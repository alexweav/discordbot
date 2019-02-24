defmodule DiscordBot.Entity.GuildTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Guild

  alias DiscordBot.Broker
  alias DiscordBot.Entity.Guild

  setup do
    broker = start_supervised!(Broker)

    guild = start_supervised!({Guild, [broker: broker, api: DiscordBot.ApiMock]})

    %{broker: broker, guild: guild}
  end

  test "lookup non-existant guild ID returns error" do
    assert Guild.lookup_by_id("doesn't exist") == :error
  end

  test "create validates inputs", %{guild: guild} do
    assert Guild.create(guild, %DiscordBot.Model.Guild{}) == :error
    assert Guild.create(guild, nil) == :error
  end

  test "can create guilds in cache", %{guild: guild} do
    model = %DiscordBot.Model.Guild{
      id: "test-id"
    }

    assert Guild.lookup_by_id(model.id) == :error
    assert Guild.create(guild, model) == :ok
    assert Guild.lookup_by_id(model.id) == {:ok, model}
  end

  test "creates cached guilds on Guild Create event", %{guild: guild, broker: broker} do
    event = %DiscordBot.Model.Guild{
      id: "another-test-id",
      name: "My Guild"
    }

    Broker.publish(broker, :guild_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because lookup_by_id does not communicate
    # with the registry.
    Guild.create(guild, %DiscordBot.Model.Guild{})
    assert Guild.lookup_by_id(event.id) == {:ok, event}
  end
end
