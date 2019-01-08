defmodule DiscordBot.Handlers.Search.Server do
  @moduledoc false

  use GenServer

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Handlers.Help

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
      command_key: "!wiki",
      name: "Search Wikipedia",
      description: "Searches wikipedia for the given text"
    })

    {:ok, broker}
  end

  def handle_info(%Event{message: message}, broker) do
    %DiscordBot.Model.Message{channel_id: channel_id, content: content} = message
    handle_content(content, channel_id)
    {:noreply, broker}
  end

  defp handle_content("!wiki " <> text, channel_id) do
    Task.Supervisor.start_child(
      DiscordBot.Search.TaskSupervisor,
      fn -> search_wiki(text, channel_id) end
    )
  end

  defp handle_content(_, _), do: nil

  defp search_wiki(text, channel_id) do
    {:ok, channel} =
      DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

    response =
      case DiscordBot.Handlers.Search.search_wikipedia(text) do
        nil -> "Nothing found :("
        link -> link
      end

    DiscordBot.Channel.Channel.create_message(channel, response)
  end
end
