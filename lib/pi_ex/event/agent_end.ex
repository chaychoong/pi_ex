defmodule PiEx.Event.AgentEnd do
  @moduledoc "Emitted when Pi finishes processing. The `:messages` field contains the final conversation history."
  defstruct [:messages]
  @type t :: %__MODULE__{messages: [map()] | nil}
end
