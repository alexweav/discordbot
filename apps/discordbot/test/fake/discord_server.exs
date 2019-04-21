defmodule DiscordBot.Fake.DiscordServer do
  @moduledoc false
  use Plug.Router

  def start(pid) do
    url = "wss://localhost:#{8473}/fakecord"
    url
  end
end
