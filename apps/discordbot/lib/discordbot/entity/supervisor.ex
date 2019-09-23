defmodule DiscordBot.Entity.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    Supervisor.start_link(__MODULE__, broker, opts)
  end

  def init(broker) do
    children = [
      {DiscordBot.Entity.Guilds, name: DiscordBot.Guilds, broker: broker},
      {DiscordBot.Entity.Channels, name: DiscordBot.Channels, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
