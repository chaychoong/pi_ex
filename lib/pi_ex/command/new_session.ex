defmodule PiEx.Command.NewSession do
  @moduledoc false
  defstruct [:id, :parent_session]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          parent_session: String.t() | nil
        }
end
