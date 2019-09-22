defmodule DiscordBot.Entity.Channels do
  @moduledoc """
  Provides a cache of channel information, backed by ETS.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Model.Channel

  @doc """
  Starts the channel registry.

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
  Creates a new channel in the cache.

  The channel is added to the cache `cache` if a channel does not already
  exist with the ID provided in `model`. Otherwise, the existing channel
  will be updated with the new data in `model`.

  Returns `:ok` if the creation is successful, otherwise `:error`.
  """
  @spec create(atom | pid, Channel.t()) :: :ok | :error
  def create(cache, channel) do
    GenServer.call(cache, {:create, channel})
  end

  @doc """
  Gets a channel by ID.
  """
  @spec from_id?(String.t()) :: {:ok, Channel.t()} | :error
  def from_id?(id) do
    case :ets.lookup(__MODULE__, id) do
      [{^id, record}] -> {:ok, record}
      [] -> :error
    end
  end

  ## Callbacks

  def init({broker, api}) do
    table =
      if :ets.whereis(__MODULE__) == :undefined do
        :ets.new(__MODULE__, [:named_table, read_concurrency: true])
      else
        __MODULE__
      end

    topics = [
      :channel_create,
      :channel_update,
      :channel_delete,
      :guild_create
    ]

    for topic <- topics do
      Broker.subscribe(broker, topic)
    end

    {:ok, {table, api}}
  end

  def handle_call({:create, channel}, _from, {table, _} = state) do
    {:reply, create_internal(table, channel), state}
  end

  defp create_internal(_, nil), do: :error
  defp create_internal(_, %Channel{id: nil}), do: :error

  defp create_internal(table, model) do
    :ets.insert(table, {model.id, model})
    :ok
  end
end
