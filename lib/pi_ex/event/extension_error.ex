defmodule PiEx.Event.ExtensionError do
  @moduledoc "Emitted when a Pi extension encounters an error."
  defstruct [:message, :code]

  @type t :: %__MODULE__{
          message: String.t() | nil,
          code: String.t() | nil
        }
end
