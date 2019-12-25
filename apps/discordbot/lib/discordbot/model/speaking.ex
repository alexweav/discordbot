defmodule DiscordBot.Model.Speaking do
  @derive [Poison.Encoder]
  @moduledoc """
  Indicates that a user is speaking currently.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Serializable, VoicePayload}

  defstruct([
    :speaking,
    :delay,
    :ssrc
  ])

  @typedoc """
  True, if this indicates that the bot has begun speaking.
  """
  @type speaking :: boolean

  @typedoc """
  The delay after which the bot should transition to speaking.
  """
  @type delay :: integer

  @typedoc """
  RTP synchronization source.
  """
  @type ssrc :: integer

  @type t :: %__MODULE__{
          speaking: speaking,
          delay: delay,
          ssrc: ssrc
        }

  @doc """
  Converts a JSON map to a speaking struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Builds the speaking struct.
  """
  @spec new(boolean, integer, integer) :: __MODULE__.t()
  def new(speaking, delay, ssrc) do
    %__MODULE__{
      speaking: speaking,
      delay: delay,
      ssrc: ssrc
    }
  end

  @doc """
  Builds the Speaking struct and wraps it in a payload.
  """
  @spec speaking(boolean, integer, integer) :: VoicePayload.t()
  def speaking(speaking, delay, ssrc) do
    VoicePayload.payload(:speaking, new(speaking, delay, ssrc))
  end
end
