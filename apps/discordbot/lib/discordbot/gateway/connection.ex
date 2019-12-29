defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use DiscordBot.GunServer
  require Logger

  alias DiscordBot.Broker

  alias DiscordBot.Model.{
    Activity,
    Dispatch,
    GatewayVoiceStateUpdate,
    Payload,
    StatusUpdate
  }

  @gateway_path Application.get_env(:discordbot, :gateway_url, "/?v=6&encoding=json")

  @callback heartbeat(atom | pid) :: :ok
  @callback identify(atom | pid, String.t(), number, number) :: :ok
  @callback update_status(atom | pid, atom) :: :ok
  @callback update_status(atom | pid, atom, atom, String.t()) :: :ok
  @callback disconnect(pid, WebSockex.close_code()) :: :ok

  defmodule State do
    @moduledoc false
    @enforce_keys [:token]

    defstruct [
      :token,
      :sequence,
      :broker
    ]

    @type token :: String.t()
    @type sequence :: number
    @type broker :: pid | atom
    @type t :: %__MODULE__{
            token: token,
            sequence: sequence,
            broker: broker
          }
  end

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    token = Keyword.fetch!(opts, :token)
    broker = Keyword.get(opts, :broker, Broker)

    state = %State{
      token: token,
      sequence: nil,
      broker: broker
    }

    DiscordBot.GunServer.start_link(__MODULE__, url <> @gateway_path, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket
  """
  @spec heartbeat(atom | pid) :: :ok
  def heartbeat(connection) do
    GenServer.cast(connection, {:heartbeat})
  end

  @doc """
  Sends an identify message over the websocket.
  """
  @spec identify(atom | pid, Identify.t()) :: :ok
  def identify(connection, identify) do
    GenServer.cast(connection, {:identify, identify})
  end

  @doc """
  Updates the bot's status to `status` over `connection`.
  """
  @spec update_status(atom | pid, atom) :: :ok
  def update_status(connection, status) do
    GenServer.cast(connection, {:update_status, status})
  end

  @doc """
  Updates the bot's status to `status`, and sets its activity
  over `connection`. Also updates their status activity given
  the activity's `type` and `name`.
  """
  @spec update_status(atom | pid, atom, atom, String.t()) :: :ok
  def update_status(connection, status, type, name) do
    GenServer.cast(connection, {:update_status, status, type, name})
  end

  @doc """
  Updates the bot's voice state within a guild.
  """
  @spec update_voice_state(atom | pid, String.t(), String.t(), boolean, boolean) :: :ok
  def update_voice_state(connection, guild_id, channel_id, self_mute \\ false, self_deaf \\ false) do
    GenServer.cast(connection, {:voice_state_update, guild_id, channel_id, self_mute, self_deaf})
  end

  @doc """
  Closes a connection.
  """
  @spec disconnect(pid, WebSockex.close_code()) :: :ok
  def disconnect(connection, close_code) do
    GenServer.cast(connection, {:disconnect, close_code})
  end

  ## Other messages

  def websocket_info(:heartbeat, state) do
    heartbeat(self())
    {:noreply, state}
  end

  def websocket_info({:disconnect, close_code}, state) do
    disconnect(self(), close_code)
    {:noreply, state}
  end

  ## WebSocket frames

  def handle_frame({:text, json}, state) do
    message = Payload.from_json(json)
    Broker.publish(state.broker, event_name(message), message.data)

    case message.sequence do
      nil -> {:ok, state}
      _ -> {:ok, %State{state | sequence: message.sequence}}
    end

    {:noreply, state}
  end

  def handle_frame({:binary, binary}, state) do
    Logger.warn("Binary frame received: #{inspect(binary)}")
    {:noreply, state}
  end

  def handle_interrupt(reason, state) do
    Logger.warn("Websocket connection interrupted: #{inspect(reason)}")
    {:stop, :normal, state}
  end

  def handle_restore(state) do
    Logger.warn("Websocket connection restored.")
    {:stop, :normal, state}
  end

  def handle_close(code, reason, state) do
    Logger.error("Websocket disconnected with code #{inspect(code)}: #{inspect(reason)}")
    exit(:closed)
    {:noreply, state}
  end

  ## GenServer messages

  def websocket_cast({:heartbeat}, conn, state) do
    message = Payload.heartbeat(nil)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:identify, identify}, conn, state) do
    Logger.info("Identifying over gateway websocket.")

    {:ok, json} =
      identify
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:update_status, status}, conn, state) do
    message = StatusUpdate.status_update(nil, nil, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:update_status, status, type, name}, conn, state) do
    activity = Activity.new(type, name)
    message = StatusUpdate.status_update(nil, activity, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast(
        {:voice_state_update, guild_id, channel_id, self_mute, self_deaf},
        conn,
        state
      ) do
    message =
      GatewayVoiceStateUpdate.voice_state_update(
        guild_id,
        channel_id,
        self_mute,
        self_deaf
      )

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(conn, {:text, json})
    {:noreply, state}
  end

  def websocket_cast({:disconnect, _close_code}, conn, state) do
    :gun.ws_send(conn, :close)
    {:noreply, state}
  end

  ## Private functions

  defp apply_sequence(payload, sequence) do
    %Payload{payload | sequence: sequence}
  end

  defp event_name(%Payload{opcode: :dispatch} = message) do
    case Dispatch.atom_from_event(message.name) do
      nil -> :dispatch
      name -> name
    end
  end

  defp event_name(payload) do
    payload.opcode
  end
end
