defmodule DiscordBot.Handlers.Search.Supervisor do
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
      {DiscordBot.Handlers.Search.TokenManager, name: DiscordBot.Search.TokenManager},
      {Task.Supervisor, name: DiscordBot.Search.TaskSupervisor},
      {DiscordBot.Handlers.Search.Server, name: DiscordBot.Search.Server, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
