defmodule DiscordBot.Gateway.GunConnection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use GenServer
  require Logger

  alias DiscordBot.Model.{
    Activity,
    GatewayVoiceStateUpdate,
    Payload,
    StatusUpdate
  }

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
    ws_upgrade(connection)

    Logger.info("Websocket connection established.")

    {:ok, %{state | connection: connection}}
  end

  ## Gun-related messages

  def handle_info({:gun_ws, _, _, {:text, text}}, state) do
    handle_frame({:text, text}, state)
  end

  def handle_info({:gun_ws, _, _, {:binary, binary}}, state) do
    Logger.info("Binary frame received: #{binary}")
    {:noreply, state}
  end

  def handle_info({:gun_ws, _, _, {:close, code, reason}}, state) do
    Logger.error("Websocket disconnected with code #{code}: #{reason}")
    {:noreply, state}
  end

  def handle_info({:gun_down, _, _, reason, _, _}, state) do
    Logger.warn("Websocket connection interrupted: #{reason}")
    {:noreply, state}
  end

  def handle_info({:gun_up, connection, _}, state) do
    ws_upgrade(connection)
    Logger.warn("Websocket connection restored.")
    {:noreply, state}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Got frame: #{json}")
    {:noreply, state}
  end

  ## GenServer messages

  def handle_cast({:heartbeat}, state) do
    message = Payload.heartbeat(nil)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(state.connection, {:text, json})
    {:noreply, state}
  end

  def handle_cast({:identify, identify}, state) do
    Logger.info("Identifying over gateway websocket.")

    {:ok, json} =
      identify
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(state.connection, {:text, json})
    {:noreply, state}
  end

  def handle_cast({:update_status, status}, state) do
    message = StatusUpdate.status_update(nil, nil, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(state.connection, {:text, json})
    {:noreply, state}
  end

  def handle_cast({:update_status, status, type, name}, state) do
    activity = Activity.activity(type, name)
    message = StatusUpdate.status_update(nil, activity, status)

    {:ok, json} =
      message
      |> apply_sequence(state.sequence)
      |> Payload.to_json()

    :ok = :gun.ws_send(state.connection, {:text, json})
    {:noreply, state}
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

    :ok = :gun.ws_send(state.connection, {:text, json})
    {:noreply, state}
  end

  def handle_cast({:disconnect, _close_code}, state) do
    :gun.ws_send(state.connection, :close)
    {:noreply, state}
  end

  ## Private functions

  defp ws_upgrade(connection) do
    :gun.ws_upgrade(connection, "/?v=6&encoding=json")

    receive do
      {:gun_upgrade, _, _, ["websocket"], _} ->
        :ok

      {:gun_error, _, _, reason} ->
        Logger.error("WS upgrade failed: #{reason}")
        exit({:upgrade_failed, reason})
    after
      10_000 ->
        Logger.error("WS upgrade timed out.")
        exit({:upgrade_failed, :timeout})
    end
  end

  defp apply_sequence(payload, sequence) do
    %Payload{payload | sequence: sequence}
  end
end
