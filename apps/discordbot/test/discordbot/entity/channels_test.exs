defmodule DiscordBot.Entity.ChannelsTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Channels

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Channels
  alias DiscordBot.Model.{Channel, Guild}

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
      name: "My Channel"
    }

    Broker.publish(broker, :channel_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because lfrom_id? does not communicate
    # with the registry.
    Channels.create(channels, nil)

    assert Channels.from_id?(event.id) == {:ok, event}
  end

  test "updates cached channels on Channel Update event", %{channels: channels, broker: broker} do
    initial = %Channel{
      id: "yet-another-test-id",
      name: "An existing channel"
    }

    Broker.publish(broker, :channel_create, initial)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Channels.create(channels, nil)

    assert elem(Channels.from_id?(initial.id), 1).name == "An existing channel"

    event = %Channel{
      id: initial.id,
      name: "A different name"
    }

    Broker.publish(broker, :channel_update, event)

    # Same
    Channels.create(channels, nil)

    assert elem(Channels.from_id?(initial.id), 1).name == "A different name"
  end

  test "deletes cached channels on Channel Delete event", %{channels: channels, broker: broker} do
    initial = %Channel{
      id: "one-more-test-id",
      name: "Some channel"
    }

    Broker.publish(broker, :channel_create, initial)
    Broker.publish(broker, :channel_delete, %Channel{id: initial.id})

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Channels.create(channels, nil)

    assert Channels.from_id?(initial.id) == :error
  end

  test "creates channels from Guild Create events", %{channels: channels, broker: broker} do
    channel = %Channel{
      id: "channel-asdf",
      name: "Test Channel",
      topic: "A test channel",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    event = %Guild{
      id: "asdf",
      name: "My guild",
      channels: [channel]
    }

    Broker.publish(broker, :guild_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Channels.create(channels, nil)

    assert {:ok, _} = Channels.from_id?(channel.id)
    assert elem(Channels.from_id?(channel.id), 1).id == "channel-asdf"
  end

  test "channels created from guilds inherit guild ID", %{channels: channels, broker: broker} do
    channel = %Channel{
      id: "channel-abcd",
      name: "Test Channel",
      topic: "A test channel",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    event = %Guild{
      id: "abcd",
      name: "My guild",
      channels: [channel]
    }

    Broker.publish(broker, :guild_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Channels.create(channels, nil)

    {:ok, created} = Channels.from_id?(channel.id)
    assert created.guild_id == "abcd"
  end

  test "finds text channels for a guild", %{channels: channels} do
    text_channel = %Channel{
      id: "text-1",
      type: :guild_text,
      guild_id: "text-search-guild"
    }

    wrong_guild = %Channel{
      id: "text-2",
      type: :guild_text,
      guild_id: "not-text-search-guild"
    }

    not_text = %Channel{
      id: "text-3",
      type: :guild_voice,
      guild_id: "text-search-guild"
    }

    Channels.create(channels, text_channel)
    Channels.create(channels, wrong_guild)
    Channels.create(channels, not_text)

    assert Channels.text_channels?("text-search-guild") == [text_channel]

    guild = %Guild{
      id: "text-search-guild"
    }

    assert Channels.text_channels?(guild) == [text_channel]
  end

  test "finds voice channels for a guild", %{channels: channels} do
    voice_channel = %Channel{
      id: "voice-1",
      type: :guild_voice,
      guild_id: "voice-search-guild"
    }

    wrong_guild = %Channel{
      id: "voice-2",
      type: :guild_voice,
      guild_id: "not-voice-search-guild"
    }

    not_voice = %Channel{
      id: "voice-3",
      type: :guild_text,
      guild_id: "voice-search-guild"
    }

    Channels.create(channels, voice_channel)
    Channels.create(channels, wrong_guild)
    Channels.create(channels, not_voice)

    assert Channels.voice_channels?("voice-search-guild") == [voice_channel]

    guild = %Guild{
      id: "voice-search-guild"
    }

    assert Channels.voice_channels?(guild) == [voice_channel]
  end
end
