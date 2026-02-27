defmodule PiEx.Command.AbortBash do
  @moduledoc false
  defstruct [:id]
  @type t :: %__MODULE__{id: String.t() | nil}
end
