defmodule DiscordBot.Gateway.BrokerTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Gateway.Broker
  alias DiscordBot.Gateway.Broker.Event

  setup do
    broker = start_supervised!({Broker, []})
    %{broker: broker}
  end

  test "no known topics on launch", %{broker: broker} do
    assert Broker.topics?(broker) == []
  end

  test "subscribing returns :ok", %{broker: broker} do
    assert Broker.subscribe(broker, :my_topic) == :ok
  end

  test "subscribing creates topic", %{broker: broker} do
    Broker.subscribe(broker, :my_topic)
    assert Broker.topics?(broker) == [:my_topic]
  end

  test "subscribing adds self as subscriber", %{broker: broker} do
    assert Broker.subscribers?(broker, :my_topic) == []
    Broker.subscribe(broker, :my_topic)
    assert Broker.subscribers?(broker, :my_topic) == [self()]
  end

  test "publishing sends message to subscriber", %{broker: broker} do
    Broker.subscribe(broker, :my_topic)
    Broker.publish(broker, :my_topic, "test message")

    message =
      receive do
        %Event{source: :broker, broker: _broker, message: msg} -> msg
      after
        1_000 -> "timeout"
      end

    assert message == "test message"
  end

  test "message has correct publisher PID", %{broker: broker} do
    Broker.subscribe(broker, :my_topic)
    Broker.publish(broker, :my_topic, "test message")

    pid =
      receive do
        %Event{source: :broker, broker: _broker, publisher: pub} -> pub
      after
        1_000 -> "timeout"
      end

    assert pid == self()
  end
end
