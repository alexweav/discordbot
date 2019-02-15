defmodule DiscordBot.Entity.Supervisor do
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
      {DynamicSupervisor, name: DiscordBot.EntitySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: DiscordBot.ChannelRegistry},
      {DiscordBot.Entity.ChannelManager, name: DiscordBot.ChannelManager, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
