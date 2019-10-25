defmodule DiscordBot.Voice.Session do
  @moduledoc """
  Represents a single voice session.
  """

  use Supervisor

  alias DiscordBot.Util
  alias DiscordBot.Voice.Control

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

  @doc """
  Gets the PID of the heartbeater process managed by this session.
  """
  @spec heartbeat?(pid) :: {:ok, pid} | :error
  def heartbeat?(session) do
    Util.child_by_id(session, DiscordBot.Gateway.Heartbeat)
  end

  @doc """
  Gets the PID of the control process managed by this session.
  """
  @spec control?(pid) :: {:ok, pid} | :error
  def control?(session) do
    Util.child_by_id(session, DiscordBot.Voice.Control)
  end

  @doc """
  Ends and disconnects this session.
  """
  @spec disconnect(pid) :: true
  def disconnect(session) do
    case control?(session) do
      {:ok, control} -> Control.disconnect(control, 4001)
    end

    Supervisor.stop(session)
  end

  @doc false
  def init(values) do
    children = [
      {DiscordBot.Gateway.Heartbeat, []},
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
