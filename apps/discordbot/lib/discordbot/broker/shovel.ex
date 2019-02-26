defmodule DiscordBot.Broker.Shovel do
  @moduledoc """
  Transfers messages from one broker to another.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

  @doc """
  Starts the shovel.

  - `opts` - a keyword list of options. See below.

  Options (required):
  - `:source` - a `DiscordBot.Broker` (pid or name) from which messages will be transferred.
  - `:destination` - a `DiscordBot.Broker` (pid or name) to which messages will be transferred.
  - `:topics` - a list of topics to transfer. All messages sent over the `:source` under any topic here will be transferred to `:destination`.
  """
  def start_link(nil), do: raise(ArgumentError, message: "Opts cannot be nil.")

  def start_link(opts) do
    source =
      case Keyword.fetch(opts, :source) do
        {:ok, pid} -> pid
        :error -> raise ArgumentError, message: "Source is a required option."
      end

    destination =
      case Keyword.fetch(opts, :destination) do
        {:ok, pid} -> pid
        :error -> raise ArgumentError, message: "Destination is a required option."
      end

    topics =
      case Keyword.fetch(opts, :topics) do
        {:ok, pid} -> pid
        :error -> raise ArgumentError, message: "Topics is a required option."
      end

    GenServer.start_link(__MODULE__, {source, destination, topics}, opts)
  end

  @doc """
  Gets the topics that the shovel is currently transferring.
  """
  @spec topics?(pid) :: list(atom)
  def topics?(shovel) do
    GenServer.call(shovel, {:topics})
  end

  @doc """
  Adds a topic to the shovel's topic set.
  """
  @spec add_topic(pid, atom) :: :ok
  def add_topic(shovel, topic) do
    GenServer.call(shovel, {:add, topic})
  end

  ## Handlers

  def init({source, destination, topics}) do
    for topic <- topics do
      Broker.subscribe(source, topic)
    end

    {:ok, {source, destination, MapSet.new(topics)}}
  end

  def handle_call({:topics}, _from, {_, _, topics} = state) do
    {:reply, topics |> MapSet.to_list(), state}
  end

  def handle_call({:add, topic}, _from, {source, dest, topics}) do
    Broker.subscribe(source, topic)
    {:reply, :ok, {source, dest, MapSet.put(topics, topic)}}
  end

  def handle_info(%Event{}, state) do
    {:noreply, state}
  end
end
