defmodule Services.Search.Youtube do
  @moduledoc """
  API client for YouTube
  """

  use HTTPoison.Base

  alias Services.Search.Youtube

  @api_base_url Application.get_env(
                  :services,
                  :youtube_api_base_url,
                  "https://www.googleapis.com/youtube"
                )

  @doc """
  Searches videos on YouTube given a term.
  `take` indicates maximum number of elements to return,
  which is by default 1.
  """
  def search_videos(term, take \\ 1) do
    uri =
      (@api_base_url <> "/v3/search?part=snippet")
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
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end

  defp api_key do
    Application.get_env(:discordbot, :youtube_data_api_key)
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
