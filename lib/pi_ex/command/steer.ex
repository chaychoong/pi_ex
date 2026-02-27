defmodule PiEx.Command.Steer do
  @moduledoc false
  @enforce_keys [:message]
  defstruct [:id, :message, :images]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          message: String.t(),
          images: [map()] | nil
        }
end
