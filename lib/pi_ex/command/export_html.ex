defmodule PiEx.Command.ExportHtml do
  @moduledoc false
  @enforce_keys [:output_path]
  defstruct [:id, :output_path]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          output_path: String.t()
        }
end
