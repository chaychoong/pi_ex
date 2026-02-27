defmodule PiEx.Event.Unknown do
  @moduledoc false

  # Forward-compatibility struct for unrecognized Pi event types.
  # Protocol.decode_line wraps any event with an unrecognized "type" field
  # into this struct rather than crashing or returning an opaque map.

  defstruct [:type, :data]

  @type t :: %__MODULE__{
          type: String.t(),
          data: map()
        }
end
