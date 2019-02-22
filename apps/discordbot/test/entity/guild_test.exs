defmodule DiscordBot.Entity.GuildTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Guild

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Guild

  setup do
    broker = start_supervised!(Broker)

    guild =
      start_supervised!({Guild, [broker: broker, api: DiscordBot.ApiMock]})

    %{broker: broker, guild: guild}
  end

  test "lookup non-existant guild ID returns error" do
    assert Guild.lookup_by_id("doesn't exist") == :error
  end
end
