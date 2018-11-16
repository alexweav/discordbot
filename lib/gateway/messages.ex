defmodule DiscordBot.Gateway.Messages do
  @moduledoc """
  Utilities for building messages for communication
  with Discord.
  """

  @doc """
  Builds the heartbeat message
  """
  def heartbeat(sequence_number) do
    %{
      "op" => 1,
      "d" => sequence_number
    }
  end

  @doc """
  Builds the message for an identify operation using
  the bot token `token` and the shard index `shard`
  """
  def identify(token, shard) do
    body = %{
      "token" => token,
      "properties" => connection_properties(),
      "compress" => false,
      "large_threshold" => 250,
      "shard" => shard
    }

    %{
      "op" => 2,
      "d" => body
    }
  end

  @doc """
  Message object representing metadata about the client
  """
  def connection_properties() do
    {_, os} = :os.type()

    %{
      "$os" => Atom.to_string(os),
      "$browser" => "DiscordBot",
      "$device" => "DiscordBot"
    }
  end
end
