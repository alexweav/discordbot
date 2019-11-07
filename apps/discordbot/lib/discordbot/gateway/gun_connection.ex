defmodule DiscordBot.Gateway.GunConnection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use GenServer
  require Logger

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    token = Keyword.fetch!(opts, :token)
    broker = Keyword.get(opts, :broker, Broker)

    state = %DiscordBot.Gateway.Connection.State{
      url: url,
      token: token,
      sequence: nil,
      broker: broker
    }

    GenServer.start_link(__MODULE__, state, opts)
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

  ## Handlers

  def init(state) do
    url = URI.parse(state.url)

    connection_opts = %{protocols: [:http]}

    {:ok, connection} =
      url.host
      |> to_charlist()
      |> :gun.open(443, connection_opts)

    {:ok, :http} = :gun.await_up(connection, 10_000)
    Logger.info("HTTP connection established!")

    :gun.ws_upgrade(connection, "/?v=6&encoding=json")

    receive do
      {:gun_upgrade, _, _, ["websocket"], _} -> :ok
      {:gun_error, _, _, reason} ->
        Logger.error("WS upgrade failed: #{reason}")
        exit({:upgrade_failed, reason})
    after
      10_000 ->
        Logger.error("WS upgrade timed out.")
        exit({:upgrade_failed, :timeout})
    end

    Logger.info("Websocket connection established.")

    {:ok, state}
  end
end
