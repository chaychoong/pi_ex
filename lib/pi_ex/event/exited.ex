defmodule PiEx.Event.Exited do
  @moduledoc false

  defstruct [:code]

  @type t :: %__MODULE__{code: non_neg_integer()}
end
