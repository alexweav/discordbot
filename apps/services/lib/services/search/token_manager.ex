defmodule Services.Search.TokenManager do
  @moduledoc """
  Manages and refreshes access tokens which have a defined expiry period.
  """

  require Logger

  defmodule TokenDefinition do
    @moduledoc """
    Represents a token with an expiry period, along with a method
    of re-acquiring the token once it expires
    """
    @enforce_keys [:name, :expiry_seconds, :generator]

    defstruct [
      :name,
      :expiry_seconds,
      :current_value,
      :generator,
      :timer
    ]

    @typedoc """
    A unique identifier for the token
    """
    @type name :: atom

    @typedoc """
    The number of seconds elapsed before this token expires
    """
    @type expiry_seconds :: integer

    @typedoc """
    The current value of the token
    """
    @type current_value :: String.t()

    @typedoc """
    A function which acquires a new token, to be called
    when after `expiry_seconds` seconds elapses
    """
    @type generator :: (() -> String.t())

    @typedoc """
    A reference to the timer process which will respond
    once this token expires
    """
    @type timer :: reference()

    @type t :: %__MODULE__{
            name: name,
            expiry_seconds: expiry_seconds,
            current_value: current_value,
            generator: generator,
            timer: timer
          }
  end

  use GenServer

  @doc """
  Starts the token manager
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Defines a new managed token. The token is regenerated after `expiry_seconds` passes
  using `generator`.

  An initial value is optional. Not providing an `initial` value (or providing `nil`)
  means that `generator` will be used to obtain the first value.
  """
  @spec define(atom | pid, atom, integer, (() -> String.t()), String.t() | nil) :: String.t()
  def define(manager, name, expiry_seconds, generator, initial \\ nil) do
    GenServer.call(manager, {:define, name, expiry_seconds, generator, initial})
  end

  @doc """
  Defines a temporary managed token with value `token`. The token cannot
  be regenerated, and will be deleted automatically after `expiry_seconds`
  passes.
  """
  @spec define_temporary(atom | pid, atom, integer, String.t()) :: String.t()
  def define_temporary(manager, name, expiry_seconds, token) do
    GenServer.call(manager, {:define_temporary, name, expiry_seconds, token})
  end

  @doc """
  Obtains the token value defined under a name. Returns `:error` if
  no token is defined.
  """
  @spec token?(atom | pid, atom) :: String.t() | :error
  def token?(manager, name) do
    GenServer.call(manager, {:lookup, name})
  end

  @doc """
  Undefines a token
  """
  @spec undefine(atom | pid, atom) :: :ok
  def undefine(manager, name) do
    GenServer.call(manager, {:delete, name})
  end

  ## Handlers

  def init(registry) do
    {:ok, registry}
  end

  def handle_call({:define, name, expiry_seconds, generator, initial}, _from, registry) do
    definition = define_internal(name, expiry_seconds, generator, initial)
    {:reply, definition.current_value, Map.put(registry, name, definition)}
  end

  def handle_call({:define_temporary, name, expiry_seconds, token}, _from, registry) do
    definition = define_internal(name, expiry_seconds, token)
    {:reply, definition.current_value, Map.put(registry, name, definition)}
  end

  def handle_call({:lookup, name}, _from, registry) do
    case Map.get(registry, name) do
      nil -> {:reply, :error, registry}
      definition -> {:reply, definition.current_value, registry}
    end
  end

  def handle_call({:delete, name}, _from, registry) do
    case Map.get(registry, name) do
      nil -> {:reply, :ok, registry}
      _ -> {:reply, :ok, Map.delete(registry, name)}
    end
  end

  def handle_info({:expired, name}, registry) do
    Logger.debug(fn -> "Token #{name} expired." end)

    case expire(Map.get(registry, name)) do
      nil -> {:noreply, Map.delete(registry, name)}
      definition -> {:noreply, Map.put(registry, name, definition)}
    end
  end

  defp define_internal(name, expiry_seconds, current_value) do
    %TokenDefinition{
      name: name,
      expiry_seconds: expiry_seconds,
      current_value: current_value,
      generator: nil,
      timer: start_timer(name, expiry_seconds)
    }
  end

  defp define_internal(name, expiry_seconds, generator, nil) do
    %TokenDefinition{
      name: name,
      expiry_seconds: expiry_seconds,
      generator: generator,
      current_value: generator.(),
      timer: start_timer(name, expiry_seconds)
    }
  end

  defp define_internal(name, expiry_seconds, generator, current_value) do
    %TokenDefinition{
      name: name,
      expiry_seconds: expiry_seconds,
      current_value: current_value,
      generator: generator,
      timer: start_timer(name, expiry_seconds)
    }
  end

  defp expire(nil) do
    nil
  end

  defp expire(%TokenDefinition{generator: nil}) do
    nil
  end

  defp expire(
         %TokenDefinition{generator: generator, name: name, expiry_seconds: expiry} = definition
       ) do
    %{definition | current_value: generator.(), timer: start_timer(name, expiry)}
  end

  defp start_timer(name, expiry_seconds) do
    Process.send_after(self(), expiry_message(name), expiry_seconds)
  end

  defp expiry_message(name) do
    {:expired, name}
  end
end
