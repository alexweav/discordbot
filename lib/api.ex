defmodule DiscordBot.Api do
  @moduledoc """
  API module for Discord
  """

  use HTTPoison.Base

  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  def process_request_url(uri) do
    "https://discordapp.com/api/" <> uri
  end
end
