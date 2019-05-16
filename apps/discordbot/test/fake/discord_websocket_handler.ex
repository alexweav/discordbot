defmodule DiscordBot.Fake.DiscordWebsocketHandler do
  @moduledoc false
  @behaviour :cowboy_websocket

  alias DiscordBot.Fake.DiscordCore
  alias DiscordBot.Model.Payload

  def init(req, args) do
    [core] = args
    DiscordCore.request_socket(core, req)
    {:cowboy_websocket, req, %{core: core}}
  end

  def websocket_init(state) do
    DiscordCore.register(state[:core])
    {:ok, state}
  end

  def websocket_handle({:ping, message}, state) do
    {:reply, {:pong, message}, state}
  end

  def websocket_handle({:text, text}, state) do
    DiscordCore.receive_text_frame(state[:core], text)
    {:ok, state}
  end

  def websocket_info({:hello, payload}, state) do
    {:ok, json} = Payload.to_json(payload)
    {:reply, [{:text, json}], state}
  end

  def websocket_info({:guild_create, payload}, state) do
    {:ok, json} = Payload.to_json(payload)
    {:reply, [{:text, json}], state}
  end

  def websocket_info(_, state), do: {:ok, state}

  def terminate(_reason, _req, _state), do: :ok

  def websocket_terminate(_reason, _req, _state), do: :ok
end
