defmodule Services.Search.Server do
  @moduledoc false

  use GenServer

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Model.Message
  alias Services.Help
  alias Services.Search

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

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!wiki",
      name: "Search Wikipedia",
      description: "Searches Wikipedia for the given text"
    })

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!youtube",
      name: "Search YouTube",
      description: "Searches YouTube videos for the given text"
    })

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!spotify album",
      name: "Search Spotify albums",
      description: "Searches Spotify albums for the given text"
    })

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!spotify track",
      name: "Search Spotify tracks",
      description: "Searches Spotify tracks for the given text"
    })

    :ok = Search.setup_handler()

    {:ok, broker}
  end

  def handle_info(%Event{message: message}, broker) do
    %Message{content: content} = message
    handle_content(content, message)
    {:noreply, broker}
  end

  defp handle_content("!wiki " <> text, message) do
    handle_supervised(fn -> Search.reply_wikipedia(text, message) end)
  end

  defp handle_content("!youtube " <> text, message) do
    handle_supervised(fn -> Search.reply_youtube(text, message) end)
  end

  defp handle_content("!spotify album " <> text, message) do
    handle_supervised(fn -> Search.reply_spotify_albums(text, message) end)
  end

  defp handle_content("!spotify track " <> text, message) do
    handle_supervised(fn -> Search.reply_spotify_tracks(text, message) end)
  end

  defp handle_content(_, _), do: nil

  defp handle_supervised(func) do
    Task.Supervisor.start_child(Services.Search.TaskSupervisor, func)
  end
end
