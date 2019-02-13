defmodule DiscordBot.Api do
  @moduledoc """
  This module is a thin wrapper for Discord's HTTP API.
  Its functions directly result in HTTP calls to Discord.
  """

  use HTTPoison.Base
  alias HTTPoison.Response

  @callback request_gateway() ::
              {:ok, map}
              | {:error, :invalid_token}
              | {:error, Response.t()}

  @callback create_message(String.t(), String.t()) ::
              {:ok, Response.t()}
              | {:error, Response.t()}
              | {:error, any}

  @callback create_tts_message(String.t(), String.t()) ::
              {:ok, Response.t()}
              | {:error, Response.t()}
              | {:error, any}

  ## Implementation

  @doc """
  Requests Gateway (websocket) access to Discord.

  Users are authenticated via the API key given by `DiscordBot.Token.token/0`.
  If gateway access is granted, this call returns a map containing the following fields:
  - `"url"`: the websocket address to connect to.
  - `"shards"`: the recommended number of shards to use.
  - `"session_start_limit"`: an object containing information regarding the maximum number of requests which can be made.

  In the event that the token given by `DiscordBot.Token.token/0` is rejected,
  this call returns `{:ok, :invalid_token}`.

  ## Examples

      DiscordBot.Api.request_gateway()
      {:ok,
        {
          "url" => "wss://gateway.discord.gg/",
          "shards" => 9,
          "session_start_limit" => {
            "total" => 1000,
            "remaining" => 999,
            "reset_after" => 14400000
          }
        }
      }

      DiscordBot.Api.request_gateway()
      {:error, :invalid_token}

  """
  @spec request_gateway() ::
          {:ok, map}
          | {:error, :invalid_token}
          | {:error, Response.t()}
  def request_gateway do
    uri = "/v7/gateway/bot"

    case DiscordBot.Api.get!(uri) do
      %Response{status_code: 200, body: body} ->
        {:ok, body}

      %Response{status_code: 401} ->
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

    case DiscordBot.Api.post(uri, body) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %Response{body: body}} ->
        {:error, body}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Posts a message with TTS enabled, with content `content`
  to the channel with ID `channel`.
  """
  def create_tts_message(channel_id, content) do
    uri = "/v7/channels/" <> channel_id <> "/messages"

    body =
      Poison.encode!(%{
        "content" => content,
        "tts" => true
      })

    case DiscordBot.Api.post(uri, body) do
      {:ok, %Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %Response{body: body}} ->
        {:error, body}

      {:error, error} ->
        {:error, error}
    end
  end

  ## HTTPoison.Base Callbacks

  @doc false
  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  def process_request_url(uri) do
    "https://discordapp.com/api/" <> uri
  end

  @doc false
  def process_request_headers(existing) do
    token = DiscordBot.Token.token()

    [
      {"Authorization", "Bot " <> token},
      {"Content-Type", "application/json"}
      | existing
    ]
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end
