defmodule PiEx.Event.MessageUpdate do
  @moduledoc false
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
