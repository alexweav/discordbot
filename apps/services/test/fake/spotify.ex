defmodule Services.Fake.Spotify do
  @moduledoc """
  A fake server which emulates Spotify's API.
  """

  alias Plug.Adapters.Cowboy
  alias Services.Fake.Spotify.Router

  defmacro __using__(_) do
    quote([]) do
      @doc """
      Sets up an instance of the Spotify test server.

      Must be called from a module using `ExUnit.Case`.
      """
      @spec setup_spotify() :: {String.t(), pid}
      def setup_spotify do
        options = [port: 8081]
        # child_spec = {Plug.Cowboy, scheme: :http, plug: Router, options: options}
        # TODO: start this somehow, and on_exit shutdown
        {:ok, pid} = Cowboy.http(Services.Fake.Spotify.Router, [], options)

        on_exit(fn ->
          Cowboy.shutdown(pid)
        end)
      end
    end
  end
end
