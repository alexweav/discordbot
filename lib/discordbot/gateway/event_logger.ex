defmodule DiscordBot.Gateway.EventLogger do
  @moduledoc """
  Utility for logging events on a broker
  """

  use GenServer

  require Logger

  @doc """
  Launches an event logger for a broker.

  Allowed option keys are:
  - `:broker` - pid of a broker to subscribe to.
    If not provided, defaults to the named `Broker`.
  - `:topics` - a list of topic atoms to subscribe to
    initially. Defaults to an empty list
  - `:logger_name` - a string name for this logger to be
    included in logged messages. Defaults to the PID of
    this logger if not provided
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    topics =
      case Keyword.fetch(opts, :topics) do
        {:ok, topics} when is_list(topics) -> topics
        _ -> []
      end

    logger_name =
      case Keyword.fetch(opts, :logger_name) do
        {:ok, name} when is_bitstring(name) -> name
        _ -> Nil
      end

    state = %{
      broker: broker,
      topics: topics,
      name: logger_name
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Returns the name of `logger`.
  """
  def logger_name?(logger) do
    GenServer.call(logger, {:logger_name})
  end

  @doc """
  Returns the list of topics that `logger` is outputting
  """
  def topics?(logger) do
    GenServer.call(logger, {:topics})
  end

  ## Handlers

  def init(state) do
    %{broker: broker, topics: topics} = state

    for topic <- topics do
      DiscordBot.Gateway.Broker.subscribe(broker, topic)
    end

    {:ok, fallback_name(state)}
  end

  def handle_call({:logger_name}, _from, state) do
    {:reply, state[:name], state}
  end

  def handle_call({:topics}, _from, state) do
    {:reply, state[:topics], state}
  end

  def handle_info({:broker, _broker, msg}, state) do
    Logger.info("EventLogger [#{state[:name]}] Event | #{Kernel.inspect(msg)}")
    {:noreply, state}
  end

  defp fallback_name(%{name: Nil} = state) do
    %{state | name: Kernel.inspect(self())}
  end

  defp fallback_name(state) do
    state
  end
end
