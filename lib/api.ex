defmodule DiscordBot.Api do
  def base_url("/" <> uri) do
    base_url(uri)
  end

  def base_url(uri) do
    "https://discordapp.com/api/" <> uri
  end
end
