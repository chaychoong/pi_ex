defmodule PiEx.Event.ToolExecutionStart do
  @moduledoc false

  # No @enforce_keys - event structs are constructed internally by
  # Protocol.decode and must not crash on malformed Pi output.
  defstruct [:tool_call_id, :tool_name, :args]

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          tool_name: String.t(),
          args: map() | nil
        }
end
