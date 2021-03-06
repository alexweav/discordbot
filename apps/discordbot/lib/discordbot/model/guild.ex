defmodule DiscordBot.Model.Guild do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a Discord guild
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Channel, Emoji, GuildMember, Payload, Role, Serializable, VoiceState}

  defstruct [
    :id,
    :name,
    :icon,
    :splash,
    :owner,
    :owner_id,
    :permissions,
    :region,
    :afk_channel_id,
    :afk_timeout,
    :embed_enabled,
    :embed_channel_id,
    :verification_level,
    :default_message_notifications,
    :explicit_content_filter,
    :roles,
    :emojis,
    :features,
    :mfa_level,
    :application_id,
    :widget_enabled,
    :widget_channel_id,
    :system_channel_id,
    :joined_at,
    :large,
    :unavailable,
    :member_count,
    :voice_states,
    :members,
    :channels,
    :presences
  ]

  @typedoc """
  The guild's ID
  """
  @type id :: String.t()

  @typedoc """
  The guild's name
  """
  @type name :: String.t()

  @typedoc """
  The guild's icon hash
  """
  @type icon :: String.t() | nil

  @typedoc """
  The guild's splash hash
  """
  @type splash :: String.t() | nil

  @typedoc """
  Whether or not the current user is the owner of the guild
  """
  @type owner :: boolean

  @typedoc """
  The ID of the guild's owner
  """
  @type owner_id :: String.t()

  @typedoc """
  Total permissions for the user in the guild
  """
  @type permissions :: number

  @typedoc """
  Voice region ID for the guild
  """
  @type region :: String.t()

  @typedoc """
  ID of the AFK channel
  """
  @type afk_channel_id :: String.t()

  @typedoc """
  AFK timeout in seconds
  """
  @type afk_timeout :: number

  @typedoc """
  Whether this guild is embeddable
  """
  @type embed_enabled :: boolean

  @typedoc """
  If not null, the channel ID that the widget will generate an invite to
  """
  @type embed_channel_id :: String.t()

  @typedoc """
  Verification level required for the guild
  """
  @type verification_level :: number

  @typedoc """
  Default message notifications level
  """
  @type default_message_notifications :: number

  @typedoc """
  Explicit content filter level
  """
  @type explicit_content_filter :: number

  @typedoc """
  Roles in the guild
  """
  @type roles :: list(Role.t())

  @typedoc """
  Custom guild emojis
  """
  @type emojis :: list(Emoji.t())

  @typedoc """
  Enabled guild features
  """
  @type features :: list(String.t())

  @typedoc """
  Required multifactor authentication level for the guild
  """
  @type mfa_level :: number

  @typedoc """
  Application ID of the guild creator, if it is bot-created
  """
  @type application_id :: String.t()

  @typedoc """
  Whether or not the server widget is enabled
  """
  @type widget_enabled :: boolean

  @typedoc """
  The channel ID for the server widget
  """
  @type widget_channel_id :: String.t()

  @typedoc """
  The ID of the channel to which system messages are sent
  """
  @type system_channel_id :: String.t()

  @typedoc """
  ISO8601 timestamp of when this guild was joined
  """
  @type joined_at :: String.t()

  @typedoc """
  Whether this is considered a large guild
  """
  @type large :: boolean

  @typedoc """
  Whether this guild is unavailable
  """
  @type unavailable :: boolean

  @typedoc """
  Total number of members in this guild
  """
  @type member_count :: number

  @typedoc """
  Array of voice states for the guild (without the `guild_id` key)
  """
  @type voice_states :: list(VoiceState.t())

  @typedoc """
  Member of the guild
  """
  @type members :: list(GuildMember.t())

  @typedoc """
  Channels in the guild
  """
  @type channels :: list(Channel.t())

  @typedoc """
  Presences of users in the guild
  """
  @type presences :: list(map)

  # TODO: presence update struct

  @type t :: %__MODULE__{
          id: id,
          name: name,
          icon: icon,
          splash: splash,
          owner: owner,
          owner_id: owner_id,
          permissions: permissions,
          region: region,
          afk_channel_id: afk_channel_id,
          afk_timeout: afk_timeout,
          embed_enabled: embed_enabled,
          embed_channel_id: embed_channel_id,
          verification_level: verification_level,
          default_message_notifications: default_message_notifications,
          explicit_content_filter: explicit_content_filter,
          roles: roles,
          emojis: emojis,
          features: features,
          mfa_level: mfa_level,
          application_id: application_id,
          widget_enabled: widget_enabled,
          widget_channel_id: widget_channel_id,
          system_channel_id: system_channel_id,
          joined_at: joined_at,
          large: large,
          unavailable: unavailable,
          member_count: member_count,
          voice_states: voice_states,
          members: members,
          channels: channels,
          presences: presences
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a guild
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.deserialize_array("members", &GuildMember.from_map(&1))
    |> Serializable.deserialize_array("emojis", &Emoji.from_map(&1))
    |> Serializable.deserialize_array("roles", &Role.from_map(&1))
    |> Serializable.deserialize_array("channels", &Channel.from_map(&1))
    |> Serializable.deserialize_array("voice_states", &VoiceState.from_map(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Creates a guild_create payload.
  """
  @spec guild_create(__MODULE__.t()) :: Payload.t()
  def guild_create(guild) do
    Payload.payload(:dispatch, guild, 0, "GUILD_CREATE")
  end
end
