defmodule DiscordBot.Entity.ChannelManager do
  @moduledoc """
  Provides management tools for the `DiscordBot.Entity.Channel` instances
  owned by the bot.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Entity.Channel
  alias DiscordBot.Model.Channel, as: ChannelModel
  alias DiscordBot.Model.Message

  @doc """
  Sends a reply to the given message on the appropriate channel.
  """
  @callback reply(message :: Message.t(), response :: String.t(), opts :: list) :: any

  @doc """
  Starts the channel manager.

  - `opts` - a keyword list of options. See below.

  Options (required):
  None.

  Options (optional):
  - `:broker` - a process (pid or name) acting as a `DiscordBot.Broker` to use for communication.
  - `:api` - an implementation of `DiscordBot.Api` to use for communication.
  """
  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    api = Keyword.get(opts, :api, DiscordBot.Api)
    GenServer.start_link(__MODULE__, {broker, api}, opts)
  end

  @doc """
  Creates a new channel.

  Spawns a new `DiscordBot.Entity.Channel` if a channel does not already exist with the
  ID provided in the model. Otherwise, the existing channel is updated with the given model.

  - `manager` - the manager to perform the creation.
  - `model` - the model containing the data for creation.
  """
  @spec create(pid, ChannelModel.t()) :: {:ok, pid} | :error
  def create(manager, model) do
    GenServer.call(manager, {:create, model})
  end

  @doc """
  Updates an existing channel with a model.

  A `DiscordBot.Entity.Channel` with the provided ID must already exist.

  - `manager` - the manager to perform the update.
  - `id` - the ID of the channel to update.
  - `update` - a model containing new data.
  """
  @spec update(pid, String.t(), ChannelModel.t()) :: :ok | :error
  def update(manager, id, update) do
    GenServer.call(manager, {:update, id, update})
  end

  @doc """
  Gets a channel by its ID.

  The returned pid will be an instance of `DiscordBot.Entity.Channel`.

  - `manager` - the manager to perform the lookup.
  - `id` - the ID of the channel to find.
  """
  @spec lookup_by_id(atom | pid, String.t()) :: {:ok, pid} | :error
  def lookup_by_id(manager, id) do
    GenServer.call(manager, {:lookup_by_id, id})
  end

  @doc """
  Closes a channel.

  - `manager` - the manager to perform the close operation.
  - `id` - the ID of the channel to close.
  """
  @spec close(pid, String.t()) :: :ok | :error
  def close(manager, id) do
    GenServer.call(manager, {:close, id})
  end

  @doc """
  Sends a reply to the given message on the appropriate channel.

  - `message` - the message for which the reply will be sent.
  - `content` - the contents of the reply message.
  - `opts` - a keyword list of options to pass to `DiscordBot.Entity.Channel.create_message/3`.
  """
  @spec reply(Message.t(), String.t(), list) :: any
  def reply(message, content, opts \\ []) do
    %Message{channel_id: channel_id} = message
    {:ok, channel} = lookup_by_id(DiscordBot.ChannelManager, channel_id)
    Channel.create_message(channel, content, opts)
  end

  ## Handlers

  def init({broker, api}) do
    topics = [
      :channel_create,
      :channel_update,
      :channel_delete,
      :guild_create
    ]

    for topic <- topics do
      Broker.subscribe(broker, topic)
    end

    {:ok, api}
  end

  def handle_call({:create, model}, _from, api) do
    {:reply, create_internal(model, api), api}
  end

  def handle_call({:update, id, update}, _from, api) do
    {:reply, update(id, update), api}
  end

  def handle_call({:lookup_by_id, id}, _from, api) do
    pids = Registry.lookup(DiscordBot.ChannelRegistry, id)
    {:reply, parse_lookup(pids), api}
  end

  def handle_call({:close, id}, _from, api) do
    {:reply, close(id), api}
  end

  def handle_info(%Event{topic: :channel_create, message: model}, api) do
    {:ok, _} = create_internal(model, api)
    {:noreply, api}
  end

  def handle_info(%Event{topic: :channel_update, message: update}, api) do
    :ok = update(update.id, update)
    {:noreply, api}
  end

  def handle_info(%Event{topic: :channel_delete, message: delete}, api) do
    :ok = close(delete.id)
    {:noreply, api}
  end

  def handle_info(%Event{topic: :guild_create, message: guild}, api) do
    {:ok, _} = create_internal(guild, api)
    {:noreply, api}
  end

  defp create_internal(nil, _api) do
    :ok
  end

  defp create_internal(%DiscordBot.Model.Guild{channels: nil}, _api) do
    {:ok, []}
  end

  defp create_internal(%DiscordBot.Model.Guild{channels: channels, id: id}, api) do
    pids =
      channels
      |> Enum.map(&%{&1 | guild_id: id})
      |> Enum.map(&create_internal(&1, api))
      |> Enum.reduce([], fn {:ok, pid}, acc -> acc ++ [pid] end)

    {:ok, pids}
  end

  defp create_internal(model, api) do
    case lookup_id(model.id) do
      {:ok, pid} ->
        Channel.update(pid, model)
        {:ok, pid}

      :error ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            DiscordBot.EntitySupervisor,
            {Channel, [channel: model, name: via_tuple(model), api: api]}
          )

        {:ok, pid}
    end
  end

  defp update(id, update) do
    case lookup_id(id) do
      {:ok, pid} ->
        Channel.update(pid, update)

      :error ->
        :error
    end
  end

  defp close(id) do
    case lookup_id(id) do
      {:ok, pid} ->
        GenServer.stop(pid, :normal)

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

  defp via_tuple(%ChannelModel{} = model) do
    {:via, Registry, {DiscordBot.ChannelRegistry, model.id}}
  end
end
