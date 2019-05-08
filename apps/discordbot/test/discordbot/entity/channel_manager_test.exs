defmodule DiscordBot.Entity.ChannelManagerTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.ChannelManager

  import Mox

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Channel
  alias DiscordBot.Entity.ChannelManager

  setup do
    broker = start_supervised!(Broker)

    _ =
      start_supervised!({DiscordBot.Entity.Supervisor, [broker: broker, api: DiscordBot.ApiMock]})

    %{broker: broker}
  end

  test "starts channels" do
    assert ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "test-id") == :error

    model = %DiscordBot.Model.Channel{
      id: "test-id"
    }

    assert {:ok, channel} = ChannelManager.create(DiscordBot.ChannelManager, model)
    assert Channel.id?(channel) == "test-id"
    assert ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "test-id") == {:ok, channel}
  end

  test "starts multiple channels with different IDs" do
    model1 = %DiscordBot.Model.Channel{
      id: "test-id1",
      name: "name1"
    }

    model2 = %DiscordBot.Model.Channel{
      id: "test-id2",
      name: "name2"
    }

    assert {:ok, channel1} = ChannelManager.create(DiscordBot.ChannelManager, model1)
    assert {:ok, channel2} = ChannelManager.create(DiscordBot.ChannelManager, model2)
    assert channel1 != channel2
    assert Channel.name?(channel1) == "name1"
    assert Channel.name?(channel2) == "name2"
  end

  test "create updates existing channel if already started" do
    model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "Test Channel",
      topic: "Test Stuff"
    }

    assert {:ok, channel_previous} = ChannelManager.create(DiscordBot.ChannelManager, model)

    other_model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "Other Channel",
      topic: "Other Stuff"
    }

    assert {:ok, channel_after} = ChannelManager.create(DiscordBot.ChannelManager, other_model)
    assert channel_previous == channel_after
  end

  test "handles updates" do
    model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "My Channel",
      topic: "Channel stuff"
    }

    assert {:ok, channel} = ChannelManager.create(DiscordBot.ChannelManager, model)

    update = %DiscordBot.Model.Channel{
      name: "Another name"
    }

    assert ChannelManager.update(DiscordBot.ChannelManager, "channel-1", update) == :ok
    assert Channel.name?(channel) == "Another name"
    assert Channel.model?(channel).topic == "Channel stuff"
  end

  test "closes channels" do
    assert ChannelManager.close(DiscordBot.ChannelManager, "channel-1") == :error

    model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "My Channel",
      topic: "Channel stuff"
    }

    {:ok, pid} = ChannelManager.create(DiscordBot.ChannelManager, model)
    assert ChannelManager.close(DiscordBot.ChannelManager, "channel-1") == :ok
    assert Process.alive?(pid) == false
  end

  test "creates channels from :channel_create events", %{broker: broker} do
    event = %DiscordBot.Model.Channel{
      id: "channel-asdf",
      name: "Test Channel",
      topic: "A test channel",
      guild_id: "123-456",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    Broker.publish(broker, :channel_create, event)
    assert {:ok, pid} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "channel-asdf")
    assert Channel.model?(pid) == event
  end

  test "updates channels from :channel_update events", %{broker: broker} do
    model1 = %DiscordBot.Model.Channel{
      id: "channel-asdf",
      name: "Test Channel",
      topic: "A test channel",
      guild_id: "123-456",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    model2 = %DiscordBot.Model.Channel{
      id: "another-channel",
      name: "Another Channel"
    }

    {:ok, pid1} = ChannelManager.create(DiscordBot.ChannelManager, model1)
    {:ok, pid2} = ChannelManager.create(DiscordBot.ChannelManager, model2)

    event = %DiscordBot.Model.Channel{
      id: "channel-asdf",
      name: "A new name"
    }

    Broker.publish(broker, :channel_update, event)

    # Do a lookup to synchronously ensure the manager has processed the event
    _ = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "channel-asdf")

    assert Channel.model?(pid1) == %DiscordBot.Model.Channel{model1 | name: "A new name"}
    assert Channel.model?(pid2) == model2
  end

  test "deletes channels from :channel_delete events", %{broker: broker} do
    model = %DiscordBot.Model.Channel{
      id: "test-channel",
      name: "Test Channel"
    }

    {:ok, pid} = ChannelManager.create(DiscordBot.ChannelManager, model)

    event = %DiscordBot.Model.Channel{
      id: "test-channel"
    }

    Broker.publish(broker, :channel_delete, event)

    # Do a lookup to synchronously ensure the manager has processed the event
    # We're not looking up the deleted channel, because Elixir's default Registry
    # may have a delayed response when processes close
    _ = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "channel-asdf")

    assert Process.alive?(pid) == false
  end

  test "creates channels embedded in :guild_create events", %{broker: broker} do
    channel = %DiscordBot.Model.Channel{
      id: "channel-asdf",
      name: "Test Channel",
      topic: "A test channel",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    event = %DiscordBot.Model.Guild{
      id: "asdf",
      name: "My guild",
      channels: [channel]
    }

    Broker.publish(broker, :guild_create, event)

    assert {:ok, pid} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "channel-asdf")
    assert Channel.id?(pid) == channel.id
  end

  test "channels provided via :guild_create have guild_id", %{broker: broker} do
    channel = %DiscordBot.Model.Channel{
      id: "channel-asdf",
      name: "Test Channel",
      topic: "A test channel",
      owner_id: "789-012",
      last_message_id: "345-678"
    }

    event = %DiscordBot.Model.Guild{
      id: "asdf",
      name: "My guild",
      channels: [channel]
    }

    Broker.publish(broker, :guild_create, event)

    {:ok, pid} = ChannelManager.lookup_by_id(DiscordBot.ChannelManager, "channel-asdf")
    assert Channel.guild_id?(pid) == event.id
  end

  test "replies to messages on a known channel" do
    model = %DiscordBot.Model.Channel{
      id: "channel-asdf"
    }

    {:ok, pid} = ChannelManager.create(DiscordBot.ChannelManager, model)

    message = %DiscordBot.Model.Message{
      channel_id: "channel-asdf"
    }

    DiscordBot.ApiMock
    |> expect(:create_message, fn _content, _id -> {:ok, %HTTPoison.Response{}} end)
    |> allow(self(), pid)

    ChannelManager.reply(message, "response")
    verify!()
  end

  test "replies to messages with TTS on a known channel" do
    model = %DiscordBot.Model.Channel{
      id: "channel-asdf"
    }

    {:ok, pid} = ChannelManager.create(DiscordBot.ChannelManager, model)

    message = %DiscordBot.Model.Message{
      channel_id: "channel-asdf"
    }

    DiscordBot.ApiMock
    |> expect(:create_tts_message, fn _content, _id -> {:ok, %HTTPoison.Response{}} end)
    |> allow(self(), pid)

    ChannelManager.reply(message, "response", tts: true)
    verify!()
  end
end
