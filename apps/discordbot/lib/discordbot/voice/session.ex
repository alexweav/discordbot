defmodule DiscordBot.Voice.Session do
  @moduledoc """
  Represents a single voice session.
  """

  use Supervisor

  @doc """
  Starts a voice session.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @doc false
  def init(:ok) do
    children = []

    Supervisor.init(children, strategy: :one_for_all)
  end
end
