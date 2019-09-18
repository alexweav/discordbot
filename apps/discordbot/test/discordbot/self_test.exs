defmodule DiscordBot.SelfTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Self

  alias DiscordBot.Broker
  alias DiscordBot.Self

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))
    %{broker: broker, test: context.test}
  end

  test "subscribes to ready topic on launch", %{broker: broker} do
    {:ok, pid} = Self.start_link(broker: broker)
    assert Broker.subscribers?(broker, :ready) == [pid]
  end
end
