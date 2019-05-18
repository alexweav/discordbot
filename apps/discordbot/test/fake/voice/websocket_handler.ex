defmodule DiscordBot.Fake.Voice.WebsocketHandler do
  @moduledoc false
  @behaviour :cowboy_websocket

  def init(req, _args) do
    {:cowboy_websocket, req, %{}}
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:text, _text}, state) do
    {:ok, state}
  end

  def websocket_info(_, state), do: {:ok, state}
  def terminate(_reason, _req, _state), do: :ok
  def websocket_terminate(_reason, _req, _state), do: :ok
end
