defmodule DiscordBot.Broker.Shovel do
  @moduledoc """
  Transfers messages from one broker to another.
  """

  use GenServer

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

  ## Handlers

  def init(args) do
    {:ok, args}
  end
end
