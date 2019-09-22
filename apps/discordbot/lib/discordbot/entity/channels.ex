defmodule DiscordBot.Entity.Channels do
  @moduledoc """
  Provides a cache of channel information, backed by ETS.
  """

  use GenServer

  alias DiscordBot.Broker

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

  ## Callbacks

  def init({broker, api}) do
    channels =
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

    {:ok, {channels, api}}
  end
end
