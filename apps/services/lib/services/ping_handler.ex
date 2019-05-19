defmodule Services.PingHandler do
  use DiscordBot.Handler

  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  def init({_, :ok}) do
    {:ok, :ok}
  end

  def handler_init(:ok) do
    {:ok, :ok}
  end

  def handle_event(_, :ok) do
    {:ok, :ok}
  end
end
