defmodule PiEx.Protocol.EncodeTest do
  use ExUnit.Case, async: true

  alias PiEx.Command
  alias PiEx.Protocol

  test "encodes Prompt with message and id" do
    cmd = %Command.Prompt{message: "hello", id: "req-1"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "prompt"
    assert decoded["message"] == "hello"
    assert decoded["id"] == "req-1"
    refute Map.has_key?(decoded, "images")
  end

  test "encodes Prompt with images" do
    cmd = %Command.Prompt{
      message: "describe this",
      id: "req-2",
      images: [%{data: "base64data", mime_type: "image/png"}]
    }

    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "prompt"
    assert length(decoded["images"]) == 1
    assert hd(decoded["images"])["mimeType"] == "image/png"
  end

  test "encodes SetModel with camelCase conversion" do
    cmd = %Command.SetModel{provider: "anthropic", model_id: "claude-sonnet", id: "req-3"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "set_model"
    assert decoded["provider"] == "anthropic"
    assert decoded["modelId"] == "claude-sonnet"
    refute Map.has_key?(decoded, "model_id")
  end

  test "encodes Abort with only command field" do
    cmd = %Command.Abort{id: "req-4"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "abort"
    assert decoded["id"] == "req-4"
    assert map_size(decoded) == 2
  end

  test "encodes Bash command" do
    cmd = %Command.Bash{shell_command: "mix test", id: "req-5"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "bash"
    assert decoded["shellCommand"] == "mix test"
  end

  test "encodes Steer command" do
    cmd = %Command.Steer{message: "focus on tests", id: "req-6"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "steer"
    assert decoded["message"] == "focus on tests"
  end

  test "encodes FollowUp command" do
    cmd = %Command.FollowUp{message: "now run tests", id: "req-7"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["command"] == "follow_up"
  end

  test "encodes RespondUI as extension_ui_response" do
    cmd = %Command.RespondUI{request_id: "ui-1", response: %{value: "yes"}, id: "req-8"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    assert decoded["type"] == "extension_ui_response"
    assert decoded["id"] == "ui-1"
    assert decoded["value"] == "yes"
  end

  test "omits nil fields from output" do
    cmd = %Command.Prompt{message: "hello", id: "req-9"}
    json = Protocol.encode(cmd)
    decoded = JSON.decode!(json)

    refute Map.has_key?(decoded, "images")
  end
end
