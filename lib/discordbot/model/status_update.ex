defmodule DiscordBot.Model.StatusUpdate do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an operation which updates the bot's online status
  """

  @behaviour DiscordBot.Model.Serializable

  defstruct [
    :since,
    :game,
    :status,
    :afk
  ]

  @typedoc """
  Unix time (in milliseconds) of when the client went idle,
  or `nil` if the client is not idle
  """
  @type since :: number | nil

  @typedoc """
  The user's new activity. Not currently supported
  """
  @type game :: nil

  @typedoc """
  The user's new status. One of:
  - `online`: Online
  - `dnd`: Do Not Disturb
  - `idle`: AFK
  - `invisible`: Invisible and shown as offline
  - `offline`: Offline
  """
  @type status :: String.t()

  @typedoc """
  Whether or not the client is afk
  """
  @type afk :: boolean

  @type t :: %__MODULE__{
          since: since,
          game: game,
          status: status,
          afk: afk
        }

  @doc """
  Builds the status update object, given a `status`
  """
  @spec status_update(status) :: __MODULE__.t()
  def status_update(status) do
    DiscordBot.Model.Payload.payload(:status_update, %__MODULE__{
      since: nil,
      game: nil,
      status: status,
      afk: false
    })
  end

  @doc """
  Serializes the provided `status_update` object into JSON
  """
  @spec to_json(__MODULE__.t()) :: {:ok, iodata}
  def to_json(payload) do
    Poison.encode(payload)
  end

  @doc """
  Deserializes a JSON blob `json` into a `status_update` object
  """
  @spec from_json(iodata) :: __MODULE__.t()
  def from_json(json) do
    {:ok, map} = Poison.decode(json)
    from_map(map)
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a payload
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %__MODULE__{
      since: Map.get(map, "since"),
      game: Map.get(map, "game"),
      status: Map.get(map, "status"),
      afk: Map.get(map, "afk")
    }
  end
end
