defmodule DiscordBot.Handlers.TtsSplitter.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    help = DiscordBot.Handlers.Help.from_arg(opts)

    Supervisor.start_link(__MODULE__, {broker, help}, opts)
  end

  def init({broker, help}) do
    children = [
      {Task.Supervisor, name: DiscordBot.TtsSplitter.TaskSupervisor},
      {DiscordBot.Handlers.TtsSplitter.Server,
       name: DiscordBot.TtsSplitter.Server, broker: broker, help: help}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
