defmodule DiscordBot.Channel.Controller do
  @moduledoc """
  Manages creation, deletion, and lookup of Channels
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

  @doc """
  Starts the controller
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    GenServer.start_link(__MODULE__, broker, opts)
  end

  @doc """
  Creates or updates a new channel for model `model`
  """
  @spec create(pid, DiscordBot.Model.Channel.t()) :: {:ok, pid} | :error
  def create(controller, model) do
    GenServer.call(controller, {:create, model})
  end

  @doc """
  Updates a channel at ID `id` with the new model `update`
  """
  @spec update(pid, String.t(), DiscordBot.Model.Channel.t()) :: :ok | :error
  def update(controller, id, update) do
    GenServer.call(controller, {:update, id, update})
  end

  @doc """
  Gets a channel by its ID
  """
  @spec lookup_by_id(pid, String.t()) :: {:ok, pid} | :error
  def lookup_by_id(controller, id) do
    GenServer.call(controller, {:lookup_by_id, id})
  end

  @doc """
  Closes the channel at ID `id`
  """
  @spec close(pid, String.t()) :: :ok | :error
  def close(controller, id) do
    GenServer.call(controller, {:close, id})
  end

  ## Handlers

  def init(broker) do
    topics = [
      :channel_create,
      :channel_update,
      :channel_delete,
      :guild_create
    ]

    for topic <- topics do
      Broker.subscribe(broker, topic)
    end

    {:ok, nil}
  end

  def handle_call({:create, model}, _from, state) do
    {:reply, create(model), state}
  end

  def handle_call({:update, id, update}, _from, state) do
    {:reply, update(id, update), state}
  end

  def handle_call({:lookup_by_id, id}, _from, state) do
    pids = Registry.lookup(DiscordBot.ChannelRegistry, id)
    {:reply, parse_lookup(pids), state}
  end

  def handle_call({:close, id}, _from, state) do
    case parse_lookup(Registry.lookup(DiscordBot.ChannelRegistry, id)) do
      {:ok, pid} ->
        GenServer.stop(pid, :normal)
        {:reply, :ok, state}

      :error ->
        {:reply, :error, state}
    end
  end

  def handle_info(%Event{topic: :channel_create, message: model}, state) do
    {:ok, _} = create(model)
    {:noreply, state}
  end

  def handle_info(%Event{topic: :channel_update, message: update}, state) do
    :ok = update(update.id, update)
    {:noreply, state}
  end

  defp create(model) do
    case lookup_id(model.id) do
      {:ok, pid} ->
        DiscordBot.Channel.Channel.update(pid, model)
        {:ok, pid}

      :error ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            DiscordBot.ChannelSupervisor,
            {DiscordBot.Channel.Channel, [channel: model, name: via_tuple(model)]}
          )

        {:ok, pid}
    end
  end

  defp update(id, update) do
    case lookup_id(id) do
      {:ok, pid} ->
        DiscordBot.Channel.Channel.update(pid, update)

      :error ->
        :error
    end
  end

  defp parse_lookup([]) do
    :error
  end

  defp parse_lookup([{pid, _}]) when is_pid(pid) do
    {:ok, pid}
  end

  defp lookup_id(id) do
    lookup_id(DiscordBot.ChannelRegistry, id)
  end

  defp lookup_id(registry, id) do
    parse_lookup(Registry.lookup(registry, id))
  end

  defp via_tuple(%DiscordBot.Model.Channel{} = model) do
    {:via, Registry, {DiscordBot.ChannelRegistry, model.id}}
  end

  defp via_tuple(id) when is_binary(id) do
    {:via, Registry, {DiscordBot.ChannelRegistry, id}}
  end
end
