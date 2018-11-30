defmodule DiscordBot.Model.IdentifyTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.Identify

  alias DiscordBot.Model.Identify
  alias DiscordBot.Model.Payload

  setup do
    object = Identify.identify("TOKEN", 1, 3)
    %{object: object}
  end

  test "wrapped by payload", %{object: object} do
    assert object.opcode == :identify
    assert object.data != nil
    assert object.sequence == nil
    assert object.name == nil
  end

  test "identify object is correct", %{object: object} do
    assert object.data.token == "TOKEN"
    assert object.data.compress == false
    assert object.data.large_threshold == 250
    assert object.data.shard == [1, 3]
  end

  test "connection properties object is correct", %{object: object} do
    {_, os} = :os.type()
    assert object.data.properties."$os" == Atom.to_string(os)
    assert object.data.properties."$browser" == "DiscordBot"
    assert object.data.properties."$device" == "DiscordBot"
  end

  test "serializes correctly", %{object: object} do
    {:ok, serialized} =
      object
      |> Identify.to_json()

    assert serialized ==
             "{\"t\":null,\"s\":null,\"op\":2,\"d\":{\"token\":\"TOKEN\",\"shard\":[1,3],\"properties\":{\"$os\":\"linux\",\"$device\":\"DiscordBot\",\"$browser\":\"DiscordBot\"},\"large_threshold\":250,\"compress\":false}}"
  end

  test "deserializes correctly" do
    json =
      "{\"t\":null,\"s\":null,\"op\":2,\"d\":{\"token\":\"TOKEN\",\"shard\":[1,3],\"properties\":{\"$os\":\"linux\",\"$device\":\"DiscordBot\",\"$browser\":\"DiscordBot\"},\"large_threshold\":250,\"compress\":false}}"

    payload = Payload.from_json(json)
    assert payload.opcode == :identify
    assert %Identify{} = payload.data
    assert payload.sequence == nil
    assert payload.name == nil
  end
end
