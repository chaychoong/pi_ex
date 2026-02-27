defmodule PiEx.Command.GetAvailableModels do
  @moduledoc false
  defstruct [:id]
  @type t :: %__MODULE__{id: String.t() | nil}
end
