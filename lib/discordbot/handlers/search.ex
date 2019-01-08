defmodule DiscordBot.Handlers.Search do
  @moduledoc """
  Logic for the search commands
  """

  def search_wikipedia(term) do
    case DiscordBot.Handlers.Search.Wikipedia.search_articles(term) do
      {:ok, [_, _, _, []]} -> nil
      {:ok, [_, _, _, [link]]} -> link
      _ -> nil
    end
  end
end
