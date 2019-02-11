defmodule Services do
  @moduledoc """
  Top-level supervisor for services.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Services.Help, [broker: Broker, name: Services.Help]},
      {Services.Ping, Broker}
    ]

    Logger.info("Launching services...")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
