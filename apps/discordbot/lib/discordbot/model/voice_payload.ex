defmodule DiscordBot.Model.VoicePayload do
  @moduledoc """
  An object which wraps all voice control websocket messages.
  """

  use DiscordBot.Model.Serializable

  alias DiscordBot.Model.{
    SelectProtocol,
    SessionDescription,
    Speaking,
    VoiceHello,
    VoiceIdentify,
    VoicePayload,
    VoiceReady
  }

  defstruct [
    :opcode,
    :data
  ]

  @typedoc """
  The numeric opcode for the payload.
  """
  @type opcode :: atom | number

  @typedoc """
  The body of the payload.
  """
  @type data :: any | nil

  @type t :: %__MODULE__{
          opcode: opcode,
          data: data
        }

  defimpl Poison.Encoder, for: __MODULE__ do
    @spec encode(Payload.t(), Poison.Encoder.options()) :: iodata
    def encode(payload, options) do
      %{opcode: opcode, data: data} = payload

      Poison.Encoder.Map.encode(
        %{
          "op" => VoicePayload.opcode_from_atom(opcode),
          "d" => data
        },
        options
      )
    end
  end

  @doc """
  Constructs a voice payload containing only an opcode, `opcode`
  """
  @spec payload(atom | number) :: __MODULE__.t()
  def payload(opcode) do
    payload(opcode, nil)
  end

  @doc """
  Constructs a payload containing an opcode, `opcode` and a datagram, `data`
  """
  @spec payload(atom | number, any) :: __MODULE__.t()
  def payload(opcode, data) when is_number(opcode) do
    opcode
    |> atom_from_opcode
    |> payload(data)
  end

  def payload(opcode, data) when is_atom(opcode) do
    %__MODULE__{
      opcode: opcode,
      data: data
    }
  end

  @doc """
  Builds the voice control heartbeat message.
  """
  @spec heartbeat(integer) :: __MODULE__.t()
  def heartbeat(nonce) do
    payload(:heartbeat, nonce)
  end

  @doc """
  Converts a JSON map into a voice payload.
  """
  @spec from_map(map) :: __MODULE__.t()
  def from_map(map) do
    opcode = map |> Map.get("op") |> atom_from_opcode

    %__MODULE__{
      opcode: opcode,
      data: map |> Map.get("d") |> to_model(opcode)
    }
  end

  @doc """
  Converts a payload body to the correct type given its opcode.
  """
  @spec to_model(any, atom) :: struct
  def to_model(data, opcode) do
    case opcode do
      :identify -> data |> VoiceIdentify.from_map()
      :hello -> data |> VoiceHello.from_map()
      :ready -> data |> VoiceReady.from_map()
      :select_protocol -> data |> SelectProtocol.from_map()
      :speaking -> data |> Speaking.from_map()
      :session_description -> data |> SessionDescription.from_map()
      _ -> data
    end
  end

  @doc """
  Converts a numeric Discord opcode to a corresponding
  descriptive atom.
  """
  @spec atom_from_opcode(number) :: atom
  def atom_from_opcode(opcode) do
    %{
      0 => :identify,
      1 => :select_protocol,
      2 => :ready,
      3 => :heartbeat,
      4 => :session_description,
      5 => :speaking,
      6 => :heartbeat_ack,
      7 => :resume,
      8 => :hello,
      9 => :resumed,
      13 => :client_disconnect
    }[opcode]
  end

  @doc """
  Converts an atom describing a Discord opcode to
  its corresponding numeric value.
  """
  @spec opcode_from_atom(atom) :: number
  def opcode_from_atom(atom) do
    %{
      identify: 0,
      select_protocol: 1,
      ready: 2,
      heartbeat: 3,
      session_description: 4,
      speaking: 5,
      heartbeat_ack: 6,
      resume: 7,
      hello: 8,
      resumed: 9,
      client_disconnect: 13
    }[atom]
  end
end
