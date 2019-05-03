defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  alias DiscordBot.Broker

  alias DiscordBot.Model.{
    Activity,
    Dispatch,
    GatewayVoiceStateUpdate,
    Identify,
    Payload,
    StatusUpdate
  }

  @callback heartbeat(atom | pid) :: :ok
  @callback identify(atom | pid, String.t(), number, number) :: :ok
  @callback update_status(atom | pid, atom) :: :ok
  @callback update_status(atom | pid, atom, atom, String.t()) :: :ok
  @callback disconnect(pid, WebSockex.close_code()) :: :ok

  defmodule State do
    @moduledoc false
    @enforce_keys [:url, :token]

    defstruct [
      :url,
      :token,
      :connection,
      :sequence,
      :broker
    ]

    @type url :: String.t()
    @type token :: String.t()
    @type connection :: map | nil
    @type sequence :: number
    @type broker :: pid | atom
    @type t :: %__MODULE__{
            url: url,
            token: token,
            connection: connection,
            sequence: sequence,
            broker: broker
          }
  end

  @doc """
  Starts a gateway connection with Discord, connecting
  via `url` and authenticating with `token`
  """
  def start_link(opts) do
    url =
      case Keyword.fetch(opts, :url) do
        {:ok, url} -> url
        :error -> raise ArgumentError, message: "#{__MODULE__} is missing required parameter :url"
      end

    token =
      case Keyword.fetch(opts, :token) do
        {:ok, token} ->
          token

        :error ->
          raise ArgumentError, message: "#{__MODULE__} is missing required parameter :token"
      end

    broker = Keyword.get(opts, :broker, Broker)

    state = %State{
      url: url <> "/?v=6&encoding=json",
      token: token,
      sequence: nil,
      broker: broker
    }

    WebSockex.start_link(state.url, __MODULE__, state, opts)
  end

  @doc """
  Sends a heartbeat message over the websocket
  """
  @spec heartbeat(atom | pid) :: :ok
  def heartbeat(connection) do
    WebSockex.cast(connection, {:heartbeat})
  end

  @doc """
  Sends an identify message over the websocket
  """
  @spec identify(atom | pid, String.t(), number, number) :: :ok
  def identify(connection, token, shard, num_shards) do
    WebSockex.cast(connection, {:identify, token, shard, num_shards})
  end

  @doc """
  Updates the bot's status to `status` over `connection`.
  """
  @spec update_status(atom | pid, atom) :: :ok
  def update_status(connection, status) do
    WebSockex.cast(connection, {:update_status, status})
  end

  @doc """
  Updates the bot's status to `status`, and sets its activity
  over `connection`. Also updates their status activity given
  the activity's `type` and `name`.
  """
  @spec update_status(atom | pid, atom, atom, String.t()) :: :ok
  def update_status(connection, status, type, name) do
    WebSockex.cast(connection, {:update_status, status, type, name})
  end

  @doc """
  Updates the bot's voice state within a guild.
  """
  @spec update_voice_state(atom | pid, String.t(), String.t(), boolean, boolean) :: :ok
  def update_voice_state(connection, guild_id, channel_id, self_mute \\ false, self_deaf \\ false) do
    WebSockex.cast(connection, {:voice_state_update, guild_id, channel_id, self_mute, self_deaf})
  end

  @doc """
  Closes a connection.
  """
  @spec disconnect(pid, WebSockex.close_code()) :: :ok
  def disconnect(connection, close_code) do
    WebSockex.cast(connection, {:disconnect, close_code})
  end

  ## Handlers

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, %{state | connection: connection}}
  end

  def handle_frame({:text, json}, state) do
    IO.inspect(json)
    message = Payload.from_json(json)
    Broker.publish(state.broker, event_name(message), message.data)

    case message.sequence do
      nil -> {:ok, state}
      _ -> {:ok, %State{state | sequence: message.sequence}}
    end
  end

  def handle_frame(frame, state) do
    Logger.error("Got other frame: #{frame}")
    {:ok, state}
  end

  def handle_disconnect(reason, state) do
    Logger.error("Disconnected. Reason: #{reason}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    log_gateway_close(reason)
    exit(:normal)
  end

  def handle_cast({:heartbeat}, state) do
    message = Payload.heartbeat(nil)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:identify, token, shard, num_shards}, state) do
    Logger.info("Send identify.")
    message = Identify.identify(token, shard, num_shards)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:update_status, status}, state) do
    message = StatusUpdate.status_update(nil, nil, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:update_status, status, type, name}, state) do
    activity = Activity.activity(type, name)
    message = StatusUpdate.status_update(nil, activity, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:voice_state_update, guild_id, channel_id, self_mute, self_deaf}, state) do
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

    {:reply, {:text, json}, state}
  end

  def handle_cast({:disconnect, close_code}, state) do
    {:close, {close_code, "Disconnecting"}, state}
  end

  defp log_gateway_close({_, code, msg}) do
    Logger.error("Connection was closed with event #{code}: #{msg}")
  end

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
