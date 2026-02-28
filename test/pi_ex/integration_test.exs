defmodule PiEx.IntegrationTest do
  use ExUnit.Case

  alias PiEx.Event.AgentEnd

  @moduletag :integration
  setup do
    cond do
      is_nil(System.find_executable("pi")) ->
        {:skip, "pi executable is not available on PATH"}

      true ->
        {:ok, pid} = PiEx.Instance.start_link([])

        on_exit(fn ->
          if Process.alive?(pid), do: GenServer.stop(pid, :normal)
        end)

        {:ok, pid: pid}
    end
  end

  test "get_state succeeds against a live pi instance", %{pid: pid} do
    assert {:ok, %PiEx.Response{success: true, data: data}} = PiEx.get_state(pid)
    assert is_map(data)
    assert data["isStreaming"] == false
  end

  test "get_messages returns a response envelope with messages list", %{pid: pid} do
    assert {:ok, %PiEx.Response{command: "get_messages", success: true, error: nil, data: data}} =
             PiEx.get_messages(pid)

    assert is_map(data)
    assert is_list(data["messages"])
  end

  test "get_session_stats returns a response envelope with token totals", %{pid: pid} do
    assert {:ok, %PiEx.Response{command: "get_session_stats", success: true, error: nil, data: data}} =
             PiEx.get_session_stats(pid)

    assert is_map(data)
    assert is_map(data["tokens"])
    assert is_number(data["tokens"]["total"])
    assert is_binary(data["sessionId"])
  end
  test "prompt stream reaches agent_end and returns requested token", %{pid: pid} do
    token = "PI_COMPAT_OK_#{System.unique_integer([:positive])}"

    prompt =
      "Reply with exactly #{token}. No punctuation, no markdown, no extra words, and no explanation."

    assert :ok = PiEx.prompt(pid, prompt)

    deadline_ms = System.monotonic_time(:millisecond) + 30_000
    delta = collect_until_agent_end(PiEx.Delta.new(), deadline_ms)

    assert PiEx.Delta.done?(delta)
    assert PiEx.Delta.text(delta) =~ token

    assert {:ok, %PiEx.Response{success: true, data: data}} = PiEx.get_state(pid)
    assert data["isStreaming"] == false
  end

  defp collect_until_agent_end(delta, deadline_ms) do
    remaining_ms = deadline_ms - System.monotonic_time(:millisecond)

    if remaining_ms <= 0 do
      flunk("timed out waiting for AgentEnd event from pi")
    end

    receive do
      {:pi_event, _, event} ->
        updated = PiEx.Delta.apply_event(delta, event)

        case event do
          %AgentEnd{} -> updated
          _ -> collect_until_agent_end(updated, deadline_ms)
        end
    after
      remaining_ms ->
        flunk("timed out waiting for AgentEnd event from pi")
    end
  end
end
