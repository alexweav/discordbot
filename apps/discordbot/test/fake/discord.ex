defmodule DiscordBot.Fake.Discord do
  @moduledoc """
  A fake server which emulates Discord's Gateway API.
  """

  alias DiscordBot.Fake.Discord.{Core, Server}

  defmacro __using__(_) do
    quote([]) do
      @doc """
      Sets up an instance of the Discord test server.

      Must be called from a module using `ExUnit.Case`.
      Returns the URL of the server, and a PID which can be used as a handle.
      """
      @spec setup_discord() :: {String.t(), pid}
      def setup_discord do
        {:ok, {url, ref, core}} = Server.start()

        on_exit(fn ->
          Server.shutdown(ref)
        end)

        {url, core}
      end
    end
  end

  @doc """
  Gets the Gateway API version requested by the client.
  """
  @spec api_version?(pid) :: integer
  defdelegate api_version?(discord), to: Core

  @doc """
  Gets the transport encoding requested by the client.
  """
  @spec encoding?(pid) :: String.t()
  defdelegate encoding?(discord), to: Core

  @doc """
  Gets the most recent frame sent to the server.
  """
  @spec latest_frame?(pid) :: any()
  defdelegate latest_frame?(discord), to: Core

  @doc """
  Gets a list of all frames sent to the server.
  """
  @spec all_frames?(pid) :: list(any())
  defdelegate all_frames?(discord), to: Core

  @doc """
  Sends a Hello message from the server to the client.
  """
  @spec hello(pid, integer, String.t()) :: :ok
  defdelegate hello(discord, interval, trace), to: Core
end
