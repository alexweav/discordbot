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
           :status_update,
           :voice_state_update,
           :ready,
           :channel_create,
           :channel_update,
           :channel_delete,
           :guild_create,
           :guild_update,
           :guild_delete,
           :message_create,
           :message_update,
           :resume,
           :reconnect,
           :invalid_session
         ],
         broker_name: Broker
       ]},
      {DiscordBot.Entity.Supervisor, []},
      {DiscordBot.Self, name: Self},
      {DiscordBot.Gateway, url: url, name: DiscordBot.GatewaySupervisor}
    ]

    Logger.info("Launching core app and establishing connection...")
    Supervisor.init(children, strategy: :one_for_one)
  end
end
