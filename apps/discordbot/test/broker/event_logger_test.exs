defmodule DiscordBot.Broker.EventLoggerTest do
  use ExUnit.Case, async: true

  alias DiscordBot.Broker
  alias DiscordBot.Broker.EventLogger

  setup do
    broker = start_supervised!({Broker, []})
    logger = start_supervised!({EventLogger, [broker: broker]})
    %{broker: broker, logger: logger}
  end

  test "sets name on launch", %{broker: broker} do
    logger =
      start_supervised!({EventLogger, [broker: broker, logger_name: "test_name"]}, id: Test)

    assert EventLogger.logger_name?(logger) == "test_name"
  end

  test "name falls back to pid", %{logger: logger} do
    assert EventLogger.logger_name?(logger) == Kernel.inspect(logger)
  end

  test "subscribes to initial topics", %{broker: broker} do
    logger = start_supervised!({EventLogger, [broker: broker, topics: [:test, :topic]]}, id: Test)
    assert EventLogger.topics?(logger) == [:test, :topic]
    assert Enum.member?(Broker.subscribers?(broker, :test), logger)
    assert Enum.member?(Broker.subscribers?(broker, :topic), logger)
  end

  test "adds new topic subscriptions", %{broker: broker} do
    logger = start_supervised!({EventLogger, [broker: broker, topics: [:test]]}, id: Test)
    assert :ok = EventLogger.begin_logging(logger, :newtopic)
    assert Enum.member?(EventLogger.topics?(logger), :newtopic)
    assert Enum.member?(Broker.subscribers?(broker, :newtopic), logger)
  end
end
