defmodule DiscordBot.Model.ChannelTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.Channel

  alias DiscordBot.Channel.Channel

  setup do
    model = %DiscordBot.Model.Channel{
      id: "test-id"
    }

    channel = start_supervised!({Channel, [channel: model]})
    %{model: model, channel: channel}
  end

  test "returns stored model", %{model: model, channel: channel} do
    assert Channel.model?(channel) == model
  end

  test "creating with nil ID throws" do
    model = %DiscordBot.Model.Channel{
      id: nil
    }

    assert_raise ArgumentError, fn ->
      Channel.start_link(channel: model)
    end
  end

  test "updates internal model", %{channel: channel} do
    model = %DiscordBot.Model.Channel{
      id: "test-id",
      name: "test-name"
    }

    assert Channel.update(channel, model) == :ok
    assert Channel.model?(channel) == model
  end

  test "knows name", %{channel: channel} do
    assert Channel.name?(channel) == nil

    model = %DiscordBot.Model.Channel{
      id: "test-id",
      name: "my-name"
    }

    assert Channel.update(channel, model) == :ok
    assert Channel.name?(channel) == "my-name"
  end

  test "wrong ID update returns error", %{channel: channel} do
    model = %DiscordBot.Model.Channel{
      id: "another-id"
    }

    assert Channel.update(channel, model) == {:error, :incorrect_id}
  end

  test "nil ID update always works", %{channel: channel} do
    model = %DiscordBot.Model.Channel{
      name: "changed name"
    }

    assert Channel.update(channel, model) == :ok
  end

  test "update ignores nil values", %{channel: channel} do
    model = %DiscordBot.Model.Channel{
      name: "a name",
      topic: "a topic"
    }

    Channel.update(channel, model)

    other_model = %DiscordBot.Model.Channel{
      topic: "a different topic"
    }

    Channel.update(channel, other_model)

    assert Channel.model?(channel).name == "a name"
    assert Channel.model?(channel).topic == "a different topic"
  end
end
