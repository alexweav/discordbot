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
    Task.Supervisor.start_child(
      DiscordBot.TtsSplitter.TaskSupervisor,
      fn -> lookup_and_send(text, channel_id) end
    )
  end

  defp handle_content(_, _), do: nil

  defp lookup_and_send(text, channel_id) do
    {:ok, channel} =
      DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

    chunks = DiscordBot.Handlers.TtsSplitter.tts_split(text)
    send_tts_chunks(chunks, channel)
  end

  defp send_tts_chunks(chunks, channel) do
    for chunk <- chunks do
      DiscordBot.Channel.Channel.create_message(channel, chunk, tts: true)
      Process.sleep(3_000)
    end
  end
end
