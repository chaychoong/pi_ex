defmodule PiEx.Command.SetFollowUpMode do
  @moduledoc false
  @enforce_keys [:mode]
  defstruct [:id, :mode]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          mode: String.t()
        }
end
