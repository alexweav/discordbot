defmodule DiscordBot.Handlers.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

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
    Broker.subscribe(broker, :message_create)
    {:ok, broker}
  end

  def handle_info(%Event{}, broker) do
    {:noreply, broker}
  end
end
