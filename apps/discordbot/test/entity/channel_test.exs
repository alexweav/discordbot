defmodule DiscordBot.Entity.ChannelTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Channel

  import Mox

  alias DiscordBot.Entity.Channel
  alias DiscordBot.Model.Channel, as: ChannelModel

  setup do
    model = %ChannelModel{
      id: "test-id"
    }

    channel = start_supervised!({Channel, [channel: model, api: DiscordBot.ApiMock]})
    %{model: model, channel: channel}
  end

  test "returns stored model", %{model: model, channel: channel} do
    assert Channel.model?(channel) == model
  end

  test "creating with nil ID throws" do
    model = %ChannelModel{
      id: nil
    }

    assert_raise ArgumentError, fn ->
      Channel.start_link(channel: model)
    end
  end

  test "updates internal model", %{channel: channel} do
    model = %ChannelModel{
      id: "test-id",
      name: "test-name"
    }

    assert Channel.update(channel, model) == :ok
    assert Channel.model?(channel) == model
  end

  test "knows name", %{channel: channel} do
    assert Channel.name?(channel) == nil

    model = %ChannelModel{
      id: "test-id",
      name: "my-name"
    }

    assert Channel.update(channel, model) == :ok
    assert Channel.name?(channel) == "my-name"
  end

  test "knows ID", %{channel: channel} do
    assert Channel.id?(channel) == "test-id"
  end

  test "knows guild ID", %{channel: channel} do
    assert Channel.guild_id?(channel) == nil

    model = %ChannelModel{
      id: "test-id",
      guild_id: "test-guild-id"
    }

    assert Channel.update(channel, model) == :ok
    assert Channel.guild_id?(channel) == "test-guild-id"
  end

  test "wrong ID update returns error", %{channel: channel} do
    model = %ChannelModel{
      id: "another-id"
    }

    assert Channel.update(channel, model) == {:error, :incorrect_id}
  end

  test "nil ID update always works", %{channel: channel} do
    model = %ChannelModel{
      name: "changed name"
    }

    assert Channel.update(channel, model) == :ok
  end

  test "update ignores nil values", %{channel: channel} do
    model = %ChannelModel{
      name: "a name",
      topic: "a topic"
    }

    Channel.update(channel, model)

    other_model = %ChannelModel{
      topic: "a different topic"
    }

    Channel.update(channel, other_model)

    assert Channel.model?(channel).name == "a name"
    assert Channel.model?(channel).topic == "a different topic"
  end

  test "sends messages", %{channel: channel} do
    DiscordBot.ApiMock
    |> expect(:create_message, fn _content, _id -> {:ok, %HTTPoison.Response{}} end)
    |> allow(self(), channel)

    model = %ChannelModel{
      id: "channel-id",
      name: "test-name"
    }

    Channel.update(channel, model)

    assert {:ok, _} = Channel.create_message(channel, "Test Message")
  end

  test "sends messages with TTS", %{channel: channel} do
    DiscordBot.ApiMock
    |> expect(:create_tts_message, fn _content, _id -> {:ok, %HTTPoison.Response{}} end)
    |> allow(self(), channel)

    model = %ChannelModel{
      id: "channel-id",
      name: "test-name"
    }

    Channel.update(channel, model)

    assert {:ok, _} = Channel.create_message(channel, "Test Message", tts: true)
  end
end
