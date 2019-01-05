defmodule DiscordBot.Handlers.TtsSplitter.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {Task.Supervisor, name: DiscordBot.TtsSplitter.TaskSupervisor},
      {DiscordBot.Handlers.TtsSplitter.Server, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
