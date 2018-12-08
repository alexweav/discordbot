defmodule DiscordBot.Gateway do
  @moduledoc """
  Supervisor for the Gateway API
  """

  use Supervisor

  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)
    Supervisor.start_link(__MODULE__, url, opts)
  end

  def init(url) do
    token = DiscordBot.Token.token()

    children = [
      {DiscordBot.Gateway.Broker, [name: Broker]},
      {DiscordBot.Gateway.EventLogger,
       [name: EventLogger, broker: Broker, topics: [:dispatch, :ready, :guild_create]]},
      {DiscordBot.Gateway.Heartbeat, []},
      Supervisor.child_spec(
        {Task, fn -> DiscordBot.Gateway.Authenticator.authenticate(token, Broker) end},
        restart: :transient
      ),
      {DiscordBot.Gateway.Connection, [url, token]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
