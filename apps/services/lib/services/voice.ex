defmodule Services.Voice do
  @moduledoc """
  Commands for joining voice channels.
  """

  use DiscordBot.Handler
  require Logger

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
  def handle_message("!ff_voice", _, _) do
    Logger.info("Join audio message!")
    {:noreply}
  end

  def handle_message(_, _, _), do: {:noreply}
end
