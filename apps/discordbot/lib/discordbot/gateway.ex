defmodule DiscordBot.Gateway do
  @moduledoc false

  use Supervisor

  @default_shard_count 1

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, url, opts)
  end

  def init(url) do
    token = DiscordBot.Configuration.token!()
    shard_count = connection_count()

    children =
      [
        {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one}
      ] ++ gateway_specs(token, url, shard_count)

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec connection_count() :: integer
  def connection_count() do
    DiscordBot.Configuration.shards() || @default_shard_count
  end

  @spec get_gateway_instance(pid, integer) :: :error | {:ok, pid}
  def get_gateway_instance(supervisor, shard_index) do
    if shard_index < 0 || shard_index >= connection_count() do
      :error
    else
      DiscordBot.Util.child_by_id(supervisor, id_from_index(shard_index))
    end
  end

  defp gateway_specs(token, url, shard_count) do
    for idx <- 0..(shard_count - 1), do: gateway_sup_spec(token, url, idx, shard_count)
  end

  defp gateway_sup_spec(token, url, shard_index, shard_count) do
    Supervisor.child_spec(
      {
        DiscordBot.Gateway.Supervisor,
        token: token,
        url: url,
        shard_index: shard_index,
        shard_count: shard_count,
        spawn_delay: spawn_delay(shard_index)
      },
      id: id_from_index(shard_index)
    )
  end

  defp id_from_index(shard_index), do: "DiscordBot.GatewayInstance-#{shard_index}"

  defp spawn_delay(0), do: 0
  defp spawn_delay(_), do: 5000
end
