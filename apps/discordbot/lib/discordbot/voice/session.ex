defmodule DiscordBot.Voice.Session do
  @moduledoc """
  Represents a single voice session.
  """

  use Supervisor

  alias DiscordBot.Util

  @doc """
  Starts a voice session.
  """
  def start_link(opts) do
    url = Util.require_opt!(opts, :url)
    server_id = Util.require_opt!(opts, :server_id)
    user_id = Util.require_opt!(opts, :user_id)
    session_id = Util.require_opt!(opts, :session_id)
    token = Util.require_opt!(opts, :token)

    values = %{
      server_id: server_id,
      user_id: user_id,
      session_id: session_id,
      token: token,
      url: url
    }

    Supervisor.start_link(__MODULE__, values, opts)
  end

  @doc false
  def init(values) do
    children = [
      {DiscordBot.Voice.Control,
       url: values[:url],
       server_id: values[:server_id],
       user_id: values[:user_id],
       session_id: values[:session_id],
       token: values[:token]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
