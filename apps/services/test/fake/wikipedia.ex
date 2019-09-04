defmodule Services.Fake.Wikipedia do
  @moduledoc """
  A fake server which emulates Wikipedia's API.
  """

  alias Plug.Adapters.Cowboy

  defmacro __using__(_) do
    quote([]) do
      @doc """
      Sets up an instance of the Wikipedia test server.

      Must be called from a module using `ExUnit.Case`.
      """
      @spec setup_wikipedia() :: pid
      def setup_wikipedia do
        options = [port: 8083]
        {:ok, pid} = Cowboy.http(Services.Fake.Wikipedia.Router, [], options)

        on_exit(fn ->
          Cowboy.shutdown(pid)
        end)

        pid
      end
    end
  end
end
