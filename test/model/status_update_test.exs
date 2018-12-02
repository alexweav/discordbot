defmodule DiscordBot.Model.StatusUpdateTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.StatusUpdate

  alias DiscordBot.Model.StatusUpdate

  test "wrapped by payload" do
    object = StatusUpdate.status_update(:online)
    assert object.opcode == :status_update
    assert object.data != nil
    assert object.sequence == nil
    assert object.name == nil
  end

  test "plain online update is correct" do
    object = StatusUpdate.status_update(:online)
    assert object.data.game == nil
    assert object.data.since == nil
    assert object.data.afk == false
    assert object.data.status == :online
  end
end
