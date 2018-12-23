defmodule DiscordBot.Channel.RegistryTest do
  use ExUnit.Case
  doctest DiscordBot.Channel.Registry

  alias DiscordBot.Channel.Registry
  alias DiscordBot.Channel.Channel

  setup_all do
    # _ = start_supervised!({Registry, keys: :unique, name: DiscordBot.ChannelRegistry})
    # _ = start_supervised!(DiscordBot.Channel.Supervisor)
    :ok
  end

  setup do
    _ = start_supervised!(DiscordBot.Channel.Supervisor)
    :ok
  end

  test "starts channels" do
    assert Registry.lookup_by_id(DiscordBot.ChannelController, "test-id") == :error

    model = %DiscordBot.Model.Channel{
      id: "test-id"
    }

    assert {:ok, channel} = Registry.create(DiscordBot.ChannelController, model)
    assert Channel.id?(channel) == "test-id"
    assert Registry.lookup_by_id(DiscordBot.ChannelController, "test-id") == {:ok, channel}
  end

  """
  test "create updates existing channel if already started" do
    model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "Test Channel",
      topic: "Test Stuff"
    }

    assert {:ok, channel_previous} = Registry.create(DiscordBot.ChannelController, model)

    other_model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "Other Channel",
      topic: "Other Stuff"
    }

    assert {:ok, channel_after} = Registry.create(DiscordBot.ChannelController, other_model)
    assert channel_previous == channel_after
  end
  """
end
