defmodule MyStruct do
  @moduledoc """
  An example struct to be used in doctests
  """

  defstruct [:key1, :key2]
end

defmodule DiscordBot.Model.SerializableTest do
  use ExUnit.Case, async: true
  doctest DiscordBot.Model.Serializable
end
