defmodule PiEx.Event.UIRequest do
  @moduledoc """
  A UI prompt sent by Pi requesting user interaction.

  The `method` field indicates the kind of prompt (`:select`, `:confirm`,
  `:input`, etc.). Respond with `PiEx.respond_ui/3`.
  """

  defstruct [:id, :method, :title, :options, :message, :placeholder, :prefill, :timeout]

  @type t :: %__MODULE__{
          id: String.t(),
          method:
            :select
            | :confirm
            | :input
            | :editor
            | :notify
            | :set_status
            | :set_widget
            | :set_title
            | :set_editor_text
            | :unknown,
          title: String.t() | nil,
          options: [String.t()] | nil,
          message: String.t() | nil,
          placeholder: String.t() | nil,
          prefill: String.t() | nil,
          timeout: pos_integer() | nil
        }
end
