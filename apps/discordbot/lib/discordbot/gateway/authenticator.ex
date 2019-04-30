defmodule DiscordBot.Gateway.Authenticator do
  @moduledoc """
  Controls authentication for connections and gateways.
  """

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event
  alias DiscordBot.Gateway.Connection

  @doc """
  Authenticates connections over a `broker`.

  Listens for `:hello` events indicating a new connection.
  Blocks until a new connection occurrs, and then attempts
  to authenticate the event's source connection with `token`.
  """
  @spec authenticate(pid | atom, String.t()) :: :ok
  def authenticate(broker, token), do: authenticate(broker, token, 0, 1)

  @doc """
  Authenticates connections and provides sharding info.
  """
  @spec authenticate(pid | atom, String.t(), integer, integer) :: :ok
  def authenticate(broker, token, shard_index, shard_count) do
    Broker.subscribe(broker, :hello)
    connection = wait_for_connect()
    Connection.identify(connection, token, shard_index, shard_count)
  end

  defp wait_for_connect do
    receive do
      %Event{publisher: publisher} -> publisher
    end
  end
end
