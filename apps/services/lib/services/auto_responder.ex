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
  def handle_message(text, %Message{author: %User{id: author_id}}, rules) do
    case Self.user?() do
      %User{id: ^author_id} -> {:noreply}
      _ -> generate_response(rules, text)
    end
  end

  def handle_message(_, _, _), do: {:noreply}

  def generate_response(rules, text) do
    case evaluate_rules(rules, text) do
      nil -> {:noreply}
      response -> {:reply, {:text, response}}
    end
  end

  def evaluate_rules([{rule, response} | rest], text) do
    case Regex.named_captures(rule, text) do
      nil -> evaluate_rules(rest, text)
      captures -> insert_string_args(response, captures)
    end
  end

  def evaluate_rules([], _), do: nil

  def insert_string_args(string, _args) do
    string
  end
end
