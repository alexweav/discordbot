defmodule DiscordBot.Handlers.Search.Spotify do
  @moduledoc """
  API client for Spotify
  """

  use HTTPoison.Base

  alias DiscordBot.Handlers.Search.Spotify

  def request_temporary_token do
    url = "https://accounts.spotify.com/api/token"

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
end
