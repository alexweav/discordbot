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
    System.put_env("TEST_KEY1", "TEST_VALUE")
    assert DiscordBot.Configuration.load_env_var("TEST_KEY1", :discordbot, :test_key1) == :ok
    assert Application.fetch_env(:discordbot, :test_key1) == {:ok, "TEST_VALUE"}
  end

  test "doesn't set app env key if env var doesn't exist" do
    assert DiscordBot.Configuration.load_env_var("NOT_EXIST", :discordbot, :not_exist) == :error
    assert Application.fetch_env(:discordbot, :not_exist) == :error
  end

  test "loads numeric env vars into application env" do
    System.put_env("TEST_KEY2", "42")
    assert DiscordBot.Configuration.load_int_env_var("TEST_KEY2", :discordbot, :test_key2) == :ok
    assert Application.fetch_env(:discordbot, :test_key2) == {:ok, 42}
  end

  test "doesn't set app env key if numeric env var doesn't exist" do
    assert DiscordBot.Configuration.load_int_env_var("NOT_EXIST", :discordbot, :not_exist) ==
             :error

    assert Application.fetch_env(:discordbot, :not_exist) == :error
  end

  test "doesn't set app env key if numeric env var isn't parseable" do
    System.put_env("TEST_KEY3", "TEST_VALUE")

    assert DiscordBot.Configuration.load_int_env_var("TEST_KEY3", :discordbot, :test_key3) ==
             :error

    assert Application.fetch_env(:discordbot, :test_key3) == :error
  end
end
