defmodule PiEx.ContractTest do
  use ExUnit.Case

  alias PiEx.Event.AgentEnd
  alias PiEx.Event.MessageUpdate
  alias PiEx.Response

  @moduletag :contract

  @stub_pi Path.expand("../support/stub_pi.sh", __DIR__)

  setup do
    {:ok, pid} = PiEx.Instance.start_link(pi_path: @stub_pi)

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid, :normal)
    end)

    {:ok, pid: pid}
  end

  test "full prompt lifecycle", %{pid: pid} do
    PiEx.prompt(pid, "hello")

    assert_receive {:pi_event, _, %PiEx.Event.AgentStart{}}, 5000

    assert_receive {:pi_event, _, %MessageUpdate{type: :text_delta, text: "Hello from contract pi"}},
                   5000

    assert_receive {:pi_event, _, %AgentEnd{}}, 5000
  end

  test "query APIs return expected response envelopes", %{pid: pid} do
    cases = [
      %{
        command: "get_state",
        call: fn -> PiEx.get_state(pid) end,
        validate_data: fn data ->
          assert data == %{"isStreaming" => false}
        end
      },
      %{
        command: "get_messages",
        call: fn -> PiEx.get_messages(pid) end,
        validate_data: fn data ->
          assert is_list(data["messages"])
          assert Enum.any?(data["messages"], fn message -> message["role"] == "assistant" end)
        end
      },
      %{
        command: "get_session_stats",
        call: fn -> PiEx.get_session_stats(pid) end,
        validate_data: fn data ->
          assert is_map(data["totals"])
          assert is_number(data["totals"]["inputTokens"])
          assert is_map(data["cost"])
          assert is_number(data["cost"]["usd"])
        end
      },
      %{
        command: "bash",
        call: fn -> PiEx.bash(pid, "echo hello") end,
        validate_data: fn data ->
          assert data["stdout"] == "hello"
          assert data["stderr"] == ""
          assert data["exitCode"] == 0
        end
      },
      %{
        command: "set_model",
        call: fn -> PiEx.set_model(pid, "openai-codex", "gpt-5.3-codex") end,
        validate_data: fn data ->
          assert data["provider"] == "openai-codex"
          assert data["modelId"] == "gpt-5.3-codex"
          assert data["applied"] == true
        end
      }
    ]

    for %{command: expected_command, call: call, validate_data: validate_data} <- cases do
      assert {:ok, %Response{command: ^expected_command, success: true, error: nil, data: data}} = call.()
      validate_data.(data)
    end
  end

  test "delta accumulation over full stream", %{pid: pid} do
    PiEx.prompt(pid, "hello")

    delta = collect_delta(PiEx.Delta.new())
    assert PiEx.Delta.text(delta) == "Hello from contract pi"
    assert PiEx.Delta.done?(delta)
  end

  defp collect_delta(delta) do
    receive do
      {:pi_event, _, %MessageUpdate{} = event} ->
        delta = PiEx.Delta.apply_event(delta, event)
        collect_delta(delta)

      {:pi_event, _, %AgentEnd{} = event} ->
        PiEx.Delta.apply_event(delta, event)

      {:pi_event, _, _} ->
        collect_delta(delta)
    after
      5000 -> delta
    end
  end
end