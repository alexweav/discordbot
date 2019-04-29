defmodule Services.Ping do
  @moduledoc """
  Responds to basic commands via text.

  Supports the following chat commands:
  - `!ping`: Responds with `Pong`
  - `!source`: Responds with a link to the bot's GitHub repo
  """

  use Task, restart: :permanent

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias Services.Help

  @doc """
  Starts this handler inside a new process. Takes a broker
  to listen to, `broker`.
  """
  def start_link(broker) do
    Task.start_link(__MODULE__, :handle, [broker])
  end

  @doc """
  Begins handling messages on a provided broker, `broker`.
  This will loop infinitely, and therefore should be launched
  in a dedicated process.
  """
  @spec handle(Broker.t()) :: no_return()
  def handle(broker) do
    Broker.subscribe(broker, :message_create)

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!ping",
      name: "Ping",
      description: "Replies with \"Pong\""
    })

    Help.register_info(Services.Help, %Help.Info{
      command_key: "!source",
      name: "Source",
      description: "Replies with a link to this bot's source"
    })

    loop_handle()
  end

  @spec loop_handle() :: no_return()
  defp loop_handle do
    receive do
      %Event{topic: :message_create, message: message} -> handle_message(message)
    end

    loop_handle()
  end

  defp handle_message(%DiscordBot.Model.Message{channel_id: channel_id, content: content}) do
    handle_content(content, channel_id)
  end

  defp handle_content("!ping", channel_id) do
    {:ok, channel} =
      DiscordBot.Entity.ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)

    DiscordBot.Entity.Channel.create_message(channel, "Pong")
  end

  defp handle_content("!source", channel_id) do
    {:ok, channel} =
      DiscordBot.Entity.ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)

    DiscordBot.Entity.Channel.create_message(channel, "https://github.com/alexweav/discordbot")
  end

  defp handle_content(_, _) do
    :noop
  end
end
