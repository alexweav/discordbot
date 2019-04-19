defmodule Services.Netstat.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    help = Services.Help.from_arg(opts)
    Supervisor.start_link(__MODULE__, {broker, help}, opts)
  end

  def init({broker, help}) do
    children = [
      {Task.Supervisor, name: Services.Netstat.TaskSupervisor},
      {Services.Netstat.Server, name: Services.Netstat.Server, broker: broker, help: help}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
