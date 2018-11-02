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
    # IO.inspect(DiscordBot.Api.get!("/v7/users/@me"))
    IO.inspect(request_gateway())
    children = []
    Logger.info("Launching...")
    Supervisor.init(children, strategy: :one_for_one)
  end

  def request_gateway() do
    get_gateway_bot_uri = "/v7/gateway/bot"

    case DiscordBot.Api.get!(get_gateway_bot_uri) do
      %HTTPoison.Response{status_code: 200, body: body} ->
        {:ok, body}

      %HTTPoison.Error{reason: reason} ->
        {:error, reason}
    end
  end
end
