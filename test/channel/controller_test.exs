defmodule DiscordBot.Channel.ControllerTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Channel.Controller

  alias DiscordBot.Channel.Controller
  alias DiscordBot.Channel.Channel

  setup do
    _ = start_supervised!(DiscordBot.Channel.Supervisor)
    :ok
  end

  test "starts channels" do
    assert Controller.lookup_by_id(DiscordBot.ChannelController, "test-id") == :error

    model = %DiscordBot.Model.Channel{
      id: "test-id"
    }

    assert {:ok, channel} = Controller.create(DiscordBot.ChannelController, model)
    assert Channel.id?(channel) == "test-id"
    assert Controller.lookup_by_id(DiscordBot.ChannelController, "test-id") == {:ok, channel}
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

    assert {:ok, channel1} = Controller.create(DiscordBot.ChannelController, model1)
    assert {:ok, channel2} = Controller.create(DiscordBot.ChannelController, model2)
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

    assert {:ok, channel_previous} = Controller.create(DiscordBot.ChannelController, model)

    other_model = %DiscordBot.Model.Channel{
      id: "channel-1",
      name: "Other Channel",
      topic: "Other Stuff"
    }

    assert {:ok, channel_after} = Controller.create(DiscordBot.ChannelController, other_model)
    assert channel_previous == channel_after
  end
end
