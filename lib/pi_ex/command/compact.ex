defmodule PiEx.Command.Compact do
  @moduledoc false
  defstruct [:id, :custom_instructions]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          custom_instructions: String.t() | nil
        }
end
