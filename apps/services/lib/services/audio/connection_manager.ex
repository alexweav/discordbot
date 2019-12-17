defmodule Services.Audio.ConnectionManager do
  @moduledoc """
  Connection manager for RabbitMQ.
  """

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Handlers

  def init(:ok) do
    {:ok, :ok}
  end
end
