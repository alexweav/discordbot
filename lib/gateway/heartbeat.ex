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
    GenServer.start_link(__MODULE__, {:waiting, Nil}, opts)
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
    DiscordBot.Gateway.Broker.subscribe(Broker, :hello)
    {:ok, state}
  end

  def handle_call({:status}, _from, {status, _pid} = state) do
    {:reply, status, state}
  end

  def handle_call({:target}, _from, {_status, pid} = state) do
    {:reply, pid, state}
  end

  def handle_call({:schedule, _interval}, {from, _ref}, {:waiting, Nil}) do
    {:reply, :ok, {:running, from}}
  end

  def handle_call({:schedule, _interval}, {from, _ref}, {:running, pid}) do
    {:reply, {:overwrote, pid}, {:running, from}}
  end

  def handle_call({:schedule, _interval, pid}, _from, {:waiting, Nil}) do
    {:reply, :ok, {:running, pid}}
  end

  def handle_call({:schedule, _interval, pid}, _from, {:running, old_pid}) do
    {:reply, {:overwrote, old_pid}, {:running, pid}}
  end

  def handle_info({:broker, _broker, %{connection: pid, json: _message}}, _state) do
    {:noreply, {:running, pid}}
  end

  # TODO actually send the heartbeat on the interval
  # TODO listen for when the target process shuts down
  # TODO go back to waiting if the target doesn't exist
end
