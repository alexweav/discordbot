defmodule DiscordBot.Fake.DiscordServer do
  @moduledoc false
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  def start() do
    ref = make_ref()
    url = "wss://localhost:#{8473}/fakecord"
    opts = [port: 8473, ref: ref]
    Plug.Adapters.Cowboy.http(__MODULE__, [], opts)
    {:ok, {url, ref}}
  end

  def shutdown(ref) do
    Plug.Adapters.Cowboy.shutdown(ref)
  end

  match _ do
    send_resp(conn, 200, "Hello world!")
  end
end
