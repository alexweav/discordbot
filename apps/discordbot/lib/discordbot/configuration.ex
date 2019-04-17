defmodule DiscordBot.Configuration do
  @moduledoc """
  Helpers for keeping track of the bot token
  """

  @token_env_var_key "TOKEN"

  @doc """
  Returns the Discord bot token given the various configuration inputs.
  """
  @spec token!() :: String.t()
  def token! do
    with nil <- token_env(),
         nil <- token_config() do
      raise(
        "No token found. Please provide a bot token, either by environment variable (TOKEN) or via confix.exs."
      )
    else
      token -> token
    end
  end

  @doc """
  Returns the discord bot token, if it is defined via environment variable,
  or `nil` otherwise.
  """
  @spec token_env() :: String.t() | nil
  def token_env do
    Map.get(System.get_env(), @token_env_var_key)
  end

  @doc """
  Returns the discord bot token, if it is defined via application configuration,
  or `nil` otherwise.
  """
  @spec token_config() :: String.t() | nil
  def token_config do
    Application.get_env(:discordbot, :token)
  end
end
