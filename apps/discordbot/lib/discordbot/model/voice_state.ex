defmodule DiscordBot.Model.VoiceState do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a user's voice connection status
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{GuildMember, Serializable}

  defstruct [
    :guild_id,
    :channel_id,
    :user_id,
    :member,
    :session_id,
    :deaf,
    :mute,
    :self_deaf,
    :self_mute,
    :suppress
  ]

  @typedoc """
  The guild ID this voice state is for
  """
  @type guild_id :: String.t()

  @typedoc """
  The channel ID this user is connected to
  """
  @type channel_id :: String.t()

  @typedoc """
  The user ID this voice state is for
  """
  @type user_id :: String.t()

  @typedoc """
  The guild member this voice state is for
  """
  @type member :: GuildMember.t() | nil

  @typedoc """
  The session ID for this voice state
  """
  @type session_id :: String.t()

  @typedoc """
  Whether this user is deafened by the server
  """
  @type deaf :: boolean

  @typedoc """
  Whether this user is muted by the server
  """
  @type mute :: boolean

  @typedoc """
  Whether this user is locally deafened
  """
  @type self_deaf :: boolean

  @typedoc """
  Whether this user is locally muted
  """
  @type self_mute :: boolean

  @typedoc """
  Whether this user is muted by the current user
  """
  @type suppress :: boolean

  @type t :: %__MODULE__{
          guild_id: guild_id,
          channel_id: channel_id,
          user_id: user_id,
          member: member,
          session_id: session_id,
          deaf: deaf,
          mute: mute,
          self_deaf: self_deaf,
          self_mute: self_mute,
          suppress: suppress
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a voice state
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("member", nil, &GuildMember.from_map(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
