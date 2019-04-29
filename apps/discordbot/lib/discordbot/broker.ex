defmodule DiscordBot.Broker do
  @moduledoc """
  A simple pub/sub message broker.

  Processes may publish events to topics, which are atoms.
  They may also subscribe to topics, which will cause the
  broker to send a message containing the event data to
  the subscribing process.
  """

  use GenServer

  alias DiscordBot.Broker.Event

  @doc """
  Starts the broker
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Returns the list of known topics
  """
  @spec topics?(atom | pid) :: list(atom)
  def topics?(broker) do
    GenServer.call(broker, {:topics})
  end

  @doc """
  Subscribes to a topic
  """
  @spec subscribe(atom | pid, atom) :: :ok
  def subscribe(broker, topic) do
    GenServer.call(broker, {:subscribe, topic})
  end

  @doc """
  Returns all subscribers for a topic
  """
  @spec subscribers?(atom | pid, atom) :: list(pid)
  def subscribers?(broker, topic) do
    GenServer.call(broker, {:subscribers, topic})
  end

  @doc """
  Publishes a message to a topic
  """
  @spec publish(atom | pid, atom, any) :: :ok
  def publish(broker, topic, message) do
    GenServer.call(broker, {:publish, topic, message})
  end

  @doc """
  Publishes a message to a topic on behalf of another process.
  """
  @spec publish(atom | pid, atom, any, pid) :: :ok
  def publish(broker, topic, message, publisher) do
    GenServer.call(broker, {:publish, topic, message, publisher})
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

  def handle_call({:publish, topic, message}, from, registry) do
    {pid, _ref} = from
    {:reply, build_and_publish(topic, message, pid, registry), registry}
  end

  def handle_call({:publish, topic, message, publisher}, _from, registry) do
    {:reply, build_and_publish(topic, message, publisher, registry), registry}
  end

  defp build_and_publish(topic, message, publisher, registry) do
    %Event{
      source: :broker,
      broker: self(),
      message: message,
      topic: topic,
      publisher: publisher
    }
    |> publish_event(topic, registry)

    :ok
  end

  defp publish_event(event, topic, registry) do
    registry
    |> Map.get(topic, MapSet.new())
    |> MapSet.to_list()
    |> Enum.each(fn subscriber -> send(subscriber, event) end)
  end
end
