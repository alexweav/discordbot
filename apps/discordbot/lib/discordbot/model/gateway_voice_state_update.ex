defmodule DiscordBot.Model.GatewayVoiceStateUpdate do
  @derive [Poison.Encoder]
  @moduledoc """
  Requests that the bot's voice state is updated in a channel.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Payload, Serializable}

  defstruct [
    :guild_id,
    :channel_id,
    :self_mute,
    :self_deaf
  ]

  @typedoc """
  The ID of the guild to request an update.
  """
  @type guild_id :: String.t()

  @typedoc """
  The ID of the channel to request an update.
  """
  @type channel_id :: String.t()

  @typedoc """
  Whether or not the bot is muted.
  """
  @type self_mute :: bool

  @typedoc """
  Whether or not the bot is deafened.
  """
  @type self_deaf :: bool

  @type t :: %__MODULE__{
          guild_id: guild_id,
          channel_id: channel_id,
          self_mute: self_mute,
          self_deaf: self_deaf
        }

  @doc """
  Builds the Gateway Voice State Update object.
  """
  @spec new(String.t(), String.t(), boolean, boolean) :: __MODULE__.t()
  def new(guild_id, channel_id, self_mute \\ false, self_deaf \\ false) do
    %__MODULE__{
      guild_id: guild_id,
      channel_id: channel_id,
      self_mute: self_mute,
      self_deaf: self_deaf
    }
  end

  @doc """
  Builds the Gateway Voice State Update object and wraps it in a payload`.
  """
  @spec voice_state_update(String.t(), String.t(), boolean, boolean) ::
          Payload.t()
  def voice_state_update(guild_id, channel_id, self_mute \\ false, self_deaf \\ false) do
    Payload.payload(:voice_state_update, new(guild_id, channel_id, self_mute, self_deaf))
  end

  @doc """
  Converts a JSON object `map` into a gateway voice state update.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
