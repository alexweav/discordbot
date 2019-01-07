defmodule DiscordBot.Handlers.Search.Server do
  @moduledoc false

  use GenServer

  require Logger

  alias DiscordBot.Broker
  alias DiscordBot.Broker.Event

  def start_link(opts) do
    broker =
      case Keyword.fetch(opts, :broker) do
        {:ok, pid} -> pid
        :error -> Broker
      end

    GenServer.start_link(__MODULE__, broker, opts)
  end

  ## Handlers

  def init(broker) do
    Broker.subscribe(broker, :message_create)
    {:ok, broker}
  end

  def handle_info(%Event{message: message}, broker) do
    %DiscordBot.Model.Message{channel_id: channel_id, content: content} = message
    handle_content(content, channel_id)
    {:noreply, broker}
  end

  defp handle_content(_, _), do: nil
end
