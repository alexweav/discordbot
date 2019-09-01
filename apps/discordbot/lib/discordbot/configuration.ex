defmodule DiscordBot.Configuration do
  @moduledoc """
  Helpers for keeping track of the bot token
  """

  @token_env_var_key "TOKEN"
  @shards_env_var_key "SHARDS"

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

  @doc """
  Gets the shard count, if provided through any configuration method.
  """
  @spec shards() :: integer | nil
  def shards do
    with nil <- shards_env(),
         nil <- shards_config() do
      nil
    else
      shards -> shards
    end
  end

  @doc """
  Gets the shard count, if defined via env variable, or `nil` otherwise.
  """
  @spec shards_env() :: integer | nil
  def shards_env do
    case System.get_env()
         |> Map.get(@shards_env_var_key)
         # Workaround for bug in Integer.parse() where an exception occurs if `nil` is passed in
         |> to_string()
         |> Integer.parse() do
      {int, _} -> int
      :error -> nil
    end
  end

  @doc """
  Gets the shard count, if defined via app config, or `nil` otherwise.
  """
  @spec shards_config() :: integer | nil
  def shards_config do
    Application.get_env(:discordbot, :shards)
  end

  @doc """
  Loads a system environment variable into the configuration for a
  certain application.

  The given environment variable may then be
  accessed via `Application.get_env/3` or `Application.fetch_env/1`.
  The given configuration key is not set if the environment variable
  is not defined - this is useful for overriding application config keys
  with environment variables.
  """
  @spec load_env_var(String.t(), atom, atom) :: :ok | :error
  def load_env_var(name, app, key) do
    case System.fetch_env(name) do
      {:ok, value} -> Application.put_env(app, key, value)
      :error -> :error
    end
  end
end
