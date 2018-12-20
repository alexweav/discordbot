defmodule DiscordBot.Channel.RegistryTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Channel.Registry

  setup do
    _ = start_supervised!(DiscordBot.Channel.Supervisor)
    :ok
  end

  test "starts channels" do
    assert DiscordBot.Channel.Registry.lookup_by_id(DiscordBot.ChannelRegistry, "test-id") ==
             :error

    model = %DiscordBot.Model.Channel{
      id: "test-id"
    }

    assert {:ok, channel} = DiscordBot.Channel.Registry.create(DiscordBot.ChannelRegistry, model)
    assert DiscordBot.Channel.Channel.id?(channel) == "test-id"
  end
end
