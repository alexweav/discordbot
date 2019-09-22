defmodule DiscordBot.Entity.Message do
  @moduledoc """
  Primitives for handling messages.
  """

  alias DiscordBot.Model.{Channel, Message}

  @doc """
  Creates a message containing the given text on a channel.
  """
  @callback create(channel :: Channel.t(), content :: String.t(), opts :: list) :: any

  @doc """
  Replies to a message on the same channel with the given text.
  """
  @callback reply(message :: Message.t(), content :: String.t(), opts :: list) :: any

  @doc """
  Creates a message containing the given text on a channel.
  """
  @spec create(Channel.t(), String.t(), list(any)) :: any
  def create(channel, content, opts \\ []) do
    send(channel.id, content, opts)
  end

  @doc """
  Replies to a message on the same channel with the given text.
  """
  @spec reply(Message.t(), String.t(), list(any)) :: any
  def reply(%Message{channel_id: channel_id}, content, opts \\ []) do
    send(channel_id, content, opts)
  end

  defp send(channel_id, content, tts: true) do
    api().create_tts_message(channel_id, content)
  end

  defp send(channel_id, content, _) do
    api().create_message(channel_id, content)
  end

  defp api do
    Application.get_env(:discordbot, :http_api, DiscordBot.Api)
  end
end
