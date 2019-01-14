defmodule DiscordBot.Handlers.Search.TokenManagerTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Handlers.Search.TokenManager

  alias DiscordBot.Handlers.Search.TokenManager

  setup do
    manager = start_supervised!(TokenManager)
    %{manager: manager}
  end

  test "defines new tokens from a static value", %{manager: manager} do
    assert TokenManager.define_temporary(manager, :token, 123, "newvalue") == "newvalue"
    assert TokenManager.token?(manager, :token) == "newvalue"
  end

  test "defines new tokens from a generator", %{manager: manager} do
    assert TokenManager.define(manager, :token, 123, fn -> "newvalue" end) == "newvalue"
    assert TokenManager.token?(manager, :token) == "newvalue"
  end

  test "doesn't generate on definition if initial provided", %{manager: manager} do
    assert TokenManager.define(manager, :token, 123, fn -> "newvalue" end, "initial") == "initial"
    assert TokenManager.token?(manager, :token) == "initial"
  end
end
