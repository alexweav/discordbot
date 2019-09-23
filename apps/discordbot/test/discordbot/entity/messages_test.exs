defmodule DiscordBot.Entity.MessagesTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Messages

  import Mox

  alias DiscordBot.Entity.Messages
  alias DiscordBot.Model.{Channel, Message}

  test "sends message to a channel" do
    channel = %Channel{
      id: "test-id"
    }

    DiscordBot.ApiMock
    |> expect(:create_message, fn _c, _i -> {:ok, %HTTPoison.Response{}} end)

    Messages.create(channel, "test")
    verify!()
  end

  test "sends TTS message to a channel" do
    channel = %Channel{
      id: "test-id"
    }

    DiscordBot.ApiMock
    |> expect(:create_tts_message, fn _c, _i -> {:ok, %HTTPoison.Response{}} end)

    Messages.create(channel, "test", tts: true)
    verify!()
  end

  test "replies to a message" do
    message = %Message{
      channel_id: "test-id"
    }

    DiscordBot.ApiMock
    |> expect(:create_message, fn _c, _i -> {:ok, %HTTPoison.Response{}} end)

    Messages.reply(message, "test")
    verify!()
  end

  test "replies using TTS" do
    message = %Message{
      channel_id: "test-id"
    }

    DiscordBot.ApiMock
    |> expect(:create_tts_message, fn _c, _i -> {:ok, %HTTPoison.Response{}} end)

    Messages.reply(message, "test", tts: true)
    verify!()
  end
end
