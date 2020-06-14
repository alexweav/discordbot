defmodule Services.Audio.Downloader do
  @moduledoc """
  Communicates with a service which can download audio resources.
  """

  use HTTPoison.Base
  alias HTTPoison.Response
  alias Services.Audio.Downloader

  ## HTTPoison.Base Callbacks

  @doc """
  Indicates whether the downloader is reachable.
  """
  def available? do
    uri = "/up"

    case Downloader.get(uri) do
      {:ok, %Response{body: %{"up" => true}}} -> :ok
      response -> {:error, response}
    end
  end

  @doc false
  def process_request_url("/" <> uri) do
    process_request_url(uri)
  end

  def process_request_url(uri) do
    "https://download-dot-discordbot-272801.uc.r.appspot.com/" <> uri
  end

  @doc false
  def process_request_headers(existing) do
    [
      {"Content-Type", "application/json"}
      | existing
    ]
  end

  @doc false
  def process_response_body(body) do
    body
    |> Poison.decode!()
  end
end
