defmodule DiscordBot.Model.VoiceIdentify do
  @derive [Poison.Encoder]
  @moduledoc """
  Identifies the client over the voice control websocket.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Serializable, VoicePayload}

  defstruct([
    :server_id,
    :user_id,
    :session_id,
    :token
  ])

  @typedoc """
  The ID of the server (guild) that we are connecting in.
  """
  @type server_id :: String.t()

  @typedoc """
  The ID of the user connecting to the voice websocket.
  """
  @type user_id :: String.t()

  @typedoc """
  The ID of the voice session.
  """
  @type session_id :: String.t()

  @typedoc """
  A token which authenticates this client.
  """
  @type token :: String.t()

  @type t :: %__MODULE__{
          server_id: server_id,
          user_id: user_id,
          session_id: session_id,
          token: token
        }

  @doc """
  Converts a JSON map to a voice identify struct.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Builds the VoiceIdentify struct.
  """
  @spec voice_identify(String.t(), String.t(), String.t(), String.t()) :: VoicePayload.t()
  def voice_identify(server_id, user_id, session_id, token) do
    VoicePayload.payload(:identify, %__MODULE__{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token
    })
  end
end
