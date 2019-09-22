defmodule DiscordBot.Entity.ChannelsTest do
  use ExUnit.Case, async: false
  doctest DiscordBot.Entity.Channels

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Channels
  alias DiscordBot.Model.Channel

  setup_all do
    broker = start_supervised!(Broker)
    channels = start_supervised!({Channels, broker: broker})
    %{broker: broker, channels: channels}
  end

  test "subscribes to expected topics on launch", %{broker: broker, channels: channels} do
    assert Broker.subscribers?(broker, :channel_create) == [channels]
    assert Broker.subscribers?(broker, :channel_update) == [channels]
    assert Broker.subscribers?(broker, :channel_delete) == [channels]
    assert Broker.subscribers?(broker, :guild_create) == [channels]
  end

  test "lookup non-existant channel ID returns error" do
    assert Channels.from_id?("doesn't exist") == :error
  end

  test "create validates inputs", %{channels: channels} do
    assert Channels.create(channels, %Channel{}) == :error
    assert Channels.create(channels, nil) == :error
  end

  test "can create channels in cache", %{channels: channels} do
    model = %Channel{
      id: "test-id"
    }

    assert Channels.from_id?(model.id) == :error
    assert Channels.create(channels, model) == :ok
    assert Channels.from_id?(model.id) == {:ok, model}
  end
end
