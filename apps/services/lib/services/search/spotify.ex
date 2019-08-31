defmodule Services.Search.Spotify do
  @moduledoc """
  API client for Spotify
  """

  use HTTPoison.Base

  alias Services.Search.Spotify
  alias Services.Search.TokenManager

  @token_base_url Application.get_env(
                    :services,
                    :spotify_token_base_url,
                    "https://accounts.spotify.com"
                  )
  @api_base_url Application.get_env(:services, :spotify_api_base_url, "https://api.spotify.com")

  def request_temporary_token do
    url = @token_base_url <> "/api/token"
    body = URI.encode("grant_type=client_credentials")

    header = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Basic " <> full_auth_key(client_id(), api_key())}
    ]

    case Spotify.post(url, body, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{body: %{"error" => "invalid_client"}}} ->
        {:error, :invalid_client}

      response ->
        {:error, response}
    end
  end

  def search_albums(term, take \\ 1) do
    url =
      (@api_base_url <> "/v1/search?type=album")
      |> apply_query(term)
      |> apply_take(take)

    header = [
      {"Authorization", auth_header()}
    ]

    case Spotify.get(url, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
    end
  end

  def search_tracks(term, take \\ 1) do
    url =
      (@api_base_url <> "/v1/search?type=track")
      |> apply_query(term)
      |> apply_take(take)

    header = [
      {"Authorization", auth_header()}
    ]

    case Spotify.get(url, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
    end
  end

  def access_token do
    TokenManager.token?(Services.Search.TokenManager, :spotify)
  end

  def client_id do
    with nil <- Map.get(System.get_env(), "SPOTIFY_CLIENT_ID"),
         nil <- Application.get_env(:discordbot, :spotify_client_id) do
      nil
    else
      token -> token
    end
  end

  def api_key do
    with nil <- Map.get(System.get_env(), "SPOTIFY_CLIENT_SECRET"),
         nil <- Application.get_env(:discordbot, :spotify_client_secret) do
      nil
    else
      token -> token
    end
  end

  def full_auth_key(client_id, api_key) do
    Base.url_encode64(client_id <> ":" <> api_key)
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end

  defp apply_query(url, term) do
    url <> "&q=#{URI.encode(term)}"
  end

  defp apply_take(url, take) do
    url <> "&limit=#{take}"
  end

  @spec auth_header() :: String.t()
  defp auth_header do
    "Bearer #{access_token()}"
  end
end
