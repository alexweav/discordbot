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
      :channel_create -> DiscordBot.Model.Channel.from_map(map)
      :channel_update -> DiscordBot.Model.Channel.from_map(map)
      :channel_delete -> DiscordBot.Model.Channel.from_map(map)
      :guild_create -> DiscordBot.Model.Guild.from_map(map)
      :guild_update -> DiscordBot.Model.Guild.from_map(map)
      :guild_delete -> DiscordBot.Model.Guild.from_map(map)
      :message_create -> DiscordBot.Model.Message.from_map(map)
      :message_update -> DiscordBot.Model.Message.from_map(map)
      _ -> map
    end
  end

  @doc """
  Converts an event name into a corresponding atom
  """
  @spec atom_from_event(String.t()) :: atom
  def atom_from_event(name) do
    %{
      "READY" => :ready,
      "CHANNEL_CREATE" => :channel_create,
      "CHANNEL_UPDATE" => :channel_update,
      "CHANNEL_DELETE" => :channel_delete,
      "GUILD_CREATE" => :guild_create,
      "GUILD_UPDATE" => :guild_update,
      "GUILD_DELETE" => :guild_delete,
      "MESSAGE_CREATE" => :message_create,
      "MESSAGE_UPDATE" => :message_update
    }[name]
  end
end
