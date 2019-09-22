defmodule DiscordBot.Entity.ChannelsTest do
  use ExUnit.Case, async: true
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

  test "can delete channels in cache", %{channels: channels} do
    model = %Channel{
      id: "some-other-test-id"
    }

    Channels.create(channels, model)

    assert Channels.delete(channels, model.id) == :ok
    assert Channels.from_id?(model.id) == :error
  end

  test "creates channels on Channel Create event", %{channels: channels, broker: broker} do
    event = %Channel{
      id: "another-test-id",
      name: "My Guild"
    }

    Broker.publish(broker, :channel_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because lookup_by_id does not communicate
    # with the registry.
    Channels.create(channels, nil)

    assert Channels.from_id?(event.id) == {:ok, event}
  end
end
