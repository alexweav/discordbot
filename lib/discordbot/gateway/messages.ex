defmodule DiscordBot.Gateway.Messages do
  @moduledoc """
  Utilities for building messages for communication
  with Discord.
  """

  @doc """
  Builds the heartbeat message
  """
  def heartbeat(sequence_number) do
    payload(:heartbeat, sequence_number)
  end

  @doc """
  Generic payload wrapper object for a message with
  opcode `opcode` and a body of `data`
  """
  def payload(opcode, data) do
    %{
      "op" => opcode_from_atom(opcode),
      "d" => data
    }
  end

  @doc """
  Converts a discord opcode to a corresponding atom
  """
  def atom_from_opcode({:ok, opcode}) do
    atom_from_opcode(opcode)
  end

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
