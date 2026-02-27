defmodule PiEx.CommandTest do
  use ExUnit.Case, async: true

  alias PiEx.Command

  test "Prompt requires message" do
    assert_raise ArgumentError, fn -> struct!(Command.Prompt, %{}) end
    prompt = %Command.Prompt{message: "hello"}
    assert prompt.message == "hello"
    assert prompt.images == nil
    assert prompt.id == nil
  end

  test "SetModel requires provider and model_id" do
    assert_raise ArgumentError, fn -> struct!(Command.SetModel, %{}) end
    cmd = %Command.SetModel{provider: "anthropic", model_id: "claude-sonnet"}
    assert cmd.provider == "anthropic"
    assert cmd.model_id == "claude-sonnet"
  end

  test "Abort has no required fields" do
    cmd = %Command.Abort{}
    assert cmd.id == nil
  end

  test "Bash requires shell_command field" do
    assert_raise ArgumentError, fn -> struct!(Command.Bash, %{}) end
    cmd = %Command.Bash{shell_command: "mix test"}
    assert cmd.shell_command == "mix test"
  end

  test "RespondUI requires request_id and response" do
    assert_raise ArgumentError, fn -> struct!(Command.RespondUI, %{}) end
    cmd = %Command.RespondUI{request_id: "ui-1", response: %{value: "yes"}}
    assert cmd.request_id == "ui-1"
  end
end
