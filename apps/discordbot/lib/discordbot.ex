defmodule DiscordBot do
  @moduledoc """
  Top-level supervisor for the bot
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    DiscordBot.Api.start()

    url =
      case DiscordBot.Api.request_gateway() do
        {:ok, %{"url" => url}} ->
          url

        {:error, :invalid_token} ->
          raise("The provided token was rejected by Discord. Please ensure your token is valid.")
      end

    children = [
      {DiscordBot.Broker.Supervisor,
       [
         logged_topics: [
           :dispatch,
           :ready,
           :guild_create,
           :message_create,
           :message_update,
           :resume,
           :reconnect,
           :invalid_session
         ]
       ]},
      {DiscordBot.Gateway, [url: url]},
      {DiscordBot.Self, [name: Self]},
      {DiscordBot.Channel.Supervisor, []},
      {DiscordBot.Handlers.Supervisor, []}
    ]

    Logger.info("Launching...")
    Supervisor.init(children, strategy: :one_for_one)
  end
end