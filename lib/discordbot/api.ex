defmodule DiscordBot.Api do
  @moduledoc """
  API module for Discord
  """

  use HTTPoison.Base

  @spec request_gateway() ::
          {:ok, map} | {:error, :invalid_token} | {:error, HTTPoison.Response.t()}
  def request_gateway do
    get_gateway_bot_uri = "/v7/gateway/bot"

    case DiscordBot.Api.get!(get_gateway_bot_uri) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}

      %HTTPoison.Response{status_code: 401} ->
        {:error, :invalid_token}

      response ->
        {:error, response}
    end
  end

  @doc """
  Posts a message with content `content` to the channel with ID `channel_id`
  """
  def create_message(channel_id, content) do
    uri = "/v7/channels/" <> channel_id <> "/messages"

    body =
      Poison.encode!(%{
        "content" => content
      })

    DiscordBot.Api.post(uri, body)
  end

  @doc """
  Appends the base URL onto a short-form URI
  """
  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  def process_request_url(uri) do
    "https://discordapp.com/api/" <> uri
  end

  @doc """
  Appends global request headers to an existing set
  """
  def process_request_headers(existing) do
    token = DiscordBot.Token.token()

    [
      {"Authorization", "Bot " <> token},
      {"Content-Type", "application/json"}
      | existing
    ]
  end

  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end
