defmodule DiscordBot.Fake.DiscordWebsocketHandler do
  @moduledoc false
  @behaviour :cowboy_websocket

  def init(req, args) do
    [core] = args
    DiscordBot.Fake.DiscordCore.request_socket(core, req)
    {:cowboy_websocket, req, %{core: core}}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:ping, message}, state) do
    {:reply, {:pong, message}, state}
  end

  def websocket_handle({:text, text}, state) do
    DiscordBot.Fake.DiscordCore.receive_text_frame(state[:core], text)
    {:ok, state}
  end

  def terminate(_reason, _req, _state), do: :ok

  def websocket_terminate(_reason, _req, _state), do: :ok
end
