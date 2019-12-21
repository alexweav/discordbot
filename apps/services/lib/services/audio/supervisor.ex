defmodule Services.Audio.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Task.Supervisor, name: Services.Audio.TaskSupervisor},
      {Services.Audio.ConnectionManager, name: Services.Audio.ConnectionManager},
      {Services.Audio.Spawner, :ok}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
