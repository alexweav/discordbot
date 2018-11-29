defmodule DiscordBot.Model.Serializable do
  @moduledoc """
  Behaviour for modules which perform serialization/deserialization
  """

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
end
