defmodule DiscordBot.GunServer do
  @moduledoc """
  A supervisable GenServer-like wrapper for Gun.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour DiscordBot.GunServer
    end
  end
end
