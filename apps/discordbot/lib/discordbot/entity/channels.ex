defmodule DiscordBot.Entity.Channels do
  @moduledoc """
  Provides a cache of channel information, backed by ETS.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Model.Channel
  alias DiscordBot.Model.Guild

  @doc """
  Starts the channel registry.

  - `opts` - a keyword list of options. See below.

  Options (required):
  None.

  Options (optional):
  - `:broker` - a process (pid or name) acting as a `DiscordBot.Broker` to use for communication.
  """
  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    GenServer.start_link(__MODULE__, broker, opts)
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

  @doc """
  Deletes a cached channel.

  Always returns `:ok` if the deletion is performed, even if the
  provided ID is not present in the cache.
  """
  @spec delete(pid | atom, String.t()) :: :ok
  def delete(cache, id) do
    GenServer.call(cache, {:delete, id})
  end

  @doc """
  Finds text channels for a guild.

  Accepts either a guild ID, or a `DiscordBot.Model.Guild`.
  """
  @spec text_channels?(Guild.t() | String.t()) :: list(Channel.t())
  def text_channels?(guild) when is_binary(guild) do
    __MODULE__
    |> :ets.match_object({:_, %{type: :guild_text, guild_id: guild}})
    |> Enum.map(&elem(&1, 1))
  end

  def text_channels?(guild) do
    text_channels?(guild.id)
  end

  @doc """
  Finds voice channels for a guild.

  Accepts either a guild ID, or a `DiscordBot.Model.Guild`.
  """
  @spec voice_channels?(Guild.t() | String.t()) :: list(Channel.t())
  def voice_channels?(guild) when is_binary(guild) do
    __MODULE__
    |> :ets.match_object({:_, %{type: :guild_voice, guild_id: guild}})
    |> Enum.map(&elem(&1, 1))
  end

  def voice_channels?(guild) do
    voice_channels?(guild.id)
  end

  ## Callbacks

  def init(broker) do
    table =
      if :ets.whereis(__MODULE__) == :undefined do
        :ets.new(__MODULE__, [:named_table, :public, read_concurrency: true])
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

    {:ok, table}
  end

  def handle_call({:create, channel}, _from, table) do
    {:reply, create_internal(table, channel), table}
  end

  def handle_call({:delete, id}, _from, table) do
    {:reply, delete_internal(table, id), table}
  end

  def handle_info(%Event{topic: :channel_create, message: model}, table) do
    create_internal(table, model)
    {:noreply, table}
  end

  def handle_info(%Event{topic: :channel_update, message: model}, table) do
    create_internal(table, model)
    {:noreply, table}
  end

  def handle_info(%Event{topic: :channel_delete, message: model}, table) do
    delete_internal(table, model.id)
    {:noreply, table}
  end

  def handle_info(%Event{topic: :guild_create, message: model}, table) do
    create_from_guild(table, model)
    {:noreply, table}
  end

  defp create_internal(_, nil), do: :error
  defp create_internal(_, %Channel{id: nil}), do: :error

  defp create_internal(table, model) do
    :ets.insert(table, {model.id, model})
    :ok
  end

  defp delete_internal(table, id) do
    :ets.delete(table, id)
    :ok
  end

  defp create_from_guild(table, %Guild{channels: channels, id: id}) do
    channels
    |> Enum.map(fn c -> %{c | guild_id: id} end)
    |> Enum.map(&create_internal(table, &1))
  end
end
