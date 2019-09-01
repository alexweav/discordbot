defmodule DiscordBot.ConfigurationTest do
  use ExUnit.Case, async: false

  test "gets bot token from ENV var first" do
    existing_var = Map.fetch(System.get_env(), "TOKEN")

    System.put_env("TOKEN", "test-token")
    assert DiscordBot.Configuration.token!() == "test-token"

    case existing_var do
      {:ok, existing} -> System.put_env("TOKEN", existing)
      :error -> nil
    end
  end

  test "gets shard count from ENV var first" do
    existing_var = Map.fetch(System.get_env(), "SHARDS")

    System.put_env("SHARDS", "1234")
    assert DiscordBot.Configuration.shards() == 1234

    case existing_var do
      {:ok, existing} -> System.put_env("SHARDS", existing)
      :error -> nil
    end
  end

  test "loads env vars into application env" do
    System.put_env("TEST_KEY", "TEST_VALUE")
    assert DiscordBot.Configuration.load_env_var("TEST_KEY", :discordbot, :test_key) == :ok
    assert Application.fetch_env(:discordbot, :test_key) == {:ok, "TEST_VALUE"}
  end

  test "doesn't set app env key if env var doesn't exist" do
    assert DiscordBot.Configuration.load_env_var("NOT_EXIST", :discordbot, :not_exist) == :error
    assert Application.fetch_env(:discordbot, :not_exist) == :error
  end
end
