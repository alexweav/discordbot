defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  defmodule State do
    @enforce_keys [:url, :token]

    defstruct [
      :url,
      :token,
      :connection,
      :sequence
    ]

    @type url :: String.t()
    @type token :: String.t()
    @type connection :: map | nil
    @type sequence :: number
    @type t :: %__MODULE__{
            url: url,
            token: token,
            connection: connection,
            sequence: sequence
          }
  end

  @doc """
  Starts a gateway connection with Discord, connecting
  via `url` and authenticating with `token`
  """
  def start_link([url, token]) do
    state = %State{
      url: url <> "/?v=6&encoding=json",
      token: token,
      sequence: nil
    }

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
  Updates the bot's status
  """
  def update_status(connection, status) do
    WebSockex.cast(connection, {:update_status, status})
  end

  ## Handlers

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, %{state | connection: connection}}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Got message.")
    message = DiscordBot.Model.Payload.from_json(json)

    socket_event = %{
      connection: self(),
      json: message.data
    }

    DiscordBot.Gateway.Broker.publish(Broker, message.opcode, socket_event)

    case message.sequence do
      nil -> {:ok, state}
      _ -> {:ok, %State{state | sequence: message.sequence}}
    end
  end

  def handle_frame(_frame, state) do
    Logger.info("Got other frame.")
    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    Logger.info("Disconnected.")
    {:ok, state}
  end

  def terminate(reason, _state) do
    log_gateway_close(reason)
    exit(:normal)
  end

  def handle_cast({:heartbeat}, state) do
    Logger.info("Send heartbeat.")
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

  defp log_gateway_close({_, code, msg}) do
    Logger.info("Connection was closed with event #{code}: #{msg}")
  end

  defp apply_sequence(payload, sequence) do
    %DiscordBot.Model.Payload{payload | sequence: sequence}
  end
end
