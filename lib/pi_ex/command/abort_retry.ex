defmodule PiEx.Command.AbortRetry do
  @moduledoc false
  defstruct [:id]
  @type t :: %__MODULE__{id: String.t() | nil}
end
