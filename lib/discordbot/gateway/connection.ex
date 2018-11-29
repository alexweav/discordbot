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
      :connection
    ]

    @type url :: String.t()
    @type token :: String.t()
    @type connection :: map | nil
    @type t :: %__MODULE__{
            url: url,
            token: token,
            connection: connection
          }
  end

  @doc """
  Starts a gateway connection with Discord, connecting
  via `url` and authenticating with `token`
  """
  def start_link([url, token]) do
    state = %State{
      url: url <> "/?v=6&encoding=json",
      token: token
    }

    WebSockex.start_link(state.url, __MODULE__, state)
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

  ## Handlers

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, %{state | connection: connection}}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Got message.")
    message = Poison.decode!(json)

    code =
      message
      |> Map.fetch!("op")
      |> DiscordBot.Model.Payload.atom_from_opcode()

    socket_event = %{
      connection: self(),
      json: message
    }

    DiscordBot.Gateway.Broker.publish(Broker, code, socket_event)
    {:ok, state}
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
    json = Poison.encode!(message)
    {:reply, {:text, json}, state}
  end

  def handle_cast({:identify, token, shard, num_shards}, state) do
    Logger.info("Send identify.")
    message = DiscordBot.Model.Identify.identify(token, shard, num_shards)
    json = Poison.encode!(message)
    {:reply, {:text, json}, state}
  end

  defp log_gateway_close({_, code, msg}) do
    Logger.info("Connection was closed with event #{code}: #{msg}")
  end
end
