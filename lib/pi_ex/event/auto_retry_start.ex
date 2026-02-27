defmodule PiEx.Event.AutoRetryStart do
  @moduledoc "Emitted when Pi begins an automatic retry after a transient error."
  defstruct []
  @type t :: %__MODULE__{}
end
