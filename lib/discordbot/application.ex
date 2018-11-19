defmodule DiscordBot.Application do
  @moduledoc """
  Application entry point for the bot.
  """

  use Application

  def start(_type, _args) do
    children = [
      {DiscordBot.Token, strategy: :one_for_one},
      {DiscordBot, name: DiscordBot}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
