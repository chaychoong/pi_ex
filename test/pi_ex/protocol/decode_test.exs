defmodule PiEx.Protocol.DecodeTest do
  use ExUnit.Case, async: true

  alias PiEx.Event
  alias PiEx.Protocol
  alias PiEx.TestFixtures.DecodeLineCases

  test "decode_line/1 matches the decode fixture corpus" do
    for %{name: name, line: line, expected: expected} <- DecodeLineCases.cases() do
      assert Protocol.decode_line(line) == expected, "decode mismatch for fixture case #{name}"
    end
  end

  test "decodes message and turn boundary events" do
    assert Protocol.decode_line(~s|{"type":"message_start"}|) == {:event, %Event.MessageStart{}}
    assert Protocol.decode_line(~s|{"type":"message_end"}|) == {:event, %Event.MessageEnd{}}
    assert Protocol.decode_line(~s|{"type":"turn_start"}|) == {:event, %Event.TurnStart{}}
    assert Protocol.decode_line(~s|{"type":"turn_end"}|) == {:event, %Event.TurnEnd{}}
  end

  test "decodes extension_ui_request confirm method" do
    line = ~s|{"type":"extension_ui_request","id":"ui-confirm","method":"confirm","title":"Sure?","message":"Delete?"}|

    assert Protocol.decode_line(line) ==
             {:ui_request,
              %Event.UIRequest{
                id: "ui-confirm",
                method: :confirm,
                title: "Sure?",
                options: nil,
                message: "Delete?",
                placeholder: nil,
                prefill: nil,
                timeout: nil
              }}
  end

  test "returns error tuple for invalid JSON" do
    assert {:error, _reason} = Protocol.decode_line("not json")
  end
end