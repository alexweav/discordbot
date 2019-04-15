defmodule DiscordBot.Gateway.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    token = Keyword.fetch!(opts, :token)
    url = Keyword.fetch!(opts, :url)
    shard_index = Keyword.fetch!(opts, :shard_index)
    shard_count = Keyword.fetch!(opts, :shard_count)
    Supervisor.start_link(__MODULE__, {token, url, shard_index, shard_count}, opts)
  end

  @impl true
  def init({token, url, shard_index, shard_count}) do
    {:ok, instance_broker} =
      DynamicSupervisor.start_child(DiscordBot.Gateway.BrokerSupervisor, DiscordBot.Broker)

    children = [
      {DiscordBot.Broker.Shovel,
       source: instance_broker,
       destination: Broker,
       topics: [
         :dispatch,
         :status_update,
         :voice_state_update,
         :ready,
         :channel_create,
         :channel_update,
         :channel_delete,
         :guild_create,
         :guild_update,
         :guild_delete,
         :message_create,
         :message_update
       ]},
      {DiscordBot.Gateway.Heartbeat, broker: instance_broker, id: :heartbeat},
      Supervisor.child_spec(
        {Task,
         fn ->
           DiscordBot.Gateway.Authenticator.authenticate(
             instance_broker,
             token,
             shard_index,
             shard_count
           )
         end},
        id: :authenticator,
        restart: :transient
      ),
      {DiscordBot.Gateway.Connection, url: url, token: token, broker: instance_broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
