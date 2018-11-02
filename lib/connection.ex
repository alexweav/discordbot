defmodule DiscordBot.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :ok)
  end
end
