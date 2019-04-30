defmodule DiscordBot.Model.Dispatch do
  @moduledoc """
  Helpers for deserializing dispatched websocket events
  """

  alias DiscordBot.Model.{Channel, Guild, Message, Ready, VoiceServerUpdate, VoiceState}

  @doc """
  Builds the appropriate dispatch struct given a `map` and its event `name`
  """
  @spec from_map(map, String.t()) :: struct | map
  def from_map(map, name) do
    deserializer_map = %{
      ready: &Ready.from_map(&1),
      channel_create: &Channel.from_map(&1),
      channel_update: &Channel.from_map(&1),
      channel_delete: &Channel.from_map(&1),
      guild_create: &Guild.from_map(&1),
      guild_update: &Guild.from_map(&1),
      guild_delete: &Guild.from_map(&1),
      message_create: &Message.from_map(&1),
      message_update: &Message.from_map(&1),
      voice_server_update: &VoiceServerUpdate.from_map(&1),
      voice_state_update: &VoiceState.from_map(&1)
    }

    deserializer = Map.get(deserializer_map, atom_from_event(name), & &1)
    deserializer.(map)
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
      "MESSAGE_UPDATE" => :message_update,
      "VOICE_SERVER_UPDATE" => :voice_server_update,
      "VOICE_STATE_UPDATE" => :voice_state_update
    }[name]
  end
end
