defmodule PiEx.Event.ToolExecutionUpdate do
  @moduledoc "Emitted with partial results while a tool call is running."

  defstruct [:tool_call_id, :tool_name, :partial_result]

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          tool_name: String.t(),
          partial_result: String.t() | nil
        }
end
