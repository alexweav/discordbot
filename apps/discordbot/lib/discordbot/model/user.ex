defmodule DiscordBot.Model.User do
  @derive [Poison.Encoder]
  @moduledoc """
  Represents a Discord user
  """

  use DiscordBot.Model.Serializable

  defstruct [
    :id,
    :username,
    :discriminator,
    :avatar,
    :bot,
    :mfa_enabled,
    :locale,
    :verified,
    :email,
    :flags,
    :premium_type
  ]

  @typedoc """
  The user's ID
  """
  @type id :: String.t()

  @typedoc """
  The user's username, not unique across the platform
  """
  @type username :: String.t()

  @typedoc """
  The user's 4-digit discord tag
  """
  @type discriminator :: String.t()

  @typedoc """
  The user's avatar hash
  """
  @type avatar :: String.t()

  @typedoc """
  Whether or not the user is a bot account
  """
  @type bot :: boolean

  @typedoc """
  Whether the user has two factor auth enabled
  """
  @type mfa_enabled :: boolean

  @typedoc """
  The user's language option
  """
  @type locale :: String.t()

  @typedoc """
  Whether the email on this account has been verified
  """
  @type verified :: boolean

  @typedoc """
  The user's email
  """
  @type email :: String.t()

  @typedoc """
  The flags on a user's account
  """
  @type flags :: number

  @typedoc """
  The type of Nitro subscription on a user's account
  """
  @type premium_type :: number

  @type t :: %__MODULE__{
          id: id,
          username: username,
          discriminator: discriminator,
          avatar: avatar,
          bot: bot,
          mfa_enabled: mfa_enabled,
          locale: locale,
          verified: verified,
          email: email,
          flags: flags,
          premium_type: premium_type
        }

  @doc """
  Converts a plain map-represented JSON object `map` into a user
  """
  @spec from_map(map) :: __MODULE__.t() | {:error, term} | :error
  def from_map(map) do
    DiscordBot.Model.Serializable.struct_from_map(map, as: %__MODULE__{})
  end
end
