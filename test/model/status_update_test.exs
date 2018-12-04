defmodule DiscordBot.Model.StatusUpdateTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.StatusUpdate

  alias DiscordBot.Model.StatusUpdate

  test "wrapped by payload" do
    object = StatusUpdate.status_update(nil, nil, :online)
    assert object.opcode == :status_update
    assert object.data != nil
    assert object.sequence == nil
    assert object.name == nil
  end

  test "plain online update is correct" do
    object = StatusUpdate.status_update(123, nil, :online, true)
    assert object.data.game == nil
    assert object.data.since == 123
    assert object.data.afk == true
    assert object.data.status == :online
  end

  test "serializes correctly" do
    object = StatusUpdate.status_update(123, nil, :dnd, true)

    {:ok, serialized} =
      object
      |> StatusUpdate.to_json()

    map = Poison.decode!(serialized)
    assert map["d"] != nil
    assert map["d"]["since"] == 123
    assert map["d"]["game"] == nil
    assert map["d"]["status"] == "dnd"
    assert map["d"]["afk"] == true
  end
end
