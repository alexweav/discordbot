defmodule DiscordBot.Model.Ready do
  @derive [Poison.Encoder]
  @moduledoc """
  Setup data object sent over the websocket after authentication
  """

  @behaviour DiscordBot.Model.Serializable

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
  @type user :: DiscordBot.Model.User.t()

  @typedoc """
  Private channels that the bot is connected to. Initially empty
  """
  @type private_channels :: list

  @typedoc """
  The guilds the user is in
  """
  @type guilds :: list(map)
  # TODO: model object for unavailable guild

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
  Serializes the provided `ready` object into JSON
  """
  @spec to_json(__MODULE__.t()) :: {:ok, iodata}
  def to_json(payload) do
    Poison.encode(payload)
  end

  @doc """
  Deserializes a JSON blob `json` into a ready object
  """
  @spec from_json(iodata) :: __MODULE__.t()
  def from_json(json) do
    {:ok, map} = Poison.decode(json)
    from_map(map)
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a ready object
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %{
      map
      | "user" =>
          map["user"]
          |> DiscordBot.Model.User.from_map(),
        "guilds" =>
          map["guilds"]
          |> Enum.map(&DiscordBot.Model.Guild.from_map(&1))
    }
    |> DiscordBot.Model.Serializable.struct_from_map(as: %__MODULE__{})
  end
end
