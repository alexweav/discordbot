defmodule DiscordBot.Model.StatusUpdate do
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

  defimpl Poison.Encoder, for: __MODULE__ do
    def encode(status_update, options) do
      map = Map.from_struct(status_update)

      Poison.Encoder.Map.encode(
        %{map | status: DiscordBot.Model.StatusUpdate.status_from_atom(map[:status])},
        options
      )
    end
  end

  @doc """
  Builds the status update object, given only a `status`. Valid statuses are:
  - `:online`
  - `:dnd`
  - `:idle`
  - `:invisible`
  - `:offline`
  """
  @spec status_update(number, DiscordBot.Model.Activity.t() | nil, atom, boolean) :: __MODULE__.t()
  def status_update(since, game, status, afk \\ false) do
    DiscordBot.Model.Payload.payload(:status_update, %__MODULE__{
      since: since,
      game: game,
      status: status,
      afk: afk
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
  Converts a plain map-represented JSON object `map` into a `StatusUpdate`
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %__MODULE__{
      since: Map.get(map, "since"),
      game: Map.get(map, "game"),
      status: map |> Map.get("status") |> atom_from_status(),
      afk: Map.get(map, "afk")
    }
  end

  @doc """
  Converts a Discord status string into a corresponding atom
  """
  @spec atom_from_status(String.t()) :: atom
  def atom_from_status(status) do
    %{
      "online" => :online,
      "dnd" => :dnd,
      "idle" => :idle,
      "invisible" => :invisible,
      "offline" => :offline
    }[status]
  end

  @doc """
  Converts a status atom into the appropriate status string
  """
  @spec status_from_atom(atom) :: String.t()
  def status_from_atom(atom) do
    %{
      online: "online",
      dnd: "dnd",
      idle: "idle",
      invisible: "invisible",
      offline: "offline"
    }[atom]
  end
end
