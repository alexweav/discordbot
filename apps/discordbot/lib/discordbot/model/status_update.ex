defmodule DiscordBot.Model.StatusUpdate do
  @moduledoc """
  Represents an operation which updates the bot's online status
  """

  use DiscordBot.Model.Serializable

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
  @type status :: atom

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
  @spec status_update(number | nil, DiscordBot.Model.Activity.t() | nil, atom, boolean) ::
          DiscordBot.Model.Payload.t()
  def status_update(since, game, status, afk \\ false) do
    DiscordBot.Model.Payload.payload(:status_update, %__MODULE__{
      since: since,
      game: game,
      status: status,
      afk: afk
    })
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a `StatusUpdate`
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    %{
      map
      | "status" =>
          map["status"]
          |> atom_from_status()
    }

    map
    |> Map.update("status", nil, &atom_from_status(&1))
    |> DiscordBot.Model.Serializable.struct_from_map(as: %__MODULE__{})
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
