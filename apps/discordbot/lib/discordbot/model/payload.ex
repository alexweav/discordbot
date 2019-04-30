defmodule DiscordBot.Model.Payload do
  @moduledoc """
  An object which wraps all gateway messages
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{Dispatch, Hello, Identify, Payload, StatusUpdate, VoiceState}

  defstruct [
    :opcode,
    :data,
    :sequence,
    :name
  ]

  @typedoc """
  The numeric opcode for the payload
  """
  @type opcode :: atom | number

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
    @spec encode(Payload.t(), Poison.Encoder.options()) :: iodata
    def encode(payload, options) do
      %{opcode: opcode, data: data, sequence: sequence, name: name} = payload

      Poison.Encoder.Map.encode(
        %{
          "op" => Payload.opcode_from_atom(opcode),
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
  @spec payload(atom | number, any, number | nil, String.t() | nil) :: __MODULE__.t()
  def payload(opcode, data, sequence, event_name) when is_number(opcode) do
    opcode
    |> atom_from_opcode()
    |> payload(data, sequence, event_name)
  end

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
  @spec heartbeat(number | nil) :: __MODULE__.t()
  def heartbeat(sequence_number) do
    payload(:heartbeat, sequence_number)
  end

  @doc """
  Converts a plain map-represented JSON object `map` into a payload
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    opcode = map |> Map.get("op") |> atom_from_opcode

    %__MODULE__{
      opcode: opcode,
      data: map |> Map.get("d") |> to_model(opcode, Map.get(map, "t")),
      sequence: Map.get(map, "s"),
      name: Map.get(map, "t")
    }
  end

  @doc """
  Converts a data object to the correct model given its opcode and event name
  """
  @spec to_model(any, atom, String.t()) :: struct
  def to_model(data, opcode, name) do
    case opcode do
      :dispatch -> data |> Dispatch.from_map(name)
      :heartbeat -> data
      :identify -> data |> Identify.from_map()
      :voice_state_update -> data |> VoiceState.from_map()
      :hello -> data |> Hello.from_map()
      :status_update -> data |> StatusUpdate.from_map()
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
    %{
      0 => :dispatch,
      1 => :heartbeat,
      2 => :identify,
      3 => :status_update,
      4 => :voice_state_update,
      6 => :resume,
      7 => :reconnect,
      8 => :request_guild_members,
      9 => :invalid_session,
      10 => :hello,
      11 => :heartbeat_ack
    }[opcode]
  end

  @doc """
  Converts an atom describing a discord opcode to
  its corresponding numeric value
  """
  @spec opcode_from_atom(atom) :: number
  def opcode_from_atom(atom) do
    %{
      dispatch: 0,
      heartbeat: 1,
      identify: 2,
      status_update: 3,
      voice_state_update: 4,
      resume: 6,
      reconnect: 7,
      request_guild_members: 8,
      invalid_session: 9,
      hello: 10,
      heartbeat_ack: 11
    }[atom]
  end
end
