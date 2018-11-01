defmodule DiscordBot do
  @moduledoc """
  Top-level supervisor for the bot
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    children = []
    Logger.info("Launching...")
    DiscordBot.Api.start()
    Supervisor.init(children, strategy: :one_for_one)
  end
end
