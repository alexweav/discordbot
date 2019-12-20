defmodule Services.Audio.ConnectionManager do
  @moduledoc """
  Connection manager for RabbitMQ.
  """

  use GenServer

  require Logger

  # @rmq_hostname "rabbitmq"
  # @rmq_username "guest"
  # @rmq_password "guest"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def open(manager, host) do
    GenServer.cast(manager, {:connect, host})
  end

  ## Handlers

  def init(:ok) do
    {:ok, :ok}
  end

  def handle_cast({:connect, host}, state) do
    Logger.info("Attempting to connect to #{host}")
    {:ok, connection} = AMQP.Connection.open(host: host)
    IO.inspect(connection)
    Logger.info("Connection succeeded")
    {:noreply, state}
  end
end
