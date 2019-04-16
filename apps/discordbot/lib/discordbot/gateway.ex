defmodule DiscordBot.Gateway do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, url, opts)
  end

  def init(url) do
    token = DiscordBot.Token.token()

    children = [
      {DynamicSupervisor, name: DiscordBot.Gateway.BrokerSupervisor, strategy: :one_for_one},
      gateway_sup_spec(token, url, 0, 2),
      gateway_sup_spec(token, url, 1, 2)
    ]

    Supervisor.init(children, strategy: :one_for_all)
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
