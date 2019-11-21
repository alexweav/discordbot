defmodule DiscordBot.Voice.Acceptor do
  @moduledoc """
  Launches a voice connection.
  """

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Gateway.Api
  alias DiscordBot.Voice.Launcher

  @default_timeout_milliseconds 10_000

  def accept(guild_id, channel_id, self_mute, self_deaf) do
    broker = Elixir.Broker
    Broker.subscribe(broker, :voice_state_update)
    Broker.subscribe(broker, :voice_server_update)
    Api.update_voice_state(guild_id, channel_id, self_mute, self_deaf)

    recv_loop(nil, nil)
  end

  defp recv_loop(state, server) when state != nil and server != nil do
    Logger.info("Preparing new voice connection.")
    Launcher.establish(state, server)
    :ok
  end

  defp recv_loop(state, server) do
    receive do
      %Event{topic: :voice_state_update, message: message} ->
        recv_loop(message, server)

      %Event{topic: :voice_server_update, message: message} ->
        recv_loop(state, message)
    after
      @default_timeout_milliseconds -> :error
    end
  end
end
