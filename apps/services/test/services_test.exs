defmodule ServicesTest do
  use ExUnit.Case
  doctest Services

  test "greets the world" do
    assert Services.hello() == :world
  end
end
