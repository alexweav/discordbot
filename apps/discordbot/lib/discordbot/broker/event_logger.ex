defmodule DiscordBot.Broker.EventLogger do
  @moduledoc """
  Utility for logging events on a broker
  """

  use GenServer
  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

  defmodule State do
    @enforce_keys [:broker, :topics, :name]

    defstruct [
      :broker,
      :topics,
      :name
    ]

    @type broker :: pid
    @type topics :: list(atom)
    @type name :: String.t()
    @type t :: %__MODULE__{
            broker: broker,
            topics: topics,
            name: name
          }
  end

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
        _ -> nil
      end

    state = %State{
      broker: broker,
      topics: topics,
      name: logger_name
    }

    GenServer.start_link(__MODULE__, state, opts)
  end

  @doc """
  Returns the name of `logger`.
  """
  @spec logger_name?(pid) :: String.t()
  def logger_name?(logger) do
    GenServer.call(logger, {:logger_name})
  end

  @doc """
  Returns the list of topics that `logger` is tracking
  """
  @spec topics?(pid) :: list(atom)
  def topics?(logger) do
    GenServer.call(logger, {:topics})
  end

  @doc """
  Starts logging a topic
  """
  @spec begin_logging(pid, atom) :: :ok | :error
  def begin_logging(logger, topic) do
    GenServer.call(logger, {:begin, topic})
  end

  ## Handlers

  def init(state) do
    subscribe(state.broker, state.topics)
    {:ok, fallback_name(state)}
  end

  def handle_call({:logger_name}, _from, state) do
    {:reply, state.name, state}
  end

  def handle_call({:topics}, _from, state) do
    {:reply, state.topics, state}
  end

  def handle_call({:begin, topic}, _from, state) do
    subscribe(state.broker, [topic])
    {:reply, :ok, %State{state | topics: state.topics ++ [topic]}}
  end

  def handle_info(%Event{topic: topic, message: msg}, state) do
    Logger.info("EventLogger [#{state.name}] Event | #{topic} | #{Kernel.inspect(msg)}")
    {:noreply, state}
  end

  defp subscribe(broker, topics) do
    for topic <- topics do
      Broker.subscribe(broker, topic)
    end
  end

  defp fallback_name(%{name: nil} = state) do
    %{state | name: Kernel.inspect(self())}
  end

  defp fallback_name(state) do
    state
  end
end
