defmodule DiscordBot.Gateway.Supervisor do
  @moduledoc false

  use Supervisor
  require Logger

  def start_link(opts) do
    token = Keyword.fetch!(opts, :token)
    url = Keyword.fetch!(opts, :url)
    shard_index = Keyword.fetch!(opts, :shard_index)
    shard_count = Keyword.fetch!(opts, :shard_count)

    if (delay = Keyword.get(opts, :spawn_delay, 0)) > 0 do
      # TODO: this is a really hacky way of rigging the staggered launch of connections. Should probably change this.
      Logger.info("Waiting #{delay} milliseconds due to Identify ratelimiting.")
      Process.sleep(delay)
    end

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
      {DiscordBot.Gateway.Heartbeat, broker: instance_broker},
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

  @spec heartbeat?(pid) :: {:ok, pid} | :error
  def heartbeat?(supervisor) do
    DiscordBot.Util.child_by_id(supervisor, DiscordBot.Gateway.Heartbeat)
  end
end
