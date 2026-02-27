defmodule PiEx.Event.ToolExecutionEnd do
  @moduledoc "Emitted when a tool call finishes. Check `:is_error` to distinguish success from failure."

  defstruct [:tool_call_id, :tool_name, :result, :is_error]

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          tool_name: String.t(),
          result: String.t() | nil,
          is_error: boolean() | nil
        }
end
