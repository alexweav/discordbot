defmodule Services.AutoResponderTest do
  use ExUnit.Case, async: true
  doctest Services.AutoResponder

  alias Services.AutoResponder

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
