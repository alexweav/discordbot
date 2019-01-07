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

  def init(_broker) do
    children = [
      {Task.Supervisor, name: DiscordBot.Search.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
