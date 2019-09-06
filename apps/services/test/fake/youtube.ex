defmodule Services.Fake.Youtube do
  @moduledoc """
  A fake server which emulates Youtube's API.
  """

  alias Plug.Adapters.Cowboy

  defmacro __using__(_) do
    quote [] do
      @doc """
      Sets up an instance of the Youtube test server.

      Must be called from a module using `ExUnit.Case`.
      """
      @spec setup_youtube() :: pid
      def setup_youtube do
        options = [port: 8082]
        {:ok, pid} = Cowboy.http(Services.Fake.Youtube.Router, [], options)

        on_exit(fn ->
          Cowboy.shutdown(pid)
        end)

        pid
      end
    end
  end
end
