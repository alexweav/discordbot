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
    children = [
      {DiscordBot.Gateway.Broker, [name: Broker]},
      {DiscordBot.Gateway.Heartbeat, []},
      {DiscordBot.Gateway.Connection, [url, DiscordBot.Token.token()]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
