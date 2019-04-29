defmodule DiscordBot.Broker.Event do
  @moduledoc """
  Represent a single broker event.
  """

  defstruct [
    :source,
    :broker,
    :message,
    :topic,
    :publisher
  ]

  @typedoc """
  An atom indicating that the event originated from a broker.
  """
  @type source :: atom

  @typedoc """
  The PID of the broker that sent the event.
  """
  @type broker :: pid

  @typedoc """
  The event data originating from the publisher.
  """
  @type message :: any

  @typedoc """
  The topic that the event is associated with.
  """
  @type topic :: atom

  @typedoc """
  The PID of the process that published this event.
  """
  @type publisher :: pid

  @type t :: %__MODULE__{
          source: source,
          broker: broker,
          message: message,
          topic: topic,
          publisher: publisher
        }
end
