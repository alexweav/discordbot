defmodule DiscordBot.Gateway.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    token = Keyword.fetch!(opts, :token)
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, {token, url}, opts)
  end

  @impl true
  def init({token, url}) do
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
        {Task, fn -> DiscordBot.Gateway.Authenticator.authenticate(instance_broker, token) end},
        id: :authenticator,
        restart: :transient
      ),
      {DiscordBot.Gateway.Connection, url: url, token: token, broker: instance_broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
