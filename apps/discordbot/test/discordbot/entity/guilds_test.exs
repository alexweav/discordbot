defmodule DiscordBot.Entity.GuildsTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Entity.Guilds

  use DiscordBot.Fake.Discord

  alias DiscordBot.Broker
  alias DiscordBot.Entity.GuildRecord
  alias DiscordBot.Entity.Guilds
  alias DiscordBot.Fake.Discord
  alias DiscordBot.Gateway.Connection

  setup_all do
    {url, discord} = setup_discord()
    broker = start_supervised!(Broker)
    guilds = start_supervised!({Guilds, broker: broker})

    connection = start_supervised!({Connection, token: "asdf", url: url, broker: broker})

    %{broker: broker, guilds: guilds, discord: discord, connection: connection}
  end

  test "subscribes to expected topics on launch", %{broker: broker, guilds: guilds} do
    assert Broker.subscribers?(broker, :guild_create) == [guilds]
    assert Broker.subscribers?(broker, :guild_update) == [guilds]
    assert Broker.subscribers?(broker, :guild_delete) == [guilds]
  end

  test "lookup non-existant guild ID returns error" do
    assert Guilds.from_id?("doesn't exist") == :error
  end

  test "create validates inputs", %{guilds: guilds} do
    assert Guilds.create(guilds, %DiscordBot.Model.Guild{}) == :error
    assert Guilds.create(guilds, nil) == :error
  end

  test "can create guilds in cache", %{guilds: guilds} do
    model = %DiscordBot.Model.Guild{
      id: "test-id"
    }

    assert Guilds.from_id?(model.id) == :error
    assert Guilds.create(guilds, model) == :ok
    assert Guilds.from_id?(model.id) == {:ok, GuildRecord.new(self(), model)}
  end

  test "can delete guilds in cache", %{guilds: guilds} do
    model = %DiscordBot.Model.Guild{
      id: "some-other-test-id"
    }

    Guilds.create(guilds, model)

    assert Guilds.delete(guilds, model.id) == :ok
    assert Guilds.from_id?(model.id) == :error
  end

  test "creates cached guilds on Guild Create event", %{guilds: guilds, broker: broker} do
    event = %DiscordBot.Model.Guild{
      id: "another-test-id",
      name: "My Guild"
    }

    Broker.publish(broker, :guild_create, event)

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Guilds.create(guilds, %DiscordBot.Model.Guild{})
    assert Guilds.from_id?(event.id) == {:ok, GuildRecord.new(self(), event)}
  end

  test "updates cached guilds on Guild Update event", %{guilds: guilds, broker: broker} do
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
    # This is necessary because from_id? does not communicate
    # with the registry.
    Guilds.create(guilds, %DiscordBot.Model.Guild{})
    assert Guilds.from_id?(initial.id) == {:ok, GuildRecord.new(self(), event)}
  end

  test "deletes cached guilds on Guild Delete event", %{guilds: guilds, broker: broker} do
    initial = %DiscordBot.Model.Guild{
      id: "one-more-test-id",
      name: "Some guild"
    }

    Broker.publish(broker, :guild_create, initial)

    Broker.publish(broker, :guild_delete, %DiscordBot.Model.Guild{id: initial.id})

    # Perform a synchronous call on the registry to ensure that
    # it has processed the event before we proceed.
    # This is necessary because from_id? does not communicate
    # with the registry.
    Guilds.create(guilds, %DiscordBot.Model.Guild{})
    assert Guilds.from_id?(initial.id) == :error
  end

  test "adds guilds sent through gateway", %{discord: discord, connection: connection} do
    model = %DiscordBot.Model.Guild{
      id: "test-id-integration"
    }

    assert Guilds.from_id?(model.id) == :error
    Discord.guild_create(discord, model)
    Process.sleep(100)
    assert Guilds.from_id?(model.id) == {:ok, GuildRecord.new(connection, model)}
  end
end
