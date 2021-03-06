defmodule DiscordBot.HandlerTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handler

  alias DiscordBot.Broker
  alias DiscordBot.Handler

  defmodule TestHandler do
    use Handler

    def handler_init(:ok) do
      {:ok, :ok}
    end

    def handle_event(_event, _state) do
      :ok
    end
  end

  setup context do
    broker = start_supervised!({Broker, []}, id: Module.concat(context.test, :broker))
    %{broker: broker, test: context.test}
  end

  describe "start_link" do
    test "launches with one topic", %{broker: broker} do
      assert {:ok, pid} = Handler.start_link(TestHandler, :topic, :ok, broker: broker)
    end

    test "launches with multiple topics", %{broker: broker} do
      assert {:ok, pid} = Handler.start_link(TestHandler, [:test, :topic], :ok, broker: broker)
    end

    test "subscribes to given topics", %{broker: broker} do
      {:ok, pid} = Handler.start_link(TestHandler, [:test, :topic], :ok, broker: broker)
      assert Enum.member?(Broker.subscribers?(broker, :test), pid)
      assert Enum.member?(Broker.subscribers?(broker, :topic), pid)
    end

    test "defaults to named broker" do
      Handler.start_link(TestHandler, :test, :ok)
    end
  end

  describe "start" do
    test "launches with one topic", %{broker: broker} do
      assert {:ok, pid} = Handler.start(TestHandler, :topic, :ok, broker: broker)
    end

    test "launches with multiple topics", %{broker: broker} do
      assert {:ok, pid} = Handler.start(TestHandler, [:test, :topic], :ok, broker: broker)
    end

    test "subscribes to given topics", %{broker: broker} do
      {:ok, pid} = Handler.start(TestHandler, [:test, :topic], :ok, broker: broker)
      assert Enum.member?(Broker.subscribers?(broker, :test), pid)
      assert Enum.member?(Broker.subscribers?(broker, :topic), pid)
    end

    test "defaults to named broker" do
      Handler.start(TestHandler, :test, :ok)
    end
  end
end
