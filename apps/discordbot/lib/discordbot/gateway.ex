defmodule DiscordBot.Gateway do
  @moduledoc false

  use Supervisor

  @default_shard_count 1

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    shard_count = Keyword.get(opts, :shard_count, nil)
    Supervisor.start_link(__MODULE__, {url, shard_count}, opts)
  end

  def init({url, shard_count_arg}) do
    token = DiscordBot.Configuration.token!()
    shard_count = shard_count_arg || DiscordBot.Configuration.shards() || @default_shard_count

    children =
      [
        {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one}
      ] ++ gateway_specs(token, url, shard_count)

    Supervisor.init(children, strategy: :one_for_all)
  end

  @spec active_gateways(pid | atom) :: list(pid)
  def active_gateways(gateway) do
    gateway
    |> Supervisor.which_children()
    |> Enum.filter(&is_connection(&1))
    |> Enum.map(&elem(&1, 1))
  end

  @spec get_gateway_instance(atom | pid, integer) :: :error | {:ok, pid}
  def get_gateway_instance(supervisor, shard_index) do
    if shard_index < 0 do
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

  @spec is_connection({String.t() | atom, pid | atom, any, any}) :: boolean
  defp is_connection({_, :undefined, _, _}), do: false
  defp is_connection({_, :restarting, _, _}), do: false
  defp is_connection({id, _, _, _}) when is_atom(id), do: false

  defp is_connection({id, _, _, _}) do
    id
    |> String.starts_with?("DiscordBot.GatewayInstance-")
  end

  defp id_from_index(shard_index), do: "DiscordBot.GatewayInstance-#{shard_index}"

  defp spawn_delay(0), do: 0
  defp spawn_delay(_), do: 5000
end
