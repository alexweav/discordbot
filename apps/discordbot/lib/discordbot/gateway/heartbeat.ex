defmodule DiscordBot.Gateway.Heartbeat do
  @moduledoc """
  Handles the heartbeat protocol for a single websocket.

  Utilizes a `DiscordBot.Broker`, to which a `DiscordBot.Gateway.Connection`
  is actively posting events in order to schedule and provide
  heartbeat messages over the websocket.

  By default, Discord will requires that a heartbeat to be sent over each
  connection at a specified interval. In addition, Discord may request that
  an additional heartbeat be sent at any time, out-of-band of the normal
  schedule, to be used for ping tracking. Discord will also acknowledge
  scheduled heartbeats with an ACK event over the websocket.

  This GenServer provides a scheduling mechanism for heartbeat messages,
  as well as a provider for out-of-band heartbeats. In addition, it tracks
  the acknowledgements for these heartbeats, and is the primary mechanism
  for determining if a `DiscordBot.Gateway.Connection` is zombied or failed.
  If this occurrs, the connection will be restarted automatically.
  """

  use GenServer

  require Logger

  alias DiscordBot.Broker.Event

  defmodule State do
    @enforce_keys [:status, :broker]
    @moduledoc false

    defstruct [
      :status,
      :target,
      :target_ref,
      :interval,
      :sender,
      :broker,
      :acked,
      :last_ack_time
    ]

    @type status :: atom
    @type target :: pid
    @type target_ref :: reference
    @type interval :: number
    @type sender :: pid
    @type broker :: pid
    @type acked :: boolean
    @type last_ack_time :: DateTime.t()
    @type t :: %__MODULE__{
            status: status,
            target: target,
            target_ref: target_ref,
            interval: interval,
            sender: sender,
            broker: broker,
            acked: acked,
            last_ack_time: last_ack_time
          }
  end

  @doc """
  Starts the heartbeat provider.

  Options (required):
  - `:broker` - a `DiscordBot.Broker` process to listen to for events.
  """
  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)

    state = %State{
      status: :waiting,
      target: nil,
      target_ref: nil,
      interval: nil,
      sender: nil,
      broker: broker,
      acked: false,
      last_ack_time: nil
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Gets the current status of the heartbeat `provider`.

  Returns either `:waiting:`, if the provider is inactive,
  or `:running:`, if the provider is actively providing heartbeats.
  """
  def status?(provider) do
    GenServer.call(provider, {:status})
  end

  @doc """
  Returns the process that the provider is working for,
  or `nil` if there is none.
  """
  def target?(provider) do
    GenServer.call(provider, {:target})
  end

  @doc """
  Returns the interval of the current scheduled heartbeat,
  or `nil` if there is none.
  """
  def interval?(provider) do
    GenServer.call(provider, {:interval})
  end

  @doc """
  Returns whether the most recently sent heartbeat has been acknowledged.
  """
  def acknowledged?(provider) do
    GenServer.call(provider, {:acknowledged})
  end

  def last_ack_time?(provider) do
    GenServer.call(provider, {:last_ack_time})
  end

  @doc """
  Schedules the provider to send a heartbeat message
  every `interval` milliseconds.
  """
  def schedule(provider, interval) do
    GenServer.call(provider, {:schedule, interval})
  end

  @doc """
  Schedules the provider to send a heartbeat message
  every `interval` milliseconds, to the process `pid`.
  """
  def schedule(provider, interval, pid) do
    GenServer.call(provider, {:schedule, interval, pid})
  end

  ## Handlers

  def init(state) do
    DiscordBot.Broker.subscribe(state.broker, :hello)
    DiscordBot.Broker.subscribe(state.broker, :heartbeat)
    DiscordBot.Broker.subscribe(state.broker, :heartbeat_ack)
    {:ok, state}
  end

  def handle_call({:status}, _from, state) do
    {:reply, state.status, state}
  end

  def handle_call({:target}, _from, state) do
    {:reply, state.target, state}
  end

  def handle_call({:interval}, _from, state) do
    {:reply, state.interval, state}
  end

  def handle_call({:acknowledged}, _from, state) do
    {:reply, state.acked, state}
  end

  def handle_call({:last_ack_time}, _from, state) do
    {:reply, state.last_ack_time, state}
  end

  def handle_call({:schedule, interval}, {from, _ref}, %State{status: :waiting} = state) do
    new_state = start_heartbeat(state, from, interval)
    {:reply, :ok, new_state}
  end

  def handle_call({:schedule, interval}, {from, _ref}, %State{status: :running} = state) do
    new_state = start_heartbeat(state, from, interval)
    {:reply, {:overwrote, state.target}, new_state}
  end

  def handle_call({:schedule, interval, pid}, _from, %State{status: :waiting} = state) do
    new_state = start_heartbeat(state, pid, interval)
    {:reply, :ok, new_state}
  end

  def handle_call({:schedule, interval, pid}, _from, %State{status: :running} = state) do
    new_state = start_heartbeat(state, pid, interval)
    {:reply, {:overwrote, state.target}, new_state}
  end

  def handle_info(%Event{publisher: pid, message: message, topic: :hello}, state) do
    interval = message.heartbeat_interval
    new_state = start_heartbeat(state, pid, interval)
    {:noreply, new_state}
  end

  def handle_info(%Event{publisher: pid, topic: :heartbeat}, state) do
    if state.status == :running and pid == state.target do
      Logger.info("Discord requested a heartbeat to be sent out-of-band. Responding...")
      DiscordBot.Gateway.Connection.heartbeat(pid)
    end

    {:noreply, state}
  end

  def handle_info(%Event{topic: :heartbeat_ack}, state) do
    {:noreply, %{state | acked: true, last_ack_time: DateTime.utc_now()}}
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, state) do
    new_state = go_idle(state)
    {:noreply, new_state}
  end

  def handle_info(:heartbeat, state) do
    cond do
      state.target == nil ->
        {:noreply, state}

      state.acked ->
        DiscordBot.Gateway.Connection.heartbeat(state.target)
        sender = Process.send_after(self(), :heartbeat, state.interval)
        new_state = %{state | sender: sender, acked: false}
        {:noreply, new_state}

      true ->
        Logger.error(
          "Discord did not acknowledge a heartbeat for an entire cycle. Closing the affected connection and reestablishing."
        )

        DiscordBot.Gateway.Connection.disconnect(state.target, 4_000)
        {:noreply, go_idle(state)}
    end
  end

  defp start_heartbeat(state, pid, interval) do
    idle_state = go_idle(state)
    ref = Process.monitor(pid)
    sender = Process.send_after(self(), :heartbeat, interval)

    %{
      idle_state
      | status: :running,
        target: pid,
        interval: interval,
        target_ref: ref,
        sender: sender,
        acked: true,
        last_ack_time: nil
    }
  end

  defp go_idle(state) do
    %{state | status: :waiting, target: nil, interval: nil, target_ref: nil, sender: nil}
  end
end
