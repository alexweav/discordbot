defmodule DiscordBot.Fake.Discord do
  @moduledoc false

  alias DiscordBot.Fake.Discord.{Core, Server}

  defmacro __using__(_) do
    quote([]) do
      def setup_discord do
        {:ok, {url, ref, core}} = Server.start()

        on_exit(fn ->
          Server.shutdown(ref)
        end)

        {url, core}
      end
    end
  end

  defdelegate api_version?(discord), to: Core
  defdelegate encoding?(discord), to: Core
  defdelegate latest_frame?(discord), to: Core
  defdelegate all_frames?(discord), to: Core
  defdelegate hello(discord, interval, trace), to: Core
end
