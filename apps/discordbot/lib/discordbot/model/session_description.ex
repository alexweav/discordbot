defmodule DiscordBot.Model.SessionDescription do
  @derive [Poison.Encoder]
  @moduledoc """
  Describes a voice session.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :audio_codec,
    :video_codec,
    :secret_key,
    :mode,
    :media_session_id
  ]

  @typedoc """
  The codec to use for audio data.
  """
  @type audio_codec :: String.t()

  @typedoc """
  The codec to use for video data.
  """
  @type video_codec :: String.t()

  @typedoc """
  The secret key to use when encrypting RTP data.
  """
  @type secret_key :: list(integer)

  @typedoc """
  The audio encoding mode to use.
  """
  @type mode :: String.t()

  @typedoc """
  ID of the media session.
  """
  @type media_session_id :: String.t()

  @type t :: %__MODULE__{
          audio_codec: audio_codec,
          video_codec: video_codec,
          secret_key: secret_key,
          mode: mode,
          media_session_id: media_session_id
        }

  @doc """
  Converts a JSON map into a Session Description struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
