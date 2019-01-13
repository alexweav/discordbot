defmodule DiscordBot.Handlers.Search.Spotify do
  @moduledoc """
  API client for Spotify
  """

  use HTTPoison.Base

  alias DiscordBot.Handlers.Search.Spotify

  def request_temporary_token do
    url = "https://accounts.spotify.com/api/token"

    body =
      %{"grant_type" => "client_credentials"}
      |> Poison.encode!()

    header = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case Spotify.post(url, body, header) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{body: %{"error" => "invalid_client"}}} ->
        {:error, :invalid_client}

      response ->
        {:error, response}
    end
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end
