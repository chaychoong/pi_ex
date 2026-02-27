defmodule PiEx.Command.Fork do
  @moduledoc false
  @enforce_keys [:entry_id]
  defstruct [:id, :entry_id]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          entry_id: String.t()
        }
end
