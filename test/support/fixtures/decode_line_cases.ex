defmodule PiEx.TestFixtures.DecodeLineCases do
  @moduledoc false

  alias PiEx.Event
  alias PiEx.Response

  @type decode_case :: %{
          name: String.t(),
          line: String.t(),
          expected: tuple()
        }

  @spec cases() :: [decode_case()]
  def cases do
    [
      %{
        name: "response success with data",
        line: ~s|{"type":"response","command":"get_state","success":true,"id":"req-1","data":{"isStreaming":false}}|,
        expected:
          {:response, "req-1",
           %Response{command: "get_state", success: true, error: nil, data: %{"isStreaming" => false}}}
      },
      %{
        name: "response failure with error",
        line: ~s|{"type":"response","command":"prompt","success":false,"id":"req-2","error":"already streaming"}|,
        expected:
          {:response, "req-2",
           %Response{command: "prompt", success: false, error: "already streaming", data: nil}}
      },
      %{
        name: "response missing optional fields defaults to nil",
        line: ~s|{"type":"response","command":"get_messages","success":true,"id":"req-3"}|,
        expected:
          {:response, "req-3",
           %Response{command: "get_messages", success: true, error: nil, data: nil}}
      },
      %{
        name: "agent start event",
        line: ~s|{"type":"agent_start"}|,
        expected: {:event, %Event.AgentStart{}}
      },
      %{
        name: "agent end event with messages",
        line: ~s|{"type":"agent_end","messages":[{"role":"assistant"}]}|,
        expected: {:event, %Event.AgentEnd{messages: [%{"role" => "assistant"}]}}
      },
      %{
        name: "message update text_delta uses delta key",
        line: ~s|{"type":"message_update","assistantMessageEvent":{"type":"text_delta","delta":"hello"}}|,
        expected: {:event, %Event.MessageUpdate{type: :text_delta, text: "hello", reason: nil}}
      },
      %{
        name: "message update thinking_delta uses text key",
        line: ~s|{"type":"message_update","assistantMessageEvent":{"type":"thinking_delta","text":"reasoning"}}|,
        expected: {:event, %Event.MessageUpdate{type: :thinking_delta, text: "reasoning", reason: nil}}
      },
      %{
        name: "message update done includes reason",
        line: ~s|{"type":"message_update","assistantMessageEvent":{"type":"done","reason":"stop"}}|,
        expected: {:event, %Event.MessageUpdate{type: :done, text: nil, reason: "stop"}}
      },
      %{
        name: "message update unknown subtype",
        line: ~s|{"type":"message_update","assistantMessageEvent":{"type":"future_delta","delta":"x"}}|,
        expected: {:event, %Event.MessageUpdate{type: :unknown, text: "x", reason: nil}}
      },
      %{
        name: "tool execution start event",
        line: ~s|{"type":"tool_execution_start","toolCallId":"tc-1","toolName":"bash","args":{"command":"ls"}}|,
        expected: {:event, %Event.ToolExecutionStart{tool_call_id: "tc-1", tool_name: "bash", args: %{"command" => "ls"}}}
      },
      %{
        name: "tool execution update event",
        line: ~s|{"type":"tool_execution_update","toolCallId":"tc-1","toolName":"bash","partialResult":"out"}|,
        expected:
          {:event,
           %Event.ToolExecutionUpdate{tool_call_id: "tc-1", tool_name: "bash", partial_result: "out"}}
      },
      %{
        name: "tool execution end event",
        line: ~s|{"type":"tool_execution_end","toolCallId":"tc-1","toolName":"bash","result":"done","isError":false}|,
        expected: {:event, %Event.ToolExecutionEnd{tool_call_id: "tc-1", tool_name: "bash", result: "done", is_error: false}}
      },
      %{
        name: "ui request select method",
        line: ~s|{"type":"extension_ui_request","id":"ui-1","method":"select","title":"Pick","options":["a","b"]}|,
        expected:
          {:ui_request,
           %Event.UIRequest{
             id: "ui-1",
             method: :select,
             title: "Pick",
             options: ["a", "b"],
             message: nil,
             placeholder: nil,
             prefill: nil,
             timeout: nil
           }}
      },
      %{
        name: "ui request unknown method maps to unknown",
        line: ~s|{"type":"extension_ui_request","id":"ui-2","method":"future_method","title":"X"}|,
        expected:
          {:ui_request,
           %Event.UIRequest{
             id: "ui-2",
             method: :unknown,
             title: "X",
             options: nil,
             message: nil,
             placeholder: nil,
             prefill: nil,
             timeout: nil
           }}
      },
      %{
        name: "auto compaction start event",
        line: ~s|{"type":"auto_compaction_start"}|,
        expected: {:event, %Event.AutoCompactionStart{}}
      },
      %{
        name: "auto compaction end event",
        line: ~s|{"type":"auto_compaction_end"}|,
        expected: {:event, %Event.AutoCompactionEnd{}}
      },
      %{
        name: "auto retry start event",
        line: ~s|{"type":"auto_retry_start"}|,
        expected: {:event, %Event.AutoRetryStart{}}
      },
      %{
        name: "auto retry end event",
        line: ~s|{"type":"auto_retry_end"}|,
        expected: {:event, %Event.AutoRetryEnd{}}
      },
      %{
        name: "extension error event",
        line: ~s|{"type":"extension_error","message":"boom","code":"ERR_TIMEOUT"}|,
        expected: {:event, %Event.ExtensionError{message: "boom", code: "ERR_TIMEOUT"}}
      },
      %{
        name: "unknown future event",
        line: ~s|{"type":"future_event","payload":{"x":1}}|,
        expected:
          {:event,
           %Event.Unknown{
             type: "future_event",
             data: %{"type" => "future_event", "payload" => %{"x" => 1}}
           }}
      }
    ]
  end
end
