defmodule DiscordBot.Handlers.Search do
  @moduledoc """
  Logic for the search commands
  """

  alias DiscordBot.Handlers.Search.Wikipedia
  alias DiscordBot.Handlers.Search.Youtube
  alias DiscordBot.Handlers.Search.Spotify

  @doc """
  Searches Wikipedia for `text`, and returns the search
  result as a response to `message`
  """
  @spec reply_wikipedia(String.t(), DiscordBot.Model.Message.t()) :: any
  def reply_wikipedia(text, message) do
    response =
      text
      |> search_wikipedia()
      |> format_message()

    DiscordBot.Channel.Controller.reply(message, response)
  end

  @doc """
  Searches Wikipedia for the given term and returns
  a link to the first result. Returns `nil` if no result
  is found, or if Wikipedia cannot be reached.
  """
  @spec search_wikipedia(String.t()) :: String.t() | nil
  def search_wikipedia(term) do
    case Wikipedia.search_articles(term) do
      {:ok, [_, _, _, []]} -> nil
      {:ok, [_, _, _, [link]]} -> link
      _ -> nil
    end
  end

  @doc """
  Searches YouTube for `text`, and returns the search result
  as a response to `message`
  """
  @spec reply_youtube(String.t(), DiscordBot.Model.Message.t()) :: any
  def reply_youtube(text, message) do
    response =
      text
      |> search_youtube()
      |> format_message()

    DiscordBot.Channel.Controller.reply(message, response)
  end

  @doc """
  Searches YouTube for the given term and returns
  a link to the first result. Returns `nil` if no result
  is found, or if YouTube cannot be reached.
  """
  @spec search_youtube(String.t()) :: String.t() | nil
  def search_youtube(term) do
    case Youtube.search_videos(term) do
      {:ok, %{"items" => []}} -> nil
      {:ok, %{"items" => [%{"id" => %{"videoId" => id}}]}} -> youtube_video_link(id)
      _ -> nil
    end
  end

  @doc """
  Returns a link to a YouTube video given the video's ID
  """
  @spec youtube_video_link(String.t()) :: String.t()
  def youtube_video_link(id) do
    "https://www.youtube.com/watch?v=#{id}"
  end

  def request_spotify_access_token do
    {:ok, data} = Spotify.request_temporary_token()
    data
  end

  @spec format_message(String.t() | nil) :: String.t()
  defp format_message(nil), do: "Nothing found :("
  defp format_message(text), do: text
end
