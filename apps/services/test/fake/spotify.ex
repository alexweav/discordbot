defmodule Services.Fake.Spotify do
  @moduledoc """
  A fake server which emulates Spotify's API.
  """

  alias Plug.Adapters.Cowboy

  defmacro __using__(_) do
    quote([]) do
      @doc """
      Sets up an instance of the Spotify test server.

      Must be called from a module using `ExUnit.Case`.
      """
      @spec setup_spotify() :: pid
      def setup_spotify do
        options = [port: 8081]
        {:ok, pid} = Cowboy.http(Services.Fake.Spotify.Router, [], options)

        on_exit(fn ->
          Cowboy.shutdown(pid)
        end)

        pid
      end
    end
  end
end
