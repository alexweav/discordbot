defmodule DiscordBot.Fake.Discord do
  @moduledoc false

  alias DiscordBot.Fake.{DiscordCore, DiscordServer}

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

  defdelegate api_version?(discord), to: DiscordCore
  defdelegate encoding?(discord), to: DiscordCore
  defdelegate latest_frame?(discord), to: DiscordCore
  defdelegate all_frames?(discord), to: DiscordCore
  defdelegate hello(discord, interval, trace), to: DiscordCore
end
