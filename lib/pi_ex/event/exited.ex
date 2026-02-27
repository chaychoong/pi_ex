defmodule PiEx.Event.Exited do
  @moduledoc "Emitted when the Pi OS process exits. The `:code` field is the exit status."

  defstruct [:code]

  @type t :: %__MODULE__{code: non_neg_integer()}
end
