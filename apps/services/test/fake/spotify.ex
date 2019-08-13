defmodule Services.Fake.Spotify do
  @moduledoc """
  A fake server which emulates Spotify's API.
  """

  alias Services.Fake.Spotify.Router

  defmacro __using__(_) do
    quote([]) do
      @doc """
      Sets up an instance of the Spotify test server.

      Must be called from a module using `ExUnit.Case`.
      Returns the URL of the server, and a PID which can be used
      as a handle.
      """
      @spec setup_spotify() :: {String.t(), pid}
      def setup_spotify do
        child_spec = {Plug.Cowboy, scheme: :http, plug: Router, options: [port: 8081]}
        # TODO: start this somehow, and on_exit shutdown
        nil
      end
    end
  end
end
