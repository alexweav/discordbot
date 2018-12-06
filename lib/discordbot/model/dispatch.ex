defmodule DiscordBot.Model.Dispatch do
  @moduledoc """
  Helpers for deserializing dispatched websocket events
  """

  @doc """
  Builds the appropriate dispatch struct given a `map` and its event `name`
  """
  @spec from_map(map, String.t()) :: struct
  def from_map(map, name) do
    case atom_from_event(name) do
      :ready -> DiscordBot.Model.Ready.from_map(map)
      _ -> map
    end
  end

  @doc """
  Converts an event name into a corresponding atom
  """
  @spec atom_from_event(String.t()) :: atom
  def atom_from_event(name) do
    %{
      "READY" => :ready
    }[name]
  end
end
