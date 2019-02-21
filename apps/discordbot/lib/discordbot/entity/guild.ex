defmodule DiscordBot.Entity.Guild do
  @moduledoc """
  Provides a cache of guild information.
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

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

  ## Callbacks

  def init({broker, _api}) do
    guilds = :ets.new(:guilds, [:named_table, read_concurrency: true])

    topics = [
      :guild_create,
      :guild_update,
      :guild_delete
    ]

    for topic <- topics do
      Broker.subscribe(broker, topic)
    end

    {:ok, guilds}
  end

  def handle_info(%Event{topic: :guild_create}, state) do
    {:noreply, state}
  end

  def handle_info(%Event{topic: :guild_update}, state) do
    {:noreply, state}
  end

  def handle_info(%Event{topic: :guild_delete}, state) do
    {:noreply, state}
  end
end
