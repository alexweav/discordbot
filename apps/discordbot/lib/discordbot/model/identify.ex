defmodule DiscordBot.Model.Identify do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an identification operation with Discord
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Payload, Serializable, StatusUpdate}

  @default_presence %StatusUpdate{
    afk: false,
    status: :online,
    since: 0
  }

  defmodule ConnectionProperties do
    @derive [Poison.Encoder]
    @moduledoc """
    Connection metadata describing the client
    """

    use DiscordBot.Model.Serializable

    defstruct [
      :"$os",
      :"$browser",
      :"$device"
    ]

    @typedoc """
    Describes the client's OS
    """
    @type os :: String.t()

    @typedoc """
    Describes the client's browser type
    """
    @type browser :: String.t()

    @typedoc """
    Describes the client's device type
    """
    @type device :: String.t()

    @type t :: %__MODULE__{
            "$os": os,
            "$browser": browser,
            "$device": device
          }

    @doc """
    Converts a plain map-represented JSON object `map` into a payload
    """
    @spec from_map(map) :: __MODULE__.t()
    def from_map(map) do
      %__MODULE__{
        "$os": Map.get(map, "$os"),
        "$browser": Map.get(map, "$browser"),
        "$device": Map.get(map, "$device")
      }
    end

    @doc """
    Builds the connection properties object
    """
    def connection_properties do
      {_, os} = :os.type()

      %__MODULE__{
        "$os": Atom.to_string(os),
        "$browser": "DiscordBot",
        "$device": "DiscordBot"
      }
    end
  end

  defstruct [
    :token,
    :properties,
    :compress,
    :large_threshold,
    :shard,
    :presence
  ]

  @typedoc """
  Bot identification token
  """
  @type token :: String.t()

  @typedoc """
  Metadata describing the client
  """
  @type properties :: ConnectionProperties.t()

  @typedoc """
  Whether this connection supports packet compression
  """
  @type compress :: boolean

  @typedoc """
  Number of guild members required before the gateway
  will stop sending offline guild members in the response
  """
  @type large_threshold :: number

  @typedoc """
  Array of two integers `[shard_id, num_shards]`
  """
  @type shard :: list(number)

  @typedoc """
  The initial status of the bot.
  """
  @type presence :: nil | StatusUpdate.t()

  @type t :: %__MODULE__{
          token: token,
          properties: properties,
          compress: compress,
          large_threshold: large_threshold,
          shard: shard,
          presence: presence
        }

  @doc """
  Converts a plain map-represented JSON object `map` into an identify object
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    map
    |> Map.update("properties", nil, &ConnectionProperties.from_map(&1))
    |> Serializable.struct_from_map(as: %__MODULE__{})
  end

  @doc """
  Builds an identify operation using
  the bot token `token`, the shard index `shard`, and
  the shard count `num_shards`.
  """
  @spec new(String.t(), integer, integer, StatusUpdate.t()) :: __MODULE__.t()
  def new(token, shard, num_shards, presence \\ @default_presence) do
    %__MODULE__{
      token: token,
      properties: ConnectionProperties.connection_properties(),
      compress: false,
      large_threshold: 250,
      shard: [shard, num_shards],
      presence: presence
    }
  end

  @doc """
  Builds the message for an identify operation using
  the bot token `token`, the shard index `shard`, and
  the shard count `num_shards`
  """
  def identify(token, shard, num_shards, presence \\ @default_presence) do
    Payload.payload(:identify, new(token, shard, num_shards, presence))
  end
end
