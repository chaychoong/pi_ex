defmodule PiEx.Command.Bash do
  @moduledoc false

  # The struct field is :shell_command (not :command) to avoid collision with
  # the RPC wire protocol's "command" key that identifies the command type.
  # Protocol.encode/1 maps :shell_command back to the "command" JSON key
  # that Pi expects for the bash command's shell string.

  @enforce_keys [:shell_command]
  defstruct [:id, :shell_command]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          shell_command: String.t()
        }
end
