defmodule DiscordBot.Handlers.Search do
  @moduledoc """
  Logic for the search commands
  """

  alias DiscordBot.Handlers.Search.Wikipedia
  alias DiscordBot.Handlers.Search.Youtube

  def search_wikipedia(term) do
    case Wikipedia.search_articles(term) do
      {:ok, [_, _, _, []]} -> nil
      {:ok, [_, _, _, [link]]} -> link
      _ -> nil
    end
  end

  def search_youtube(term) do
    case Youtube.search_videos(term) do
      {:ok, %{"items" => []}} -> nil
      {:ok, %{"items" => [%{"id" => %{"videoId" => id}}]}} -> youtube_video_link(id)
      _ -> nil
    end
  end

  def youtube_video_link(id) do
    "https://www.youtube.com/watch?v=#{id}"
  end
end
