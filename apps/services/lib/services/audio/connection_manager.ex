defmodule Services.Audio.ConnectionManager do
  @moduledoc """
  Connection manager for RabbitMQ.
  """

  use GenServer

  require Logger

  @rmq_hostname "rabbitmq"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_channel!(manager) do
    GenServer.call(manager, :get_channel)
  end

  ## Handlers

  def init(:ok) do
    {:ok, nil}
  end

  def handle_call(:get_channel, _from, connection) do
    connection = try_connect!(connection)
    {:ok, channel} = AMQP.Channel.open(connection)
    {:reply, channel, connection}
  end

  defp try_connect!(nil) do
    Logger.info("Attempting to connect to RabbitMQ at #{@rmq_hostname}")
    {:ok, connection} = AMQP.Connection.open(host: @rmq_hostname)
    Logger.info("Connection succeeded")
    connection
  end

  defp try_connect!(connection), do: connection
end
