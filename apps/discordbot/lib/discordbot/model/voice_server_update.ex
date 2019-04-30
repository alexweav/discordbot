defmodule DiscordBot.Model.VoiceServerUpdate do
  @derive [Poison.Encoder]
  @moduledoc """
  Sent when a guild's voice server is updated.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.Serializable

  defstruct [
    :token,
    :guild_id,
    :endpoint
  ]

  @typedoc """
  The token for the voice connection.
  """
  @type token :: String.t()

  @typedoc """
  The ID of the guild that this server update is for.
  """
  @type guild_id :: String.t()

  @typedoc """
  The voice server host.
  """
  @type endpoint :: String.t()

  @type t :: %__MODULE__{
          token: token,
          guild_id: guild_id,
          endpoint: endpoint
        }

  @doc """
  Converts a JSON object `map` into a voice server update.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
