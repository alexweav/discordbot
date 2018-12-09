defmodule DiscordBot.Model.Serializable do
  @moduledoc """
  Behaviour for modules which perform serialization/deserialization
  """

  defmacro __using__(_) do
    quote([]) do
      @behaviour DiscordBot.Model.Serializable

      @doc """
      Serializes the provided instance of this type `struct` into JSON
      """
      @spec to_json(__MODULE__.t()) :: {:ok, iodata}
      def to_json(struct) do
        Poison.encode(struct)
      end

      defoverridable to_json: 1
    end
  end

  @callback from_json(json :: iodata) ::
              {:ok, deserialized :: term}
              | {:error, reason :: term}
              | :error

  @callback from_map(map :: map) ::
              {:ok, deserialized :: term}
              | {:error, reason :: term}
              | :error

  @callback to_json(object :: term) ::
              {:ok, json :: iodata}
              | {:error, reason :: term}
              | :error

  @doc """
  Converts a string-keyed map `map` into a struct of type `struct`.

  Does so without converting arbitrarily passed strings to atoms,
  but treats string keys as if they are struct atoms.

  Map keys that aren't in the struct are ignored, and struct keys
  that aren't in the map have their default value preserved.

  ## Examples

  Suppose the following struct is defined:

      defmodule MyStruct do
        defstruct [:key1, :key2]
      end

      iex> import MyStruct
      ...> DiscordBot.Model.Serializable.struct_from_map(%{"key1" => "asdf", "key2" => %{other: :item}}, as: %MyStruct{})
      %MyStruct{key1: "asdf", key2: %{other: :item}}

      iex> import MyStruct
      ...> DiscordBot.Model.Serializable.struct_from_map(%{"not" => "found", "key1" => :found}, as: %MyStruct{})
      %MyStruct{key1: :found, key2: nil}

  """
  @spec struct_from_map(map, as: struct) :: struct
  def struct_from_map(map, as: struct) do
    keys =
      struct
      |> Map.keys()
      |> Enum.filter(fn x -> x != :__struct__ end)

    converted =
      for key <- keys, into: %{} do
        value = Map.get(map, key) || Map.get(map, to_string(key))
        {key, value}
      end

    Map.merge(struct, converted)
  end
end
