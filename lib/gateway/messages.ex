defmodule DiscordBot.Gateway.Messages do
  @moduledoc """
  Utilities for building messages for communication
  with Discord.
  """

  def heartbeat(sequence_number) do
    %{
      "op" => 1,
      "d" => sequence_number
    }
  end
end
