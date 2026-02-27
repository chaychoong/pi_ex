defmodule PiEx.Command.SetAutoRetry do
  @moduledoc false
  @enforce_keys [:enabled]
  defstruct [:id, :enabled]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          enabled: boolean()
        }
end
