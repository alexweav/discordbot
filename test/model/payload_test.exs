defmodule DiscordBot.Model.PayloadTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.Payload

  alias DiscordBot.Model.Payload

  test "builds from atom opcode" do
    payload = Payload.payload(11)
    assert payload.opcode == :heartbeat_ack
    assert payload.data == Nil
    assert payload.sequence == Nil
    assert payload.name == Nil
  end

  test "builds from numeric opcode" do
    payload = Payload.payload(:heartbeat_ack)
    assert payload.opcode == :heartbeat_ack
    assert payload.data == Nil
    assert payload.sequence == Nil
    assert payload.name == Nil
  end

  test "builds from opcode and data" do
    payload = Payload.payload(:identify, %{"test" => "map"})
    assert payload.opcode == :identify
    assert payload.data == %{"test" => "map"}
    assert payload.sequence == Nil
    assert payload.name == Nil
  end

  test "builds from all properties" do
    payload = Payload.payload(:dispatch, %{"test" => "map"}, 14, "TEST_EVENT")
    assert payload.opcode == :dispatch
    assert payload.data == %{"test" => "map"}
    assert payload.sequence == 14
    assert payload.name == "TEST_EVENT"
  end

  test "serializes correctly" do
    {:ok, serialized} =
      Payload.payload(:status_update, "test", 10, "TEST")
      |> Payload.to_json()

    assert serialized == "{\"t\":\"TEST\",\"s\":10,\"op\":3,\"d\":\"test\"}"
  end

  test "deserializes correctly" do
    json = "{\"t\":\"TEST\",\"s\":10,\"op\":3,\"d\":\"test\"}"
    payload = Payload.from_json(json)
    assert payload.opcode == :status_update
    assert payload.data == "test"
    assert payload.sequence == 10
    assert payload.name == "TEST"
  end
end
