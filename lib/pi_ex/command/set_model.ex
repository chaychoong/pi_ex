defmodule PiEx.Command.SetModel do
  @moduledoc false
  @enforce_keys [:provider, :model_id]
  defstruct [:id, :provider, :model_id]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          provider: String.t(),
          model_id: String.t()
        }
end
