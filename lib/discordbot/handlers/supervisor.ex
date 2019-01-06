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
      {DiscordBot.Handlers.TtsSplitter.Supervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
