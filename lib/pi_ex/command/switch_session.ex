defmodule PiEx.Command.SwitchSession do
  @moduledoc false
  @enforce_keys [:session_path]
  defstruct [:id, :session_path]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          session_path: String.t()
        }
end
