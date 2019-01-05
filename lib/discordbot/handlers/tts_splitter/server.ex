defmodule DiscordBot.Handlers.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  require Logger

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

  def handle_info(%Event{message: message}, broker) do
    %DiscordBot.Model.Message{channel_id: channel_id, content: content} = message
    handle_content(content, channel_id)
    {:noreply, broker}
  end

  defp handle_content("!tts_split " <> text, channel_id) do
    {:ok, channel} =
      DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

    [message] = DiscordBot.Handlers.TtsSplitter.tts_split(text)
    DiscordBot.Channel.Channel.create_message(channel, message, tts: true)
  end

  defp handle_content(_, _), do: nil
end
