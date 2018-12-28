defmodule DiscordBot.Handlers.Ping do
  @moduledoc """
  Responds to basic commands via text.

  Supports the following chat commands:
  - `!ping`: Responds with `Pong`
  - `!source`: Responds with a link to the bot's GitHub repo
  """

  use Task, restart: :permanent

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

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
  @spec handle(Broker.t()) :: :ok
  def handle(broker) do
    DiscordBot.Broker.subscribe(broker, :message_create)
    loop_handle()
  end

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
      DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

    DiscordBot.Channel.Channel.create_message(channel, "Pong")
  end

  defp handle_content("!source", channel_id) do
    {:ok, channel} =
      DiscordBot.Channel.Controller.lookup_by_id(DiscordBot.ChannelController, channel_id)

    DiscordBot.Channel.Channel.create_message(channel, "https://github.com/alexweav/discordbot")
  end

  defp handle_content(_, _) do
    :noop
  end
end
