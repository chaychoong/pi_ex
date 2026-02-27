defmodule PiEx.EventTest do
  use ExUnit.Case, async: true

  alias PiEx.Event

  test "AgentStart has no required fields" do
    event = %Event.AgentStart{}
    assert event.__struct__ == Event.AgentStart
  end

  test "AgentEnd holds messages" do
    event = %Event.AgentEnd{messages: [%{role: "assistant", content: "hello"}]}
    assert length(event.messages) == 1
  end

  test "MessageUpdate holds type and text" do
    event = %Event.MessageUpdate{type: :text_delta, text: "hello"}
    assert event.type == :text_delta
    assert event.text == "hello"
  end

  test "ToolExecutionStart has tool_call_id and tool_name" do
    event = %Event.ToolExecutionStart{tool_call_id: "tc-1", tool_name: "bash", args: %{}}
    assert event.tool_name == "bash"
  end

  test "ToolExecutionEnd includes is_error flag" do
    event = %Event.ToolExecutionEnd{
      tool_call_id: "tc-1",
      tool_name: "bash",
      result: "output",
      is_error: false
    }

    refute event.is_error
  end

  test "UIRequest holds method and options" do
    event = %Event.UIRequest{
      id: "ui-1",
      method: :select,
      title: "Pick a file",
      options: ["a.ex", "b.ex"]
    }

    assert event.method == :select
    assert length(event.options) == 2
  end

  test "Exited holds exit code" do
    event = %Event.Exited{code: 1}
    assert event.code == 1
  end
end
