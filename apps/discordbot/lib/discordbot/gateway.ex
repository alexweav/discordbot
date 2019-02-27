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
      {DiscordBot.Gateway.Supervisor, []},
      {DiscordBot.Gateway.Heartbeat, broker: Broker},
      Supervisor.child_spec(
        {Task, fn -> DiscordBot.Gateway.Authenticator.authenticate(token, Broker) end},
        restart: :transient
      ),
      {DiscordBot.Gateway.Connection, url: url, token: token, broker: Broker}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
