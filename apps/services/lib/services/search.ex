defmodule Services.Search do
  @moduledoc """
  Logic for the search commands
  """

  alias DiscordBot.Entity.ChannelManager
  alias DiscordBot.Model.Message
  alias Services.Search.Spotify
  alias Services.Search.TokenManager
  alias Services.Search.Wikipedia
  alias Services.Search.Youtube

  @default_spotify_token_timeout 1000 * 60 * 60

  @doc """
  Searches Wikipedia for `text`, and returns the search
  result as a response to `message`
  """
  @spec reply_wikipedia(String.t(), Message.t()) :: any
  def reply_wikipedia(text, message) do
    response =
      text
      |> search_wikipedia()
      |> format_message()

    ChannelManager.reply(message, response)
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
  @spec reply_youtube(String.t(), Message.t()) :: any
  def reply_youtube(text, message) do
    response =
      text
      |> search_youtube()
      |> format_message()

    ChannelManager.reply(message, response)
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
  Searches Spotify albums for `text`, and returns the search
  result as a response to `message`
  """
  @spec reply_spotify_albums(String.t(), Message.t()) :: any
  def reply_spotify_albums(text, message) do
    response =
      text
      |> search_spotify_albums()
      |> format_message()

    ChannelManager.reply(message, response)
  end

  @doc """
  Searches Spotify for the given term and returns
  a link to the first album result. Returns `nil` if no result
  is found, or if Spotify cannot be reached.
  """
  @spec search_spotify_albums(String.t()) :: String.t() | nil
  def search_spotify_albums(term) do
    case Spotify.search_albums(term) do
      {:ok, %{"albums" => %{"items" => [%{"external_urls" => %{"spotify" => url}}]}}} -> url
      _ -> nil
    end
  end

  @doc """
  Searches Spotify tracks for `text`, and returns the search
  result as a response to `message`
  """
  @spec reply_spotify_tracks(String.t(), Message.t()) :: any
  def reply_spotify_tracks(text, message) do
    response =
      text
      |> search_spotify_albums()
      |> format_message()

    ChannelManager.reply(message, response)
  end

  @doc """
  Searches Spotify for the given term and returns
  a link to the first track result. Returns `nil` if no result
  is found, or if Spotify cannot be reached.
  """
  @spec search_spotify_tracks(String.t()) :: String.t() | nil
  def search_spotify_tracks(term) do
    case Spotify.search_tracks(term) do
      {:ok, %{"tracks" => %{"items" => [%{"external_urls" => %{"spotify" => url}}]}}} -> url
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

  def setup_handler do
    TokenManager.define(
      Services.Search.TokenManager,
      :spotify,
      @default_spotify_token_timeout,
      fn -> request_spotify_access_token() end
    )

    :ok
  end

  def request_spotify_access_token do
    {:ok, %{"access_token" => token}} = Spotify.request_temporary_token()
    token
  end

  @spec format_message(String.t() | nil) :: String.t()
  defp format_message(nil), do: "Nothing found :("
  defp format_message(text), do: text
end
