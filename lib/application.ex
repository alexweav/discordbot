defmodule DiscordBot.Application do
  @moduledoc """
  Application entry point for the bot.
  """

  use Application

  def start(_type, _args) do
    children = [
      {DiscordBot, name: DiscordBot, token: token()}
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end

  defp token() do
    case Map.get(System.get_env(), "TOKEN") do
      nil ->
        case Application.get_env(:discordbot, :token) do
          nil -> raise("no token lol")
          token -> token
        end

      token ->
        token
    end
  end
end
