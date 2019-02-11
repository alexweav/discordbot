defmodule DiscordBot.Gateway.Authenticator do
  @moduledoc """
  Authenticates the bot over the gateway
  """

  alias DiscordBot.Broker.Event

  @doc """
  Authenticates connections over a `broker`.
  Listens for `:hello` events indicating a new connection.
  Blocks until a new connection occurrs, and then attempts
  to authenticate the event's source connection with `token`.
  """
  def authenticate(token, broker) do
    DiscordBot.Broker.subscribe(broker, :hello)
    connection = wait_for_connect(broker)
    DiscordBot.Gateway.Connection.identify(connection, token, 0, 1)
    :ok
  end

  defp wait_for_connect(_broker) do
    receive do
      %Event{publisher: publisher} -> publisher
    end
  end
end
