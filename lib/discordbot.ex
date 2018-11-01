defmodule DiscordBot do
  @moduledoc """
  Top-level supervisor for the bot
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    token = Keyword.fetch!(opts, :token)
    Supervisor.start_link(__MODULE__, token, opts)
  end

  def init(_token) do
    children = []
    Logger.info("Launching...")
    DiscordBot.Api.start()
    Supervisor.init(children, strategy: :one_for_one)
  end
end
