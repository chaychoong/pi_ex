defmodule PiEx.Command.SetThinkingLevel do
  @moduledoc false
  @enforce_keys [:level]
  defstruct [:id, :level]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          level: String.t()
        }
end
