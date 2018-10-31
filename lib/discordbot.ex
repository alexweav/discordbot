defmodule DiscordBot.Application do
  require Logger
  use Application

  @moduledoc """
  Entry point for the bot
  """

  def start(_type, _args) do
    children = []
    Logger.info("Launching...")
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
