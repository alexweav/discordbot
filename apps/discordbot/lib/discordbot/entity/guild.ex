defmodule DiscordBot.Entity.Guild do
  @moduledoc """
  Provides a cache of guild information.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Model.Guild, as: GuildModel

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
  """
  @spec create(pid | atom, GuildModel.t()) :: :ok | :error
  def create(cache, model) do
    GenServer.call(cache, {:create, model})
  end

  @doc """
  Gets a guild by its ID.

  The returned guild will be an instance of `DiscordBot.Model.Guild`.
  """
  @spec lookup_by_id(String.t()) :: {:ok, GuildModel.t()} | :error
  def lookup_by_id(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, model}] -> {:ok, model}
      [] -> :error
    end
  end

  ## Callbacks

  def init({broker, api}) do
    guilds = :ets.new(__MODULE__, [:named_table, read_concurrency: true])

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

  def handle_call({:create, model}, _from, {guilds, _} = state) do
    {:reply, create_internal(guilds, model), state}
  end

  def handle_info(%Event{topic: :guild_create, message: model}, {guilds, _} = state) do
    create_internal(guilds, model)
    {:noreply, state}
  end

  def handle_info(%Event{topic: :guild_update}, state) do
    {:noreply, state}
  end

  def handle_info(%Event{topic: :guild_delete}, state) do
    {:noreply, state}
  end

  defp create_internal(_, nil), do: :error

  defp create_internal(_, %DiscordBot.Model.Guild{id: nil}) do
    :error
  end

  defp create_internal(table, model) do
    :ets.insert(table, {model.id, model})
    :ok
  end
end
