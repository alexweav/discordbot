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

  @doc """
  Gets the metadata for a file managed the downloader, by path.
  """
  def get_file(path) do
    uri = "/files/" <> URI.encode(path)

    case Downloader.get(uri) do
      {:ok, %Response{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %Response{status_code: 404}} -> {:error, :notfound}
      {:error, response} -> {:error, response}
    end
  end

  @doc """
  Downloads a file managed by the downloader to a local file.
  The local file must already exist.
  """
  def download_file(path, local_path) do
    uri = "/files/" <> URI.encode(path) <> "?alt=media"
    url = process_request_url(uri)

    result = :httpc.request(:get, {to_charlist(url), []}, [], stream: to_charlist(local_path))

    case result do
      {:ok, :saved_to_file} -> :ok
      other -> {:error, other}
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
