defmodule PiEx.Command.RespondUI do
  @moduledoc false
  @enforce_keys [:request_id, :response]
  defstruct [:id, :request_id, :response]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          request_id: String.t(),
          response: map()
        }
end
