defmodule DiscordBot.Util do
  @moduledoc """
  Various utility methods and helpers.
  """

  @doc """
  Gets the PID of a child process from a supervisor given an ID.

  `supervisor` is the supervisor to query, and `id` is the ID
  to lookup. Do not call this from the `start_link/1` or
  the `init/1` function of any child process of `supervisor`,
  or deadlock will occur.
  """
  @spec child_by_id(pid, any) :: {:ok, pid} | :error
  def child_by_id(supervisor, id) do
    children = Supervisor.which_children(supervisor)

    case Enum.filter(children, fn child -> matches_id?(child, id) end) do
      [] -> :error
      [{_, pid, _, _}] -> {:ok, pid}
      _ -> :error
    end
  end

  defp matches_id?({_, :undefined, _, _}, _), do: false
  defp matches_id?({_, :restarting, _, _}, _), do: false
  defp matches_id?({id, _, _, _}, id), do: true
  defp matches_id?(_, _), do: false

  @doc ~S"""
  Gets a required option from a keyword list.

  Raises an `ArgumentError` with the provided `msg` if the option
  is not present.

  ## Examples

      iex> opts = [option: :value]
      ...> DiscordBot.Util.require_opt!(opts, :option, "Error!")
      :value

      iex> opts = [option: :value]
      ...> DiscordBot.Util.require_opt!(opts, :not_present, "Error!")
      ** (ArgumentError) Error!
  """
  @spec require_opt!(list, atom, String.t()) :: any()
  def require_opt!(opts, key, message) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> value
      :error -> raise ArgumentError, message: message
    end
  end
end
