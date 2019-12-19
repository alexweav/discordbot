defmodule DiscordBot.ConfigProvider do
  @moduledoc false

  # This is a modification of the default Elixir config provider that
  # ships with Distillery, which allows for optional config files

  use Distillery.Releases.Config.Provider

  @impl Provider
  def init([path]) do
    started? = ensure_started()

    try do
      case Provider.expand_path(path) do
        {:ok, path} ->
          if File.exists?(path) do
            path
            |> eval!()
            |> merge_config()
            |> Mix.Config.persist()
          else
            :ok
          end

        {:error, _} ->
          :ok
      end
    else
      _ -> :ok
    after
      unless started? do
        :ok = Application.stop(:mix)
      end
    end
  end

  def merge_config(runtime_config) do
    Enum.flat_map(runtime_config, fn {app, app_config} ->
      all_env = Application.get_all_env(app)
      Mix.Config.merge([{app, all_env}], [{app, app_config}])
    end)
  end

  def eval!(path, imported_paths \\ [])

  Code.ensure_loaded(Mix.Config)

  if function_exported?(Mix.Config, :eval!, 2) do
    def eval!(path, imported_paths) do
      {config, _} = Mix.Config.eval!(path, imported_paths)
      config
    end
  else
    def eval!(path, imported_paths), do: Mix.Config.read!(path, imported_paths)
  end

  defp ensure_started do
    started? = List.keymember?(Application.started_applications(), :mix, 0)

    unless started? do
      :ok = Application.start(:mix)
      env = System.get_env("MIX_ENV") || "prod"
      System.put_env("MIX_ENV", env)
      Mix.env(String.to_atom(env))
    end

    started?
  end
end
