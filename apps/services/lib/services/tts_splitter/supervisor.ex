defmodule Services.TtsSplitter.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    help = Services.Help.from_arg(opts)

    Supervisor.start_link(__MODULE__, {broker, help}, opts)
  end

  def init({broker, help}) do
    children = [
      {Task.Supervisor, name: Services.TtsSplitter.TaskSupervisor},
      {Services.TtsSplitter.Server, name: Services.TtsSplitter.Server, broker: broker, help: help}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
