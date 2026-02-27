defmodule PiEx.Delta do
  @moduledoc "Pure accumulator for assembling streaming message deltas."

  alias PiEx.Event.MessageUpdate

  defstruct text: "",
            thinking: "",
            tool_calls: [],
            current_tool: nil,
            done: false,
            stop_reason: nil

  @type t :: %__MODULE__{
          text: String.t(),
          thinking: String.t(),
          tool_calls: [map()],
          current_tool: map() | nil,
          done: boolean(),
          stop_reason: String.t() | nil
        }

  def new, do: %__MODULE__{}
  def text(%__MODULE__{text: text}), do: text
  def thinking(%__MODULE__{thinking: thinking}), do: thinking
  def tool_calls(%__MODULE__{tool_calls: tool_calls}), do: Enum.reverse(tool_calls)
  def done?(%__MODULE__{done: done}), do: done
  def stop_reason(%__MODULE__{stop_reason: reason}), do: reason

  def reset(%__MODULE__{}), do: new()

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{type: :text_delta, text: text}) do
    %{delta | text: delta.text <> (text || "")}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{type: :thinking_delta, text: text}) do
    %{delta | thinking: delta.thinking <> (text || "")}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{type: :toolcall_start, text: name}) do
    %{delta | current_tool: %{name: name, arguments: ""}}
  end

  def apply_event(%__MODULE__{current_tool: tool} = delta, %MessageUpdate{type: :toolcall_delta, text: text})
      when not is_nil(tool) do
    %{delta | current_tool: %{tool | arguments: tool.arguments <> (text || "")}}
  end

  def apply_event(%__MODULE__{current_tool: tool} = delta, %MessageUpdate{type: :toolcall_end})
      when not is_nil(tool) do
    %{delta | tool_calls: [tool | delta.tool_calls], current_tool: nil}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{type: :done, reason: reason}) do
    %{delta | done: true, stop_reason: reason}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{}), do: delta
end
