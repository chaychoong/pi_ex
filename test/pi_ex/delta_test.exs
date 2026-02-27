defmodule PiEx.DeltaTest do
  use ExUnit.Case, async: true

  alias PiEx.Delta
  alias PiEx.Event.MessageUpdate

  test "new returns empty delta" do
    delta = Delta.new()
    assert Delta.text(delta) == ""
    assert Delta.thinking(delta) == ""
    assert Delta.tool_calls(delta) == []
  end

  test "accumulates text deltas" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :text_start})
      |> Delta.apply_event(%MessageUpdate{type: :text_delta, text: "hel"})
      |> Delta.apply_event(%MessageUpdate{type: :text_delta, text: "lo"})
      |> Delta.apply_event(%MessageUpdate{type: :text_end})

    assert Delta.text(delta) == "hello"
  end

  test "accumulates thinking deltas" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :thinking_start})
      |> Delta.apply_event(%MessageUpdate{type: :thinking_delta, text: "let me "})
      |> Delta.apply_event(%MessageUpdate{type: :thinking_delta, text: "think"})
      |> Delta.apply_event(%MessageUpdate{type: :thinking_end})

    assert Delta.thinking(delta) == "let me think"
  end

  test "accumulates tool call deltas" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :toolcall_start, text: "bash"})
      |> Delta.apply_event(%MessageUpdate{type: :toolcall_delta, text: "{\"command\":"})
      |> Delta.apply_event(%MessageUpdate{type: :toolcall_delta, text: "\"ls\"}"})
      |> Delta.apply_event(%MessageUpdate{type: :toolcall_end})

    assert [%{name: "bash", arguments: ~s({"command":"ls"})}] = Delta.tool_calls(delta)
  end

  test "handles interleaved text and thinking" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :thinking_start})
      |> Delta.apply_event(%MessageUpdate{type: :thinking_delta, text: "hmm"})
      |> Delta.apply_event(%MessageUpdate{type: :thinking_end})
      |> Delta.apply_event(%MessageUpdate{type: :text_start})
      |> Delta.apply_event(%MessageUpdate{type: :text_delta, text: "answer"})
      |> Delta.apply_event(%MessageUpdate{type: :text_end})

    assert Delta.thinking(delta) == "hmm"
    assert Delta.text(delta) == "answer"
  end

  test "tracks completion via done message event" do
    delta = Delta.new()
    refute Delta.done?(delta)

    delta = Delta.apply_event(delta, %MessageUpdate{type: :done, reason: "stop"})
    assert Delta.done?(delta)
    assert Delta.stop_reason(delta) == "stop"
  end

  test "tracks completion via AgentEnd" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :text_delta, text: "hello"})
      |> Delta.apply_event(%PiEx.Event.AgentEnd{messages: []})

    assert Delta.done?(delta)
    assert Delta.text(delta) == "hello"
  end

  test "ignores unrecognized events" do
    delta =
      Delta.new()
      |> Delta.apply_event(%PiEx.Response{command: "prompt", success: true})
      |> Delta.apply_event(%PiEx.Event.AgentStart{})

    assert Delta.text(delta) == ""
    refute Delta.done?(delta)
  end

  test "reset clears accumulated state" do
    delta =
      Delta.new()
      |> Delta.apply_event(%MessageUpdate{type: :text_delta, text: "hello"})
      |> Delta.reset()

    assert Delta.text(delta) == ""
  end
end
