defmodule PiEx.Event.MessageUpdate do
  @moduledoc """
  A streaming content delta from Pi's assistant response.

  The `:type` field indicates what kind of content is being streamed (see
  `t:delta_type/0`). Text and thinking content arrive in the `:text` field.
  Tool call events use `:text` for the tool name (on `:toolcall_start`) and
  argument fragments (on `:toolcall_delta`).

  See `PiEx.Delta` for an accumulator that assembles these into a complete
  response.
  """
  defstruct [:type, :text, :reason]

  @type delta_type ::
          :start
          | :text_start
          | :text_delta
          | :text_end
          | :thinking_start
          | :thinking_delta
          | :thinking_end
          | :toolcall_start
          | :toolcall_delta
          | :toolcall_end
          | :done
          | :error
          | :unknown

  @type t :: %__MODULE__{
          type: delta_type(),
          text: String.t() | nil,
          reason: String.t() | nil
        }
end
