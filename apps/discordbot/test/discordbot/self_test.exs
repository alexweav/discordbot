defmodule DiscordBot.SelfTest do
  use ExUnit.Case, async: false
  doctest DiscordBot.Self

  alias DiscordBot.Broker
  alias DiscordBot.Model.{Ready, User}
  alias DiscordBot.Self

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))
    %{broker: broker, test: context.test}
  end

  test "subscribes to ready topic on launch", %{broker: broker} do
    {:ok, pid} = Self.start_link(broker: broker)
    assert Broker.subscribers?(broker, :ready) == [pid]
  end

  test "uninitialized on launch", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    assert Self.status?() == :uninitialized
  end

  test "initialized after ready", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    Broker.publish(broker, :ready, test_ready())
    assert Self.status?() == :initialized
  end

  test "retrieves full user struct", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    Broker.publish(broker, :ready, test_ready())
    assert Self.user?() == test_ready().user
  end

  test "retrieves bot username", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    Broker.publish(broker, :ready, test_ready())
    assert Self.username?() == "a-bot"
  end

  test "retrieves bot discriminator", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    Broker.publish(broker, :ready, test_ready())
    assert Self.discriminator?() == "1234"
  end

  test "retrieves bot ID", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)
    Broker.publish(broker, :ready, test_ready())
    assert Self.id?() == "123456789"
  end

  test "can set user for use in testing", %{broker: broker} do
    Self.start_link(broker: broker, name: DiscordBot.Self)

    user = %User{
      id: "test-user"
    }

    Self.set_user(user)

    assert Self.id?() == "test-user"
  end

  defp test_ready do
    %Ready{
      v: 6,
      user: %User{
        id: "123456789",
        username: "a-bot",
        discriminator: "1234",
        bot: true
      },
      private_channels: [],
      guilds: [],
      session_id: "asdf",
      _trace: "test guild"
    }
  end
end
