defmodule PiEx.IntegrationTest do
  use ExUnit.Case

  alias PiEx.Event.MessageUpdate

  @moduletag :integration

  @fake_pi Path.expand("../support/fake_pi.sh", __DIR__)

  test "full prompt lifecycle" do
    {:ok, pid} = PiEx.Instance.start_link(pi_path: @fake_pi)

    PiEx.prompt(pid, "hello")

    assert_receive {:pi_event, _, %PiEx.Event.AgentStart{}}, 5000

    assert_receive {:pi_event, _, %MessageUpdate{type: :text_delta, text: "Hello from fake pi"}},
                   5000

    assert_receive {:pi_event, _, %PiEx.Event.AgentEnd{}}, 5000

    GenServer.stop(pid, :normal)
  end

  test "get_state returns response" do
    {:ok, pid} = PiEx.Instance.start_link(pi_path: @fake_pi)

    assert {:ok, %PiEx.Response{success: true, data: data}} = PiEx.get_state(pid)
    assert data["isStreaming"] == false

    GenServer.stop(pid, :normal)
  end

  test "delta accumulation over full stream" do
    {:ok, pid} = PiEx.Instance.start_link(pi_path: @fake_pi)
    PiEx.prompt(pid, "hello")

    delta = collect_delta(PiEx.Delta.new())
    assert PiEx.Delta.text(delta) == "Hello from fake pi"
    assert PiEx.Delta.done?(delta)

    GenServer.stop(pid, :normal)
  end

  defp collect_delta(delta) do
    receive do
      {:pi_event, _, %MessageUpdate{} = event} ->
        delta = PiEx.Delta.apply_event(delta, event)
        if event.type == :done, do: delta, else: collect_delta(delta)

      {:pi_event, _, _} ->
        collect_delta(delta)
    after
      5000 -> delta
    end
  end
end
