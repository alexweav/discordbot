defmodule DiscordBot.Fake.DiscordWebsocketHandler do
  @moduledoc false
  @behaviour :cowboy_websocket

  @timeout 10000

  def init(req, state) do
    {:cowboy_websocket, req, state}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:ping, message}, state) do
    {:reply, {:pong, message}, state}
  end

  def websocket_handle({:text, text}, state) do
    IO.puts(text)
    {:ok, state}
  end

  def terminate(_reason, _req, _state), do: :ok

  def websocket_terminate(_reason, _req, _state), do: :ok
end
