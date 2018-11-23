defmodule DiscordBot.Gateway.Broker do
  @moduledoc """
  Event broker for a gateway instance
  """

  use GenServer

  defmodule Event do
    defstruct [
      :source,
      :broker,
      :message
    ]

    @typedoc """
    An atom indicating that the event originated from a broker
    """
    @type source :: atom

    @typedoc """
    The PID of the broker that sent the event
    """
    @type broker :: pid

    @typedoc """
    The event data originating from the publisher
    """
    @type message :: any

    @type t :: %__MODULE__{
            source: source,
            broker: broker,
            message: message
          }
  end

  @doc """
  Starts the broker
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Returns the list of known topics
  """
  def topics?(broker) do
    GenServer.call(broker, {:topics})
  end

  @doc """
  Subscribes to a topic
  """
  def subscribe(broker, topic) do
    GenServer.call(broker, {:subscribe, topic})
  end

  @doc """
  Returns all subscribers for a topic
  """
  def subscribers?(broker, topic) do
    GenServer.call(broker, {:subscribers, topic})
  end

  @doc """
  Publishes a message to a topic
  """
  def publish(broker, topic, message) do
    GenServer.call(broker, {:publish, topic, message})
  end

  ## Handlers

  def init(state) do
    {:ok, state}
  end

  def handle_call({:topics}, _from, registry) do
    {:reply, Map.keys(registry), registry}
  end

  def handle_call({:subscribe, topic}, {from, _ref}, registry) do
    subscribers = Map.get(registry, topic, MapSet.new())
    new_registry = Map.put(registry, topic, MapSet.put(subscribers, from))
    {:reply, :ok, new_registry}
  end

  def handle_call({:subscribers, topic}, _from, registry) do
    set = Map.get(registry, topic, MapSet.new())
    {:reply, MapSet.to_list(set), registry}
  end

  def handle_call({:publish, topic, message}, _from, registry) do
    registry
    |> Map.get(topic, MapSet.new())
    |> MapSet.to_list()
    |> Enum.each(fn sub -> send(sub, %Event{
      source: :broker,
      broker: self(),
      message: message}) end)

    {:reply, :ok, registry}
  end
end
