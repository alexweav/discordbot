defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  defmodule State do
    @moduledoc false
    @enforce_keys [:url, :token]

    defstruct [
      :url,
      :token,
      :connection,
      :sequence,
      :broker,
      :broker_provider
    ]

    @type url :: String.t()
    @type token :: String.t()
    @type connection :: map | nil
    @type sequence :: number
    @type broker :: pid | atom
    @type broker_provider :: pid | atom
    @type t :: %__MODULE__{
            url: url,
            token: token,
            connection: connection,
            sequence: sequence,
            broker: broker,
            broker_provider: broker_provider
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

    broker_provider = Keyword.get(opts, :broker_provider, nil)

    state = %State{
      url: url <> "/?v=6&encoding=json",
      token: token,
      sequence: nil,
      broker: broker,
      broker_provider: broker_provider
    }

    # TODO figure out the init() equivalent for websockex process and move this there
    send(self(), :after_init)

    WebSockex.start_link(state.url, __MODULE__, state, name: Connection)
  end

  @doc """
  Sends a heartbeat message over the websocket
  """
  def heartbeat(connection) do
    WebSockex.cast(connection, {:heartbeat})
  end

  @doc """
  Sends an identify message over the websocket
  """
  def identify(connection, token, shard, num_shards) do
    WebSockex.cast(connection, {:identify, token, shard, num_shards})
  end

  @doc """
  Updates the bot's status to `status` over `connection`.
  """
  def update_status(connection, status) do
    WebSockex.cast(connection, {:update_status, status})
  end

  @doc """
  Updates the bot's status to `status`, and sets its activity
  over `connection`. Also updates their status activity given
  the activity's `type` and `name`.
  """
  def update_status(connection, status, type, name) do
    WebSockex.cast(connection, {:update_status, status, type, name})
  end

  ## Handlers

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, %{state | connection: connection}}
  end

  def handle_frame({:text, json}, state) do
    message = DiscordBot.Model.Payload.from_json(json)
    DiscordBot.Broker.publish(state.broker, event_name(message), message.data)

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
    message = DiscordBot.Model.Payload.heartbeat(nil)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> DiscordBot.Model.Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:identify, token, shard, num_shards}, state) do
    Logger.info("Send identify.")
    message = DiscordBot.Model.Identify.identify(token, shard, num_shards)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> DiscordBot.Model.Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:update_status, status}, state) do
    message = DiscordBot.Model.StatusUpdate.status_update(nil, nil, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> DiscordBot.Model.Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_cast({:update_status, status, type, name}, state) do
    activity = DiscordBot.Model.Activity.activity(type, name)
    message = DiscordBot.Model.StatusUpdate.status_update(nil, activity, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> DiscordBot.Model.Payload.to_json()

    {:reply, {:text, json}, state}
  end

  def handle_info(:after_init, _state) do
  end

  defp log_gateway_close({_, code, msg}) do
    Logger.error("Connection was closed with event #{code}: #{msg}")
  end

  defp apply_sequence(payload, sequence) do
    %DiscordBot.Model.Payload{payload | sequence: sequence}
  end

  defp event_name(%DiscordBot.Model.Payload{opcode: :dispatch} = message) do
    case DiscordBot.Model.Dispatch.atom_from_event(message.name) do
      nil -> :dispatch
      name -> name
    end
  end

  defp event_name(payload) do
    payload.opcode
  end
end
