defmodule Services.Search.Wikipedia do
  @moduledoc """
  API client for Wikipedia
  """

  use HTTPoison.Base

  alias Services.Search.Wikipedia

  @doc """
  Searches articles on Wikipedia given a term.
  `take` indicates maximum the number of articles to return,
  which is by default 1.
  """
  @spec search_articles(String.t(), integer) :: {:ok, list} | {:error, HTTPoison, Response.t()}
  def search_articles(term, take \\ 1) do
    base_uri = "/w/api.php?action=opensearch&namespace=0&format=json"
    search_uri = "#{base_uri}&limit=#{take}&search=#{URI.encode(term)}"

    case Wikipedia.get(search_uri) do
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
    "https://en.wikipedia.org/" <> uri
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end
