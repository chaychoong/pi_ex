defmodule PiEx.Delta do
  @moduledoc """
  Pure accumulator for assembling streaming message deltas.

  Collects `text_delta`, `thinking_delta`, and `toolcall_*` events into a single
  structure. Feed events with `apply_event/2` and read the accumulated state with
  the accessor functions.

      delta =
        PiEx.Delta.new()
        |> PiEx.Delta.apply_event(event1)
        |> PiEx.Delta.apply_event(event2)

      PiEx.Delta.text(delta)
  """

  alias PiEx.Event.AgentEnd
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

  @doc "Create a new empty delta."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Return the accumulated response text."
  @spec text(t()) :: String.t()
  def text(%__MODULE__{text: text}), do: text

  @doc "Return the accumulated thinking/reasoning text."
  @spec thinking(t()) :: String.t()
  def thinking(%__MODULE__{thinking: thinking}), do: thinking

  @doc "Return the list of completed tool calls, each with `:name` and `:arguments` keys."
  @spec tool_calls(t()) :: [map()]
  def tool_calls(%__MODULE__{tool_calls: tool_calls}), do: Enum.reverse(tool_calls)

  @doc "Return `true` if the stream is complete."
  @spec done?(t()) :: boolean()
  def done?(%__MODULE__{done: done}), do: done

  @doc "Return the stop reason (e.g. `\"stop\"`), or `nil` if not yet done."
  @spec stop_reason(t()) :: String.t() | nil
  def stop_reason(%__MODULE__{stop_reason: reason}), do: reason

  @doc "Reset the delta to its initial empty state."
  @spec reset(t()) :: t()
  def reset(%__MODULE__{}), do: new()

  @doc "Apply a streaming event to the delta, returning the updated delta."
  @spec apply_event(t(), struct()) :: t()
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

  def apply_event(%__MODULE__{current_tool: tool} = delta, %MessageUpdate{type: :toolcall_end}) when not is_nil(tool) do
    %{delta | tool_calls: [tool | delta.tool_calls], current_tool: nil}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{type: :done, reason: reason}) do
    %{delta | done: true, stop_reason: reason}
  end

  def apply_event(%__MODULE__{} = delta, %MessageUpdate{}), do: delta

  def apply_event(%__MODULE__{} = delta, %AgentEnd{}) do
    %{delta | done: true}
  end

  def apply_event(%__MODULE__{} = delta, _event), do: delta
end
