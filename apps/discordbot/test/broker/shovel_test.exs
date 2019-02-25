defmodule DiscordBot.Broker.ShovelTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Broker.Shovel

  alias DiscordBot.Broker.Shovel

  test "start_link validates inputs" do
    assert_raise ArgumentError, fn ->
      Shovel.start_link(nil) == :ok
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(destination: self(), topics: [])
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(source: self(), topics: [])
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(source: self(), destination: self())
    end
  end
end
