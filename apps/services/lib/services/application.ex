defmodule Services.Application do
  @moduledoc """
  Application entry point for an app which contains services for the various commands
  provided by the bot.
  """

  use Application

  def start(_type, _args) do
    children = [
      {Services, name: Services.Supervisor}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
