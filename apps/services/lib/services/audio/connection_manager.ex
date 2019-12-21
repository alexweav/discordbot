defmodule Services.Audio.ConnectionManager do
  @moduledoc """
  Connection manager for RabbitMQ.
  """

  use GenServer

  require Logger

  @rmq_hostname Application.get_env(
                  :services,
                  :rmq_host,
                  "localhost"
                )

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_channel!(manager) do
    GenServer.call(manager, :get_channel, 60_000)
  end

  ## Handlers

  def init(:ok) do
    {:ok, nil}
  end

  def handle_call(:get_channel, _from, connection) do
    connection = try_connect!(connection, 5)
    {:ok, channel} = AMQP.Channel.open(connection)
    {:reply, channel, connection}
  end

  defp try_connect!(nil, num_retries) do
    Logger.info("Attempting to connect to RabbitMQ at #{@rmq_hostname}")
    {:ok, connection} = connect_retry_loop(num_retries)
    Logger.info("Connection succeeded")
    connection
  end

  defp try_connect!(connection, _), do: connection

  defp connect_retry_loop(1) do
    connect()
  end

  defp connect_retry_loop(num_retries) do
    case connect() do
      {:ok, connection} ->
        {:ok, connection}

      _ ->
        Logger.warn("Connection attempt failed, retrying...")
        Process.sleep(10_000)
        connect_retry_loop(num_retries - 1)
    end
  end

  defp connect do
    AMQP.Connection.open(host: @rmq_hostname)
  end
end
