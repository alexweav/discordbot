defmodule DiscordBot.Gateway.Heartbeat do
  @moduledoc """
  Provides a scheduled heartbeat to a single
  process which requests it
  """

  use GenServer

  alias DiscordBot.Broker.Event

  defmodule State do
    @enforce_keys [:status, :broker]

    defstruct [
      :status,
      :target,
      :target_ref,
      :interval,
      :sender,
      :broker
    ]

    @type status :: atom
    @type target :: pid
    @type target_ref :: reference
    @type interval :: number
    @type sender :: pid
    @type broker :: pid
    @type t :: %__MODULE__{
            status: status,
            target: target,
            target_ref: target_ref,
            interval: interval,
            sender: sender,
            broker: broker
          }
  end

  @doc """
  Starts the heartbeat provider
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    state = %State{
      status: :waiting,
      target: nil,
      target_ref: nil,
      interval: nil,
      sender: nil,
      broker: broker
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Gets the current status of the heartbeat provider
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
  Schedules the provider to send a heartbeat message
  every `interval` milliseconds
  """
  def schedule(provider, interval) do
    GenServer.call(provider, {:schedule, interval})
  end

  @doc """
  Schedules the provider to send a heartbeat message
  every `interval` milliseconds, to the process `pid`
  """
  def schedule(provider, interval, pid) do
    GenServer.call(provider, {:schedule, interval, pid})
  end

  ## Handlers

  def init(state) do
    DiscordBot.Broker.subscribe(state.broker, :hello)
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

  def handle_info(%Event{publisher: pid, message: message}, state) do
    interval = message.heartbeat_interval
    new_state = start_heartbeat(state, pid, interval)
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _ref, :process, _object, _reason}, state) do
    new_state = go_idle(state)
    {:noreply, new_state}
  end

  def handle_info(:heartbeat, state) do
    case state.target do
      nil ->
        {:noreply, state}

      target ->
        DiscordBot.Gateway.Connection.heartbeat(target)
        sender = Process.send_after(self(), :heartbeat, state.interval)
        new_state = %{state | sender: sender}
        {:noreply, new_state}
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
        sender: sender
    }
  end

  defp go_idle(state) do
    %{state | status: :waiting, target: nil, interval: nil, target_ref: nil, sender: nil}
  end
end
