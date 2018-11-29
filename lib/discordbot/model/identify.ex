defmodule DiscordBot.Model.Identify do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents an identification operation with Discord
  """

  defmodule ConnectionProperties do
    @derive [Poison.Encoder]
    @moduledoc """
    Connection metadata describing the client
    """

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
    :shard
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

  @type t :: %__MODULE__{
          token: token,
          properties: properties,
          compress: compress,
          large_threshold: large_threshold,
          shard: shard
        }

  @doc """
  Builds the message for an identify operation using
  the bot token `token`, the shard index `shard`, and
  the shard count `num_shards`
  """
  def identify(token, shard, num_shards) do
    DiscordBot.Model.Payload.payload(:identify, %__MODULE__{
      token: token,
      properties: ConnectionProperties.connection_properties(),
      compress: false,
      large_threshold: 250,
      shard: [shard, num_shards]
    })
  end
end