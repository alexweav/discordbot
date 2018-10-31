defmodule DiscordBot do
  use Application
  require Logger

  @moduledoc """
  Application entry point for the bot.
  """

  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one]
    Logger.info("Launching...")
    Supervisor.start_link(children, opts)
  end
end
