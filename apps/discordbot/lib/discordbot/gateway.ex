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
      {DiscordBot.Gateway.Supervisor, token: token, url: url}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
