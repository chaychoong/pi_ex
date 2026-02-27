defmodule PiEx.Protocol.DecodeTest do
  use ExUnit.Case, async: true

  alias PiEx.{Event, Response}
  alias PiEx.Protocol

  test "decodes a successful command response" do
    json = ~s|{"type":"response","command":"get_state","success":true,"id":"req-1","data":{"isStreaming":false}}|
    assert {:response, "req-1", %Response{} = resp} = Protocol.decode_line(json)
    assert resp.command == "get_state"
    assert resp.success == true
    assert resp.data == %{"isStreaming" => false}
  end

  test "decodes a failed command response" do
    json = ~s|{"type":"response","command":"prompt","success":false,"id":"req-2","error":"already streaming"}|
    assert {:response, "req-2", %Response{} = resp} = Protocol.decode_line(json)
    refute resp.success
    assert resp.error == "already streaming"
  end

  test "decodes agent_start event" do
    json = ~s|{"type":"agent_start"}|
    assert {:event, %Event.AgentStart{}} = Protocol.decode_line(json)
  end

  test "decodes agent_end event" do
    json = ~s|{"type":"agent_end","messages":[]}|
    assert {:event, %Event.AgentEnd{messages: []}} = Protocol.decode_line(json)
  end

  test "decodes message_update with text_delta" do
    json = ~s|{"type":"message_update","assistantMessageEvent":{"type":"text_delta","text":"hello"}}|
    assert {:event, %Event.MessageUpdate{type: :text_delta, text: "hello"}} = Protocol.decode_line(json)
  end

  test "decodes message_update with thinking_delta" do
    json = ~s|{"type":"message_update","assistantMessageEvent":{"type":"thinking_delta","text":"reasoning..."}}|

    assert {:event, %Event.MessageUpdate{type: :thinking_delta, text: "reasoning..."}} =
             Protocol.decode_line(json)
  end

  test "decodes message_update done event" do
    json = ~s|{"type":"message_update","assistantMessageEvent":{"type":"done","reason":"stop"}}|
    assert {:event, %Event.MessageUpdate{type: :done, reason: "stop"}} = Protocol.decode_line(json)
  end

  test "decodes tool_execution_start event" do
    json = ~s|{"type":"tool_execution_start","toolCallId":"tc-1","toolName":"bash","args":{"command":"ls"}}|
    assert {:event, %Event.ToolExecutionStart{} = event} = Protocol.decode_line(json)
    assert event.tool_call_id == "tc-1"
    assert event.tool_name == "bash"
    assert event.args == %{"command" => "ls"}
  end

  test "decodes tool_execution_end event" do
    json = ~s|{"type":"tool_execution_end","toolCallId":"tc-1","toolName":"bash","result":"output","isError":false}|
    assert {:event, %Event.ToolExecutionEnd{} = event} = Protocol.decode_line(json)
    assert event.result == "output"
    assert event.is_error == false
  end

  test "decodes extension_ui_request as ui_request" do
    json = ~s|{"type":"extension_ui_request","id":"ui-1","method":"select","title":"Pick","options":["a","b"]}|
    assert {:ui_request, %Event.UIRequest{} = event} = Protocol.decode_line(json)
    assert event.id == "ui-1"
    assert event.method == :select
    assert event.options == ["a", "b"]
  end

  test "decodes extension_ui_request confirm method" do
    json = ~s|{"type":"extension_ui_request","id":"ui-2","method":"confirm","title":"Sure?","message":"Delete?"}|

    assert {:ui_request, %Event.UIRequest{method: :confirm, message: "Delete?"}} =
             Protocol.decode_line(json)
  end

  test "returns error tuple for invalid JSON" do
    assert {:error, _reason} = Protocol.decode_line("not json")
  end

  test "returns Event.Unknown for unrecognized event type" do
    json = ~s|{"type":"some_future_event","data":"stuff"}|
    assert {:event, %PiEx.Event.Unknown{type: "some_future_event"}} = Protocol.decode_line(json)
  end
end
