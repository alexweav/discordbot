defmodule DiscordBot.Gateway.Connection do
  @moduledoc """
  Represents a single websocket connection to Discord.
  """

  use WebSockex
  require Logger

  def start_link([url, token]) do
    state = %{
      url: url <> "/?v=6&encoding=json",
      token: token
    }

    WebSockex.start_link(state[:url], __MODULE__, state)
  end

  def handle_connect(connection, state) do
    Logger.info("Connected!")
    {:ok, Map.put(state, :connection, connection)}
  end

  def handle_frame({:text, json}, state) do
    Logger.info("Got message.")
    IO.inspect(Poison.decode!(json))
    {:ok, state}
  end

  def handle_frame(frame, state) do
    Logger.info("Got other frame.")
    IO.inspect(frame)
    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    Logger.info("Disconnected.")
    {:ok, state}
  end

  def terminate(_reason, _state) do
    Logger.info("Terminated.")
    exit(:normal)
  end
end
