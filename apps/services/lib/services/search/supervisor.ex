defmodule Services.Search.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    Supervisor.start_link(__MODULE__, broker, opts)
  end

  def init(broker) do
    children = [
      {Services.Search.TokenManager, name: Services.Search.TokenManager, strategy: :one_for_all},
      {Task.Supervisor, name: Services.Search.TaskSupervisor},
      {Services.Search.Server, name: Services.Search.Server, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
