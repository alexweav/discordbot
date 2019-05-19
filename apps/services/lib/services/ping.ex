defmodule Services.Ping do
  @moduledoc """
  Responds to basic commands via text.

  Supports the following chat commands:
  - `!ping`: Responds with `Pong`
  - `!source`: Responds with a link to the bot's GitHub repo
  """

  use DiscordBot.Handler

  alias DiscordBot.Entity.{Channel, ChannelManager}
  alias DiscordBot.Model.Message
  alias Services.Help

  @doc """
  Starts this handler inside a new process.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(:ok) do
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

    {:ok, :ok}
  end

  @doc false
  def handle_event(%Event{message: %Message{channel_id: channel_id, content: content}}, :ok) do
    handle_content(content, channel_id)
  end

  def handle_event(_, _), do: nil

  defp handle_content("!ping", channel_id) do
    {:ok, channel} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)
    Channel.create_message(channel, "Pong")
  end

  defp handle_content("!source", channel_id) do
    {:ok, channel} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, channel_id)
    Channel.create_message(channel, "https://github.com/alexweav/discordbot")
  end

  defp handle_content(_, _) do
    :noop
  end
end
