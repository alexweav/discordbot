defmodule DiscordBot.Handlers.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  @doc """
  Starts the TTS-splitter handler
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    GenServer.start_link(__MODULE__, broker, opts)
  end

  ## Handlers

  def init(broker) do
    {:ok, broker}
  end
end
