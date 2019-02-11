defmodule DiscordBot.Handlers.Search.Youtube do
  @moduledoc """
  API client for YouTube
  """

  use HTTPoison.Base

  alias DiscordBot.Handlers.Search.Youtube

  @doc """
  Searches videos on YouTube given a term.
  `take` indicates maximum number of elements to return,
  which is by default 1.
  """
  def search_videos(term, take \\ 1) do
    uri =
      "/v3/search?part=snippet"
      |> apply_type(:video)
      |> apply_take(take)
      |> apply_query(term)
      |> apply_api_key()

    case Youtube.get(uri) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      response ->
        {:error, response}
    end
  end

  @doc false
  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  @doc false
  def process_request_url(uri) do
    "https://www.googleapis.com/youtube/" <> uri
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end

  defp api_key do
    case Map.get(System.get_env(), "YOUTUBE_DATA_API_KEY") do
      nil ->
        case Application.get_env(:discordbot, :youtube_data_api_key) do
          nil -> nil
          token -> token
        end

      token ->
        token
    end
  end

  defp apply_type(url, :video) do
    url <> "&type=video"
  end

  defp apply_take(url, take) do
    url <> "&maxResults=#{take}"
  end

  defp apply_query(url, term) do
    url <> "&q=#{URI.encode(term)}"
  end

  defp apply_api_key(url) do
    url <> "&key=#{api_key()}"
  end
end
