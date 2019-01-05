defmodule DiscordBot.Handlers.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Handlers.Help

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

    Help.register_info(DiscordBot.Help, %Help.Info{
      command_key: "!tts_split",
      name: "TTS Split",
      description: "Splits long text into segments and repeats them using /tts"
    })

    {:ok, broker}
  end

  def handle_info(%Event{}, broker) do
    {:noreply, broker}
  end
end
