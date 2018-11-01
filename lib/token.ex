defmodule DiscordBot.Token do
  @moduledoc """
  Agent for keeping track of the bot token
  """

  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @doc "Obtains the bot token"
  @spec get() :: String.t()
  def get() do
    case Agent.get(__MODULE__, fn state -> state end) do
      nil ->
        token = token_fallback()
        Agent.update(__MODULE__, fn _ -> token end)
        token

      token ->
        token
    end
  end

  defp token_fallback() do
    case Map.get(System.get_env(), "TOKEN") do
      nil ->
        case Application.get_env(:discordbot, :token) do
          nil ->
            raise(
              "No token found. Please provide a bot token, either by environment variable (TOKEN) or via confix.exs."
            )

          token ->
            token
        end

      token ->
        token
    end
  end
end
