defmodule DiscordBot.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  def start_link(url) do
    WebSockex.start_link(url <> "/?v=6&encoding=json", __MODULE__, :ok)
  end

  def handle_connect(connection, _state) do
    Logger.info("Connected!")
    IO.inspect connection
    {:ok, :ok}
  end

  def handle_frame(frame, _state) do
    Logger.info("Got message.")
    IO.inspect frame
  end

  def handle_disconnect(_reason, _state) do
    Logger.info("Disconnected.")
  end

  def terminate(_reason, _state) do
    Logger.info("Terminated.")
    exit(:normal)
  end
end
