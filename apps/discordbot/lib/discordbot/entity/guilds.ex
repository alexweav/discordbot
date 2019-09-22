defmodule DiscordBot.Entity.Guilds do
  @moduledoc """
  Provides a cache of guild information, backed by ETS.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Entity.GuildRecord
  alias DiscordBot.Model.Guild

  @doc """
  Starts the guild registry.

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
  Creates a new guild in the cache.

  The guild is added to the cache `cache` if a guild does not already
  exist with the ID provided in `model`. Otherwise, the existing guild
  will be updated with the new data in `model`.

  Returns `:ok` if the creation is successful, otherwise `:error`.
  """
  @spec create(pid | atom, Guild.t()) :: :ok | :error
  def create(cache, model) do
    GenServer.call(cache, {:create, model})
  end

  @doc """
  Deletes a cached guild.

  Always returns `:ok` if the deletion is performed, even if the
  provided ID is not present in the cache.
  """
  @spec delete(pid | atom, String.t()) :: :ok
  def delete(cache, id) do
    GenServer.call(cache, {:delete, id})
  end

  @doc """
  Gets a guild and its metadata by its ID.

  The returned guild will be an instance of `DiscordBot.Model.GuildRecord`.
  """
  @spec lookup_by_id(String.t()) :: {:ok, GuildRecord.t()} | :error
  def lookup_by_id(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, record}] -> {:ok, record}
      [] -> :error
    end
  end

  ## Callbacks

  def init({broker, api}) do
    guilds =
      if :ets.whereis(__MODULE__) == :undefined do
        :ets.new(__MODULE__, [:named_table, read_concurrency: true])
      else
        __MODULE__
      end

    topics = [
      :guild_create,
      :guild_update,
      :guild_delete
    ]

    for topic <- topics do
      Broker.subscribe(broker, topic)
    end

    {:ok, {guilds, api}}
  end

  def handle_call({:create, model}, {pid, _ref}, {guilds, _} = state) do
    {:reply, create_internal(guilds, model, pid), state}
  end

  def handle_call({:delete, id}, _from, {guilds, _} = state) do
    {:reply, delete_internal(guilds, id), state}
  end

  def handle_info(
        %Event{topic: :guild_create, message: model, publisher: pub},
        {guilds, _} = state
      ) do
    create_internal(guilds, model, pub)
    {:noreply, state}
  end

  def handle_info(
        %Event{topic: :guild_update, message: model, publisher: pub},
        {guilds, _} = state
      ) do
    create_internal(guilds, model, pub)
    {:noreply, state}
  end

  def handle_info(%Event{topic: :guild_delete, message: model}, {guilds, _} = state) do
    delete_internal(guilds, model.id)
    {:noreply, state}
  end

  defp create_internal(_, nil, _), do: :error

  defp create_internal(_, %Guild{id: nil}, _) do
    :error
  end

  defp create_internal(table, model, source) do
    record = GuildRecord.new(source, model)
    :ets.insert(table, {model.id, record})
    :ok
  end

  defp delete_internal(table, id) do
    :ets.delete(table, id)
    :ok
  end
end
