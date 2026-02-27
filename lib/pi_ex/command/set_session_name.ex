defmodule PiEx.Command.SetSessionName do
  @moduledoc false
  @enforce_keys [:name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t()
        }
end
