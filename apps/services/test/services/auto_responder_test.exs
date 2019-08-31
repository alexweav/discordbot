defmodule Services.AutoResponderTest do
  use ExUnit.Case, async: true
  doctest Services.AutoResponder

  alias Services.AutoResponder

  test "responds if rules match" do
    rules = [
      {~r/abc(?<group>.+)/, "captured {group}"}
    ]

    expected = {:reply, {:text, "captured test"}}
    assert AutoResponder.generate_response(rules, "abctest") == expected
  end

  test "no response if rules don't match" do
    rules = [
      {~r/abc(?<group>.+)/, "captured {group}"}
    ]

    assert AutoResponder.generate_response(rules, "xyz") == {:noreply}
  end

  test "evaluates rules and performs capture inserts" do
    rules = [
      {~r/abc(?<group>.+)/, "captured {group}"}
    ]

    assert AutoResponder.evaluate_rules(rules, "abctest") == "captured test"
  end

  test ":error if no rules match" do
    rules = [
      {~r/abc(?<group>.+)/, "captured {group}"}
    ]

    assert AutoResponder.evaluate_rules(rules, "xyz") == :error
  end

  test "inserts args into strings" do
    string = "A {arg}"
    args = %{"foo" => "bar", "arg" => "test"}
    assert AutoResponder.insert_string_args(string, args) == "A test"
  end

  test "leaves non-matching args alone" do
    string = "A {arg} and {another}"
    args = %{"foo" => "bar", "arg" => "test"}
    assert AutoResponder.insert_string_args(string, args) == "A test and {another}"
  end
end
