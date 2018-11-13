defmodule DiscordBot.Gateway.Heartbeat do
  @moduledoc """
  Provides a scheduled heartbeat to a single
  process which requests it
  """

  use GenServer

  @doc """
  Starts the heartbeat provider
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    state = %{
      status: :waiting,
      target: Nil,
      broker: broker
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Gets the current status of the heartbeat provider
  """
  def status(provider) do
    GenServer.call(provider, {:status})
  end

  @doc """
  Returns the process that the provider is working for,
  or `Nil` if there is none.
  """
  def target(provider) do
    GenServer.call(provider, {:target})
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
    DiscordBot.Gateway.Broker.subscribe(state[:broker], :hello)
    {:ok, state}
  end

  def handle_call({:status}, _from, state) do
    {:reply, state[:status], state}
  end

  def handle_call({:target}, _from, state) do
    {:reply, state[:target], state}
  end

  def handle_call({:schedule, _interval}, {from, _ref}, %{status: :waiting} = state) do
    {:reply, :ok, retarget_state(state, from)}
  end

  def handle_call({:schedule, _interval}, {from, _ref}, %{status: :running} = state) do
    {:reply, {:overwrote, state[:target]}, retarget_state(state, from)}
  end

  def handle_call({:schedule, _interval, pid}, _from, %{status: :waiting} = state) do
    {:reply, :ok, retarget_state(state, pid)}
  end

  def handle_call({:schedule, _interval, pid}, _from, %{status: :running} = state) do
    {:reply, {:overwrote, state[:target]}, retarget_state(state, pid)}
  end

  def handle_info({:broker, _broker, %{connection: pid, json: _message}}, state) do
    {:noreply, retarget_state(state, pid)}
  end

  defp retarget_state(state, pid) do
    %{state | status: :running, target: pid}
  end

  # TODO actually send the heartbeat on the interval
  # TODO listen for when the target process shuts down
  # TODO go back to waiting if the target doesn't exist
end
