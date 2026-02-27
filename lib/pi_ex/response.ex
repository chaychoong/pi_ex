defmodule PiEx.Response do
  @moduledoc false
  @enforce_keys [:command, :success]
  defstruct [:command, :success, :error, :data]

  @type t :: %__MODULE__{
          command: String.t(),
          success: boolean(),
          error: String.t() | nil,
          data: map() | nil
        }
end
