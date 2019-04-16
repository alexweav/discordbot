defmodule DiscordBot.Gateway do
  @moduledoc false

  use Supervisor

  @default_shard_count 2

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, url, opts)
  end

  def init(url) do
    token = DiscordBot.Token.token()

    children =
      [
        {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one}
      ] ++ gateway_specs(token, url, @default_shard_count)

    Supervisor.init(children, strategy: :one_for_all)
  end

  defp gateway_specs(token, url, shard_count) do
    for idx <- 0..(shard_count - 1), do: gateway_sup_spec(token, url, idx, shard_count)
  end

  defp gateway_sup_spec(token, url, shard_index, shard_count) do
    Supervisor.child_spec(
      {
        DiscordBot.Gateway.Supervisor,
        token: token, url: url, shard_index: shard_index, shard_count: shard_count
      },
      id: shard_index
    )
  end
end
