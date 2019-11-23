defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use DiscordBot.GunServer
  require Logger

  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Model.{SelectProtocol, Speaking, VoiceIdentify, VoicePayload}
  alias DiscordBot.Util
  alias DiscordBot.Voice.{Session, UDP}

  def start_link(opts) do
    url = Util.require_opt!(opts, :url)
    server_id = Util.require_opt!(opts, :server_id)
    user_id = Util.require_opt!(opts, :user_id)
    session_id = Util.require_opt!(opts, :session_id)
    token = Util.require_opt!(opts, :token)

    state = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token,
      parent: self(),
      heartbeat: nil,
      connection: nil
    }

    DiscordBot.GunServer.start_link(__MODULE__, url, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket.
  """
  @spec heartbeat(atom | pid, integer) :: :ok
  def heartbeat(connection, nonce) do
    GenServer.cast(connection, {:heartbeat, nonce})
  end

  @doc """
  Sends an identify message over the websocket.
  """
  @spec identify(atom | pid) :: :ok
  def identify(connection) do
    GenServer.cast(connection, :identify)
  end

  @doc """
  Specifies the IP and port for the incoming voice UDP data.
  """
  @spec select_protocol(atom | pid, String.t(), integer) :: :ok
  def select_protocol(connection, ip, port) do
    GenServer.cast(connection, {:select_protocol, ip, port})
  end

  @doc """
  Indicates whether the bot has started or finished speaking.
  """
  @spec speaking(atom | pid, boolean) :: :ok
  def speaking(connection, speaking) do
    GenServer.cast(connection, {:speaking, speaking})
  end

  @doc """
  Disconnects from the control websocket.
  """
  @spec disconnect(pid, integer) :: :ok
  def disconnect(connection, close_code) do
    GenServer.cast(connection, {:disconnect, close_code})
  end

  ## WebSocket message handlers

  def after_connect(state) do
    Logger.info("Connected to voice control!")
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Received voice control frame: #{Kernel.inspect(json)}")

    json
    |> VoicePayload.from_json()
    |> handle_payload(state)
  end

  def handle_frame({:binary, frame}, state) do
    Logger.error("Got non-text frame: #{inspect(frame)}")
    {:ok, state}
  end

  @doc false
  def handle_payload(%VoicePayload{opcode: :hello} = payload, state) do
    identify(self())
    interval = payload.data.heartbeat_interval
    new_state = setup_heartbeat(interval, state)
    {:noreply, new_state}
  end

  def handle_payload(%VoicePayload{opcode: :heartbeat_ack}, state) do
    Heartbeat.acknowledge(state[:heartbeat])
    {:noreply, state}
  end

  def handle_payload(%VoicePayload{opcode: :ready} = payload, state) do
    data = payload.data
    connection = UDP.open(data.ip, data.port, data.ssrc)
    Logger.info("Connected to UDP: #{inspect(connection)}")
    select_protocol(self(), connection.my_ip, connection.my_port)
    {:noreply, %{state | connection: connection}}
  end

  def handle_payload(%VoicePayload{opcode: :session_description} = payload, state) do
    secret = payload.data.secret_key |> :erlang.list_to_binary()
    Logger.info("Secret key acquired: #{inspect(secret)}")
    new_conn = %{state[:connection] | secret_key: secret}
    {:noreply, %{state | connection: new_conn}}
  end

  def handle_payload(_, state), do: {:noreply, state}

  def handle_interrupt(reason, state) do
    Logger.warn("Voice connection interrupted: #{inspect(reason)}")
    {:noreply, state}
  end

  def handle_restore(state) do
    Logger.warn("Voice connection restored.")
    {:noreply, state}
  end

  def handle_close(code, reason, state) do
    Logger.error("Voice disconnected with code #{inspect(code)}: #{inspect(reason)}")
    exit(:closed)
    {:noreply, state}
  end

  ## Process message handlers

  def websocket_cast({:heartbeat, nonce}, conn, state) do
    Logger.info("Sending voice control heartbeat.")

    {:ok, json} =
      nonce
      |> VoicePayload.heartbeat()
      |> VoicePayload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast(:identify, conn, state) do
    Logger.info(
      "Sending voice identification for control connection #{Kernel.inspect(self())}..."
    )

    message =
      VoiceIdentify.voice_identify(
        state[:server_id],
        state[:user_id],
        state[:session_id],
        state[:token]
      )

    {:ok, json} =
      message
      |> VoicePayload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:select_protocol, ip, port}, conn, state) do
    Logger.info("Selecting protocol.")

    message =
      SelectProtocol.select_protocol(
        "udp",
        ip,
        port,
        "xsalsa20_poly1305"
      )

    {:ok, json} =
      message
      |> VoicePayload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:speaking, speaking}, conn, state) do
    Logger.info("Speaking.")

    message = Speaking.speaking(speaking, 0, state[:connection].ssrc)

    {:ok, json} =
      message
      |> VoicePayload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:disconnect, _close_code}, conn, state) do
    UDP.close(state.connection)
    :gun.ws_send(conn, :close)
    {:noreply, state}
  end

  def websocket_info(:heartbeat, state) do
    heartbeat(self(), :rand.uniform(999_999_999))
    {:noreply, state}
  end

  ## Private functions

  defp setup_heartbeat(interval, state) do
    # According to discord docs, the correct heartbeat interval
    # is provided in the Hello event, and is an erroneous value.
    # Clients should take this heartbeat to be 75% of its
    # given value.
    # https://discordapp.com/developers/docs/topics/voice-connections
    {:ok, heartbeat} = get_heartbeat(state)
    Heartbeat.schedule(heartbeat, trunc(interval * 0.75))
    %{state | heartbeat: heartbeat}
  end

  defp get_heartbeat(state) do
    state
    |> Map.get(:parent)
    |> Session.heartbeat?()
  end
end
