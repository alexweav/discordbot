defmodule DiscordBot.Fake.Discord do
  @moduledoc false

  alias DiscordBot.Fake.DiscordServer

  defmacro __using__(_) do
    quote([]) do
      def setup_discord do
        {:ok, {url, ref, core}} = DiscordServer.start()

        on_exit(fn ->
          DiscordServer.shutdown(ref)
        end)

        {url, core}
      end
    end
  end
end
