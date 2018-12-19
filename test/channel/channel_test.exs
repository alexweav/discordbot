defmodule DiscordBot.Model.ChannelTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.Channel

  setup do
    model = %DiscordBot.Model.Channel{}
    channel = start_supervised!({DiscordBot.Channel.Channel, [channel: model]})
    %{model: model, channel: channel}
  end

  test "returns stored model", %{model: model, channel: channel} do
    assert DiscordBot.Channel.Channel.model?(channel) == model
  end
end
