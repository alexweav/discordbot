defmodule DiscordBot.Entity.ChannelsTest do
  use ExUnit.Case, async: false
  doctest DiscordBot.Entity.Channels

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Channels

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
end
