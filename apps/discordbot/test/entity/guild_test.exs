defmodule DiscordBot.Entity.GuildTest do
  use ExUnit.Case, async: false
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

  test "can delete guilds in cache", %{guild: guild} do
    model = %DiscordBot.Model.Guild{
      id: "some-other-test-id"
    }

    Guild.create(guild, model)

    assert Guild.delete(guild, model.id) == :ok
    assert Guild.lookup_by_id(model.id) == :error
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

  test "updates cached guilds on Guild Update event", %{guild: guild, broker: broker} do
    initial = %DiscordBot.Model.Guild{
      id: "yet-another-test-id",
      name: "An existing guild"
    }

    Broker.publish(broker, :guild_create, initial)

    event = %DiscordBot.Model.Guild{
      id: initial.id,
      name: "A different name"
    }

    Broker.publish(broker, :guild_update, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because lookup_by_id does not communicate
    # with the registry.
    Guild.create(guild, %DiscordBot.Model.Guild{})
    assert Guild.lookup_by_id(initial.id) == {:ok, event}
  end

  test "deletes cached guilds on Guild Delete event", %{guild: guild, broker: broker} do
    initial = %DiscordBot.Model.Guild{
      id: "one-more-test-id",
      name: "Some guild"
    }

    Broker.publish(broker, :guild_create, initial)

    Broker.publish(broker, :guild_delete, %DiscordBot.Model.Guild{id: initial.id})

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because lookup_by_id does not communicate
    # with the registry.
    Guild.create(guild, %DiscordBot.Model.Guild{})
    assert Guild.lookup_by_id(initial.id) == :error
  end
end
