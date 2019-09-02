defmodule Services.Mention do
  @moduledoc """
  Responds to bot mentions.
  """

  use DiscordBot.Handler

  alias DiscordBot.Model.Message
  alias DiscordBot.Model.User
  alias DiscordBot.Self

  @doc """
  Starts the handler.
  """
  def start_link(opts) do
    DiscordBot.Handler.start_link(__MODULE__, :message_create, :ok, opts)
  end

  @doc false
  def handler_init(_) do
    {:ok, :ok}
  end

  @doc false
  def handle_message(_, %Message{mentions: mentions}, _) do
    %User{id: self_id} = Self.user?()

    if Enum.any?(mentions, fn user -> user.id == self_id end) do
      {:reply, {:text, "can you dont"}}
    else
      {:noreply}
    end
  end

  def handle_message(_, _, _), do: {:noreply}
end
