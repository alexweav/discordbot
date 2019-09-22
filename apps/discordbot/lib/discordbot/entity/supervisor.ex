defmodule DiscordBot.Entity.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    broker = Keyword.get(opts, :broker, Broker)
    api = Keyword.get(opts, :api, DiscordBot.Api)

    Supervisor.start_link(__MODULE__, {broker, api}, opts)
  end

  def init({broker, api}) do
    children = [
      {DynamicSupervisor, name: DiscordBot.EntitySupervisor, strategy: :one_for_one},
      {Registry, keys: :unique, name: DiscordBot.ChannelRegistry},
      {DiscordBot.Entity.ChannelManager,
       name: DiscordBot.ChannelManager, broker: broker, api: api},
      {DiscordBot.Entity.Guilds, name: DiscordBot.Guilds, broker: broker, api: api},
      {DiscordBot.Entity.Channels, name: DiscordBot.Channels, broker: broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
