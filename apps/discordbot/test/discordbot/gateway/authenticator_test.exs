defmodule DiscordBot.Gateway.AuthenticatorTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Gateway.Authenticator

  setup context do
    broker = start_supervised!({Broker, []})
    %{broker: broker, context: context}
  end

  test "subscribes to :hello events on launch", %{broker: broker, context: context} do
    auth =
      start_supervised!(
        {Task, fn -> Authenticator.authenticate(broker, "test") end},
        id: context.test
      )

    Process.sleep(10)

    assert broker
           |> Broker.subscribers?(:hello)
           |> Enum.member?(auth)
  end

  test "publishing :hello event triggers authentication", %{broker: broker, context: context} do
    start_supervised!(
      {Task, fn -> Authenticator.authenticate(broker, "test") end},
      id: context.test
    )

    Process.sleep(10)
    Broker.publish(broker, :hello, {})
    assert_receive({:"$gen_cast", {:identify, data}}, 1_000)
    assert data.data.token == "test"
    assert data.data.shard == [0, 1]
  end

  test ":hello with custom sharding authenticates", %{broker: broker, context: context} do
    start_supervised!(
      {Task, fn -> Authenticator.authenticate(broker, "asdf", 31, 128) end},
      id: context.test
    )

    Process.sleep(10)
    Broker.publish(broker, :hello, {})
    assert_receive({:"$gen_cast", {:identify, data}}, 1_000)
    assert data.data.token == "asdf"
    assert data.data.shard == [31, 128]
  end
end
