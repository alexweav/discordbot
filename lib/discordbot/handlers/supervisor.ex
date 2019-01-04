defmodule DiscordBot.Handlers.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = [
      {DiscordBot.Handlers.Help, [broker: Broker, name: DiscordBot.Help]},
      {DiscordBot.Handlers.Ping, Broker},
      {Task.Supervisor, name: DiscordBot.TtsSplitter.TaskSupervisor},
      {DiscordBot.Handlers.TtsSplitter, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
