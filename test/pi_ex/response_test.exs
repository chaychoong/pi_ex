defmodule PiEx.ResponseTest do
  use ExUnit.Case, async: true

  alias PiEx.Response

  test "creates a successful response" do
    resp = %Response{command: "get_state", success: true, data: %{"isStreaming" => false}}
    assert resp.success
    assert resp.command == "get_state"
    assert resp.data == %{"isStreaming" => false}
    assert resp.error == nil
  end

  test "creates an error response" do
    resp = %Response{command: "prompt", success: false, error: "already streaming"}
    refute resp.success
    assert resp.error == "already streaming"
    assert resp.data == nil
  end
end
