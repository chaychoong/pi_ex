defmodule PiEx.Command.GetState do
  @moduledoc false
  defstruct [:id]

  @type t :: %__MODULE__{id: String.t() | nil}
end
