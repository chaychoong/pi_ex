defmodule PiEx.Event.ToolExecutionEnd do
  @moduledoc false

  defstruct [:tool_call_id, :tool_name, :result, :is_error]

  @type t :: %__MODULE__{
          tool_call_id: String.t(),
          tool_name: String.t(),
          result: String.t() | nil,
          is_error: boolean() | nil
        }
end
