defmodule Services.Search.Wikipedia do
  @moduledoc """
  API client for Wikipedia
  """

  use HTTPoison.Base

  alias Services.Search.Wikipedia

  @api_base_url Application.get_env(
                  :services,
                  :wikipedia_api_base_url,
                  "https://en.wikipedia.org"
                )

  @doc """
  Searches articles on Wikipedia given a term.
  `take` indicates maximum the number of articles to return,
  which is by default 1.
  """
  @spec search_articles(String.t(), integer) :: {:ok, list} | {:error, HTTPoison, Response.t()}
  def search_articles(term, take \\ 1) do
    core_uri = "/w/api.php?action=opensearch&namespace=0&format=json"
    search_params = "&limit=#{take}&search=#{URI.encode(term)}"

    url = @api_base_url <> core_uri <> search_params

    case Wikipedia.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      response ->
        {:error, response}
    end
  end

  @doc false
  def process_response_body(body) do
    IO.inspect(body)

    body
    |> Poison.decode!()
  end
end
