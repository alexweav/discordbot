defmodule DiscordBot.Voice.Control do
  @moduledoc """
  Represents a connection to Discord's voice control websocket API.
  """

  use WebSockex
  require Logger

  alias DiscordBot.Gateway.Heartbeat
  alias DiscordBot.Model.{SelectProtocol, Speaking, VoiceIdentify, VoicePayload}
  alias DiscordBot.Util
  alias DiscordBot.Voice.Session

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
      heartbeat: nil
    }

    WebSockex.start_link(url, __MODULE__, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket.
  """
  @spec heartbeat(atom | pid, integer) :: :ok
  def heartbeat(connection, nonce) do
    WebSockex.cast(connection, {:heartbeat, nonce})
  end

  @doc """
  Sends an identify message over the websocket.
  """
  @spec identify(atom | pid) :: :ok
  def identify(connection) do
    WebSockex.cast(connection, :identify)
  end

  @doc """
  Specifies the IP and port for the incoming voice UDP data.
  """
  @spec select_protocol(atom | pid, String.t(), integer) :: :ok
  def select_protocol(connection, ip, port) do
    WebSockex.cast(connection, {:select_protocol, ip, port})
  end

  @doc """
  Indicates whether the bot has started or finished speaking.
  """
  @spec speaking(atom | pid, boolean, integer) :: :ok
  def speaking(connection, speaking, ssrc) do
    WebSockex.cast(connection, {:speaking, speaking, ssrc})
  end

  @doc """
  Disconnects from the control websocket.
  """
  @spec disconnect(pid, WebSockex.close_code()) :: :ok
  def disconnect(connection, close_code) do
    WebSockex.cast(connection, {:disconnect, close_code})
  end

  ## WebSocket message handlers

  def handle_connect(_, state) do
    Logger.info("Connected to voice control!")
    {:ok, state}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Received voice control frame: #{Kernel.inspect(json)}")

    json
    |> VoicePayload.from_json()
    |> handle_payload(state)
  end

  def handle_frame(frame, state) do
    Logger.error("Got non-text frame: #{frame}")
    {:ok, state}
  end

  @doc false
  def handle_payload(%VoicePayload{opcode: :hello} = payload, state) do
    identify(self())
    interval = payload.data.heartbeat_interval
    new_state = setup_heartbeat(interval, state)
    {:ok, new_state}
  end

  def handle_payload(%VoicePayload{opcode: :heartbeat_ack}, state) do
    Heartbeat.acknowledge(state[:heartbeat])
    {:ok, state}
  end

  def handle_payload(%VoicePayload{opcode: :ready} = payload, state) do
    {:ok, state}
  end

  def handle_payload(_, state), do: {:ok, state}

  def handle_disconnect(reason, state) do
    Logger.error("Disconnected from voice control. Reason: #{reason}")
    {:ok, state}
  end

  def terminate({_, code, msg}, _) do
    Logger.error("Voice control connection closed with event #{code}: #{msg}")
    exit(:normal)
  end

  ## Process message handlers

  def handle_cast({:heartbeat, nonce}, state) do
    Logger.info("Sending voice control heartbeat.")

    {:ok, json} =
      nonce
      |> VoicePayload.heartbeat()
      |> VoicePayload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast(:identify, state) do
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

    {:reply, {:text, json}, state}
  end

  def handle_cast({:select_protocol, ip, port}, state) do
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

    {:reply, {:text, json}, state}
  end

  def handle_cast({:speaking, speaking, ssrc}, state) do
    Logger.info("Speaking.")

    message = Speaking.speaking(speaking, 0, ssrc)

    {:ok, json} =
      message
      |> VoicePayload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:disconnect, close_code}, state) do
    {:close, {close_code, "Disconnecting"}, state}
  end

  def handle_info(:heartbeat, state) do
    heartbeat(self(), :rand.uniform(999_999_999))
    {:ok, state}
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
