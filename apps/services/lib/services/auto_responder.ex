defmodule Services.AutoResponder do
  @moduledoc """
  Responds to messages using pattern-based rules.
  """

  use DiscordBot.Handler

  @doc """
  Starts this handler.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(:ok) do
    {:ok, :ok}
  end

  @doc false
  def handle_message(_, _, _), do: {:noreply}
end
