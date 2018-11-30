defmodule DiscordBot.Model.Payload do
  @moduledoc """
  An object which wraps all gateway messages
  """

  @behaviour DiscordBot.Model.Serializable

  defstruct [
    :opcode,
    :data,
    :sequence,
    :name
  ]

  @typedoc """
  The numeric opcode for the payload
  """
  @type opcode :: number

  @typedoc """
  The body of the payload
  """
  @type data :: any | nil

  @typedoc """
  The sequence number, used for resumes/heartbeats
  """
  @type sequence :: number | nil

  @typedoc """
  The payload's event name, only for opcode 0
  """
  @type name :: String.t() | nil

  @type t :: %__MODULE__{
          opcode: opcode,
          data: data,
          sequence: sequence,
          name: name
        }

  defimpl Poison.Encoder, for: __MODULE__ do
    @spec encode(DiscordBot.Model.Payload.t(), Poison.Encoder.options()) :: iodata
    def encode(payload, options) do
      %{opcode: opcode, data: data, sequence: sequence, name: name} = payload

      Poison.Encoder.Map.encode(
        %{
          "op" => DiscordBot.Model.Payload.opcode_from_atom(opcode),
          "d" => data,
          "s" => sequence,
          "t" => name
        },
        options
      )
    end
  end

  @doc """
  Constructs a payload containing only an opcode, `opcode`
  """
  @spec payload(atom | number) :: __MODULE__.t()
  def payload(opcode) do
    payload(opcode, nil, nil, nil)
  end

  @doc """
  Constructs a payload containing an opcode, `opcode` and a datagram, `data`
  """
  @spec payload(atom | number, any) :: __MODULE__.t()
  def payload(opcode, data) do
    payload(opcode, data, nil, nil)
  end

  @doc """
  Consructs a payload object given the opcode `opcode`, the datagram `data`,
  the sequence number `sequence`, and the event name `event_name`
  """
  @spec payload(number, any, number, String.t()) :: __MODULE__.t()
  def payload(opcode, data, sequence, event_name) when is_number(opcode) do
    opcode
    |> atom_from_opcode()
    |> payload(data, sequence, event_name)
  end

  @spec payload(atom, any, number, String.t()) :: __MODULE__.t()
  def payload(opcode, data, sequence, event_name) when is_atom(opcode) do
    %__MODULE__{
      opcode: opcode,
      data: data,
      sequence: sequence,
      name: event_name
    }
  end

  @doc """
  Builds the heartbeat message
  """
  @spec heartbeat(number) :: __MODULE__.t()
  def heartbeat(sequence_number) do
    payload(:heartbeat, sequence_number)
  end

  @doc """
  Serializes the provided `payload` object into JSON
  """
  @spec to_json(__MODULE__.t()) :: {:ok, iodata}
  def to_json(payload) do
    Poison.encode(payload)
  end

  @doc """
  Deserializes a JSON blob `json` into a payload
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
    opcode = Map.get(map, "op") |> atom_from_opcode

    %__MODULE__{
      opcode: opcode,
      data: Map.get(map, "d") |> to_model(opcode),
      sequence: Map.get(map, "s"),
      name: Map.get(map, "t")
    }
  end

  @doc """
  Converts a data object to the correct model given its opcode
  """
  @spec to_model(any, atom) :: struct
  def to_model(data, opcode) do
    case opcode do
      :heartbeat -> data
      :identify -> data |> DiscordBot.Model.Identify.from_map()
      :hello -> data |> DiscordBot.Model.Hello.from_map()
      :heartbeat_ack -> nil
      _ -> data
    end
  end

  @doc """
  Converts a numeric Discord opcode to a corresponding
  descriptive atom
  """
  @spec atom_from_opcode(number) :: atom
  def atom_from_opcode(opcode) do
    case opcode do
      0 -> :dispatch
      1 -> :heartbeat
      2 -> :identify
      3 -> :status_update
      4 -> :voice_state_update
      6 -> :resume
      7 -> :reconnect
      8 -> :request_guild_members
      9 -> :invalid_session
      10 -> :hello
      11 -> :heartbeat_ack
    end
  end

  @doc """
  Converts an atom describing a discord opcode to
  its corresponding numeric value
  """
  @spec opcode_from_atom(atom) :: number
  def opcode_from_atom(atom) do
    case atom do
      :dispatch -> 0
      :heartbeat -> 1
      :identify -> 2
      :status_update -> 3
      :voice_state_update -> 4
      :resume -> 6
      :reconnect -> 7
      :request_guild_members -> 8
      :invalid_session -> 9
      :hello -> 10
      :heartbeat_ack -> 11
    end
  end
end
