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
end
