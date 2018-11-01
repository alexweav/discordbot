defmodule DiscordBot.Api do
  @moduledoc """
  API module for Discord
  """

  use HTTPoison.Base

  @doc "Appends the base URL onto a short-form URI"
  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  def process_request_url(uri) do
    "https://discordapp.com/api/" <> uri
  end

  @doc "Appends global request headers to an existing set"
  def process_request_headers(existing) do
    token = DiscordBot.Token.get()

    [
      {"Authorization", "Bot " <> token}
      | existing
    ]
  end
end
