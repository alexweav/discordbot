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
    assert_receive({:"$websockex_cast", {:identify, "test", 0, 1}}, 1_000)
  end

  test ":hello with custom sharding authenticates", %{broker: broker, context: context} do
    start_supervised!(
      {Task, fn -> Authenticator.authenticate(broker, "asdf", 31, 128) end},
      id: context.test
    )

    Process.sleep(10)
    Broker.publish(broker, :hello, {})
    assert_receive({:"$websockex_cast", {:identify, "asdf", 31, 128}}, 1_000)
  end
end
