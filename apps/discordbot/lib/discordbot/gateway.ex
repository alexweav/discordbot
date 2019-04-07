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
      {DiscordBot.Gateway.Supervisor, token: token, url: url, name: DiscordBot.GatewaySupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
