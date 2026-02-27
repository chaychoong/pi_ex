defmodule PiEx.Event.AgentEnd do
  @moduledoc false
  defstruct [:messages]
  @type t :: %__MODULE__{messages: [map()] | nil}
end
