defmodule Services.TtsSplitter.Server do
  @moduledoc """
  GenServer for the TTS splitter command
  """

  use GenServer

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Entity.{Channel, ChannelManager}
  alias DiscordBot.Model.Message
  alias Services.Help

  @doc """
  Starts the TTS-splitter handler
  """
  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    help = Help.from_arg(opts)

    GenServer.start_link(__MODULE__, {broker, help}, opts)
  end

  ## Handlers

  def init({broker, help}) do
    Broker.subscribe(broker, :message_create)

    Help.register_info(help, %Help.Info{
      command_key: "!tts_split",
      name: "TTS Split",
      description: "Splits long text into segments and repeats them using /tts"
    })

    {:ok, broker}
  end

  def handle_info(%Event{message: message}, broker) do
    %Message{channel_id: channel_id, content: content} = message
    handle_content(content, channel_id)
    {:noreply, broker}
  end

  defp handle_content("!tts_split " <> text, channel_id) do
    Task.Supervisor.start_child(
      Services.TtsSplitter.TaskSupervisor,
      fn -> lookup_and_send(text, channel_id) end
    )
  end

  defp handle_content(_, _), do: nil

  defp lookup_and_send(text, channel_id) do
    {:ok, channel} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)

    chunks = Services.TtsSplitter.tts_split(text)
    send_tts_chunks(chunks, channel)
  end

  defp send_tts_chunks(chunks, channel) do
    for chunk <- chunks do
      Channel.create_message(channel, chunk, tts: true)
      Process.sleep(3_000)
    end
  end
end
