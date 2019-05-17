defmodule DiscordBot.Fake.Discord.Server do
  @moduledoc false
  use Plug.Router

  alias DiscordBot.Fake.Discord.Core
  alias DiscordBot.Fake.Discord.Server
  alias DiscordBot.Fake.Discord.WebsocketHandler
  alias Plug.Adapters.Cowboy
  alias Plug.Cowboy.Handler

  plug(:match)
  plug(:dispatch)

  def start do
    ref = make_ref()
    port = generate_port()
    url = "ws://localhost:#{port}/gateway"
    {:ok, core} = Core.start_link([])
    opts = [port: port, ref: ref, dispatch: dispatch(core)]

    case Cowboy.http(__MODULE__, [], opts) do
      {:ok, _} -> {:ok, {url, ref, core}}
      {:error, :eaddrinuse} -> start()
    end
  end

  def shutdown(ref) do
    Cowboy.shutdown(ref)
  end

  match _ do
    send_resp(conn, 200, "Hello world!")
  end

  def dispatch(args) do
    [
      {:_,
       [
         {"/gateway", WebsocketHandler, [args]},
         {"/voice", VoiceWebsocketHandler, [args]},
         {:_, Handler, {Server, []}}
       ]}
    ]
  end

  defp generate_port do
    Enum.random(50_000..60_000)
  end
end
