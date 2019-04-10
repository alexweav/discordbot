defmodule DiscordBot.Gateway.Authenticator do
  @moduledoc """
  Controls authentication for connections and gateways.
  """

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Gateway

  @doc """
  Authenticates connections over a `broker`.

  Listens for `:hello` events indicating a new connection.
  Blocks until a new connection occurrs, and then attempts
  to authenticate the event's source connection with `token`.
  """
  @spec authenticate(pid | atom, String.t()) :: :ok
  def authenticate(broker, token) do
    Broker.subscribe(broker, :hello)
    connection = wait_for_connect(broker)
    DiscordBot.Gateway.Connection.identify(connection, token, 0, 1)
    :ok
  end

  @doc """
  Authenticates a gateway process once the gateway connects.
  """
  @spec authenticate_gateway(pid | atom, String.t()) :: :ok
  def authenticate_gateway(gateway, token) do
    gateway
    |> Gateway.Supervisor.broker?()
    |> authenticate(token)
  end

  defp wait_for_connect(_broker) do
    receive do
      %Event{publisher: publisher} -> publisher
    end
  end
end
