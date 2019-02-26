defmodule DiscordBot.Broker.ShovelTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Broker.Shovel

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Shovel

  setup context do
    source = start_supervised!({Broker, []}, id: (Atom.to_string(context.test) <> "-source") |> String.to_atom())
    destination = start_supervised!({Broker, []}, id: (Atom.to_string(context.test) <> "-dest") |> String.to_atom())
    %{source: source, destination: destination}
  end

  test "start_link validates inputs", %{source: source, destination: destination} do
    assert_raise ArgumentError, fn ->
      Shovel.start_link(nil) == :ok
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(destination: destination, topics: [])
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(source: source, topics: [])
    end

    assert_raise ArgumentError, fn ->
      Shovel.start_link(source: source, destination: destination)
    end
  end

  test "subscribes to input topics", %{source: source, destination: destination} do
    shovel = start_supervised!({Shovel, source: source, destination: destination, topics: [:test, :topic]})

    assert Enum.member?(Broker.subscribers?(source, :test), shovel)
    assert Enum.member?(Broker.subscribers?(source, :topic), shovel)
  end

  test "subscribes to newly added topics", %{source: source, destination: destination} do
    shovel = start_supervised!({Shovel, source: source, destination: destination, topics: []})

    assert Enum.member?(Broker.subscribers?(source, :topic), shovel) == false

    Shovel.add_topic(shovel, :topic)

    assert Enum.member?(Broker.subscribers?(source, :topic), shovel) == true
  end
end
