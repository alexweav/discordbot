defmodule Services.Voice do
  @moduledoc """
  Commands for joining voice channels.
  """

  use DiscordBot.Handler
  require Logger

  alias DiscordBot.Entity.Channels
  alias DiscordBot.Voice

  @doc """
  Starts this handler inside a new process.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(:ok) do
    {:ok, :ok}
  end

  @doc false
  def handle_message("!ff_voice", message, _) do
    Logger.info("Join audio message!")
    channels = Channels.voice_channels?(message.guild_id)

    unless channels == [] do
      first_channel = Enum.min_by(channels, fn c -> c.position end)
      Voice.connect(first_channel.id)
    end

    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}
end
