defmodule Services.AutoResponder do
  @moduledoc """
  Responds to messages using pattern-based rules.
  """

  use DiscordBot.Handler

  alias DiscordBot.Self
  alias DiscordBot.Model.User

  @doc """
  Starts this handler.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(:ok) do
    rules = [
      {~r/^i('?m|\sam)\s(?<rest>.+)$/i, "Hi {rest}, I'm Dad!"}
    ]

    {:ok, rules}
  end

  @doc false
  def handle_message(_text, %Message{author: %User{id: author_id}}, _) do
    case Self.user?() do
      %User{id: ^author_id} -> {:noreply}
      _ -> {:reply, {:text, "test"}}
    end
  end

  def handle_message(_, _, _), do: {:noreply}
end
