defmodule Services.Ping do
  @moduledoc """
  Responds to basic commands via text.

  Supports the following chat commands:
  - `!ping`: Responds with `Pong`
  - `!source`: Responds with a link to the bot's GitHub repo
  """

  use DiscordBot.Handler

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
  def handle_message("!ping", _) do
    {:reply, {:text, "Pong!"}}
  end

  def handle_message("!source", _) do
    {:reply, {:text, "https://github.com/alexweav/discordbot"}}
  end

  def handle_message(_, _), do: {:noreply}
end
