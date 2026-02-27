defmodule PiEx.Event.ToolExecutionStart do
  @moduledoc "Emitted when Pi begins executing a tool call."
  defstruct [:tool_call_id, :tool_name, :args]

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          tool_name: String.t(),
          args: map() | nil
        }
end
