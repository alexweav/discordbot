defmodule DiscordBot.Handlers.Search.TokenManager do
  @moduledoc """
  Manages and refreshes access tokens which have a defined expiry period.
  """

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
      :generator
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

    @type t :: %__MODULE__{
            name: name,
            expiry_seconds: expiry_seconds,
            current_value: current_value,
            generator: generator
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
  @spec define(pid, atom, integer, (() -> String.t()), String.t() | nil) :: String.t()
  def define(manager, name, expiry_seconds, generator, initial \\ nil) do
    GenServer.call(manager, {:define, name, expiry_seconds, generator, initial})
  end

  @doc """
  Defines a temporary managed token with value `token`. The token cannot
  be regenerated, and will be deleted automatically after `expiry_seconds`
  passes.
  """
  @spec define_temporary(pid, atom, integer, String.t()) :: String.t()
  def define_temporary(manager, name, expiry_seconds, token) do
    GenServer.call(manager, {:define_temporary, name, expiry_seconds, token})
  end

  ## Handlers

  def init(registry) do
    {:ok, registry}
  end

  def handle_call({:define, _name, _expiry_seconds, _generator, _initial}, _from, registry) do
    {:reply, :ok, registry}
  end

  def handle_call({:define_temporary, _name, _expiry_seconds, _token}, _from, registry) do
    {:reply, :ok, registry}
  end
end
