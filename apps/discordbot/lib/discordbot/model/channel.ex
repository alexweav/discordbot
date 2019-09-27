defmodule DiscordBot.Model.Channel do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a channel within a guild, or a DM channel
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Overwrite, Serializable, User}

  defstruct [
    :id,
    :type,
    :guild_id,
    :position,
    :permission_overwrites,
    :name,
    :topic,
    :nsfw,
    :last_message_id,
    :bitrate,
    :user_limit,
    :rate_limit_per_user,
    :recipients,
    :icon,
    :owner_id,
    :application_id,
    :parent_id,
    :last_pin_timestamp
  ]

  @typedoc """
  The ID of this channel
  """
  @type id :: String.t()

  @typedoc """
  The type of channel
  """
  @type type :: atom

  @typedoc """
  The ID of the guild
  """
  @type guild_id :: String.t()

  @typedoc """
  The sorting position of the channel
  """
  @type position :: number

  @typedoc """
  Explicit permission overwrites for members and roles
  """
  @type permission_overwrites :: list(Overwrite.t())

  @typedoc """
  The name of the channel
  """
  @type name :: String.t()

  @typedoc """
  The channel topic
  """
  @type topic :: String.t()

  @typedoc """
  Whether the channel is nsfw
  """
  @type nsfw :: boolean

  @typedoc """
  The ID of the last message sent in this channel.
  May not point to an existing or valid message.
  """
  @type last_message_id :: String.t()

  @typedoc """
  The bitrate (in bits) of the voice channel
  """
  @type bitrate :: number

  @typedoc """
  The user limit of the voice channel
  """
  @type user_limit :: number

  @typedoc """
  Amount of seconds the user has to wait before sending another message
  (0 -120). Bots, as well as users with permission `manage_messages` or
  `manage_channel`, are unaffected
  """
  @type rate_limit_per_user :: number

  @typedoc """
  The recipients of the DM
  """
  @type recipients :: list(User.t())

  @typedoc """
  Icon hash
  """
  @type icon :: String.t()

  @typedoc """
  ID of the DM creator
  """
  @type owner_id :: String.t()

  @typedoc """
  Application ID of the group DM creator, if it is bot-created
  """
  @type application_id :: String.t()

  @typedoc """
  ID of the parent category for a channel
  """
  @type parent_id :: String.t()

  @typedoc """
  ISO8601 timestamp of when the last pinned message was pinned
  """
  @type last_pin_timestamp :: String.t()

  @type t :: %__MODULE__{
          id: id,
          type: type,
          guild_id: guild_id,
          position: position,
          permission_overwrites: permission_overwrites,
          name: name,
          topic: topic,
          nsfw: nsfw,
          last_message_id: last_message_id,
          bitrate: bitrate,
          user_limit: user_limit,
          rate_limit_per_user: rate_limit_per_user,
          recipients: recipients,
          icon: icon,
          owner_id: owner_id,
          application_id: application_id,
          parent_id: parent_id,
          last_pin_timestamp: last_pin_timestamp
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a channel
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update(
      "permission_overwrites",
      nil,
      &Enum.map(&1, fn overwrite -> Overwrite.from_map(overwrite) end)
    )
    |> Map.update(
      "recipients",
      nil,
      &Enum.map(&1, fn user -> User.from_map(user) end)
    )
    |> Map.update("type", nil, &atom_from_type(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Converts a channel type ID to a corresponding atom.
  """
  @spec atom_from_type(number) :: atom | nil
  def atom_from_type(id) do
    %{
      0 => :guild_text,
      1 => :dm,
      2 => :guild_voice,
      3 => :group_dm,
      4 => :guild_category,
      5 => :guild_news,
      6 => :guild_store
    }[id]
  end

  @doc """
  Converts a channel type atom into its corresponding ID.
  """
  @spec type_from_atom(atom) :: number | nil
  def type_from_atom(atom) do
    %{
      guild_text: 0,
      dm: 1,
      guild_voice: 2,
      group_dm: 3,
      guild_category: 4,
      guild_news: 5,
      guild_store: 6
    }[atom]
  end
end
