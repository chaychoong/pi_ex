defmodule PiEx.Event.ExtensionError do
  @moduledoc false
  defstruct [:message, :code]

  @type t :: %__MODULE__{
          message: String.t() | nil,
          code: String.t() | nil
        }
end
