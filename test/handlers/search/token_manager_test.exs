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

  test "undefined token returns error", %{manager: manager} do
    assert TokenManager.token?(manager, :undefined) == :error
  end

  test "tokens are deletable", %{manager: manager} do
    TokenManager.define_temporary(manager, :token, 1, "value")
    assert TokenManager.token?(manager, :token) == "value"
    assert TokenManager.undefine(manager, :token) == :ok
    assert TokenManager.token?(manager, :token) == :error
  end

  test "temp token undefined after time expires", %{manager: manager} do
    TokenManager.define_temporary(manager, :token, 1, "mytoken")
    assert TokenManager.token?(manager, :token) == "mytoken"
    Process.sleep(10)

    # Do a lookup to synchronously wait for the manager to process the expiry message
    TokenManager.token?(manager, :undefined)
    assert TokenManager.token?(manager, :token) == :error
  end

  test "generated token redefined after time expires", %{manager: manager} do
    TokenManager.define(manager, :token, 1, fn -> "newvalue" end, "initial")
    assert TokenManager.token?(manager, :token) == "initial"
    Process.sleep(10)

    # Do a lookup to synchronously wait for the manager to process the expiry message
    TokenManager.token?(manager, :undefined)
    assert TokenManager.token?(manager, :token) == "newvalue"
  end
end
