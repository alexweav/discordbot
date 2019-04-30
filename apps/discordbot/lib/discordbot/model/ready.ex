defmodule DiscordBot.Model.Ready do
  @derive [Poison.Encoder]
  @moduledoc """
  Setup data object sent over the websocket after authentication
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Guild, Serializable, User}

  defstruct [
    :v,
    :user,
    :private_channels,
    :guilds,
    :session_id,
    :_trace
  ]

  @typedoc """
  Gateway protocol version
  """
  @type v :: number

  @typedoc """
  Information about the current user
  """
  @type user :: User.t()

  @typedoc """
  Private channels that the bot is connected to. Initially empty
  """
  @type private_channels :: list

  @typedoc """
  The guilds the user is in
  """
  @type guilds :: list(Guild.t())

  @typedoc """
  Used for resuming connections
  """
  @type session_id :: String.t()

  @typedoc """
  Used for debugging - the guilds the user is in
  """
  @type trace :: list(String.t())

  @type t :: %__MODULE__{
          v: v,
          user: user,
          private_channels: private_channels,
          guilds: guilds,
          session_id: session_id,
          _trace: trace
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a ready object
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("user", nil, &User.from_map(&1))
    |> Map.update(
      "guilds",
      nil,
      &Enum.map(&1, fn guild -> Guild.from_map(guild) end)
    )
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end
end
