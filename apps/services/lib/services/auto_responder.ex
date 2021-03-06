defmodule Services.AutoResponder do
  @moduledoc """
  Responds to messages using pattern-based rules.
  """

  use DiscordBot.Handler

  alias DiscordBot.Model.User
  alias DiscordBot.Self

  @typedoc """
  Represents a single auto-response rule. A rule consists
  of a regex, and a response string. If a message is given which matches
  the rule, the bot will respond with the matching response.

  Named capture groups in the rule regex may be inserted into the
  response by wrapping the name in curly braces.
  """
  @type rule :: {Regex.t(), String.t()}

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

  @doc """
  Generates a reply tuple containing the response produced when evaluating
  a list of rules against a string. See `evaluate_rules`.
  """
  @spec generate_response(list(rule), String.t()) :: {:reply, {:text, String.t()}} | {:noreply}
  def generate_response(rules, text) do
    case evaluate_rules(rules, text) do
      :error -> {:noreply}
      response -> {:reply, {:text, response}}
    end
  end

  @doc """
  Evaluates a list of rules against a string. Returns the response given
  by the first matching rule. Returns `:error` if no given rules match the string.

  ## Examples

      iex> rules = [{~r/abc/, "def"}]
      ...> Services.AutoResponder.evaluate_rules(rules, "abc")
      "def"

      iex> rules = [{~r/abc/, "def"}]
      ...> Services.AutoResponder.evaluate_rules(rules, "xyz")
      :error
  """
  @spec evaluate_rules(list(rule), String.t()) :: String.t() | :error
  def evaluate_rules([{rule, response} | rest], text) do
    case Regex.named_captures(rule, text) do
      nil -> evaluate_rules(rest, text)
      captures -> insert_string_args(response, captures)
    end
  end

  def evaluate_rules([], _), do: :error

  @doc """
  Inserts a set of named arguments into a string. The arguments
  within the string are indicated by names wrapped in curly braces.

  ## Examples

      iex> Services.AutoResponder.insert_string_args("Hello {arg}!", %{"arg" => "World"})
      "Hello World!"
  """
  @spec insert_string_args(String.t(), map) :: String.t()
  def insert_string_args(string, args) do
    args
    |> Map.to_list()
    |> Enum.reduce(string, fn {key, insert}, str ->
      String.replace(str, "{#{key}}", insert)
    end)
  end
end
