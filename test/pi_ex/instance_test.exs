defmodule PiEx.InstanceTest do
  use ExUnit.Case, async: true

  # Helper: start an Instance with a fake port ref and writer function injected.
  # The Instance skips Port.open when :port is provided.
  # The writer sends {:port_write, data} to the test process for assertions.
  defp start_instance(opts \\ []) do
    test_pid = self()
    fake_port = Keyword.get_lazy(opts, :port, &make_ref/0)
    writer = Keyword.get(opts, :writer, fn _port, data -> send(test_pid, {:port_write, data}) end)
    opts = opts |> Keyword.put(:port, fake_port) |> Keyword.put(:writer, writer)
    {:ok, pid} = PiEx.Instance.start_link(opts)
    %{pid: pid, port: fake_port}
  end

  # Helper: simulate a line arriving from the port
  defp send_line(%{pid: pid, port: port}, json) do
    send(pid, {port, {:data, {:eol, json}}})
  end

  describe "start_link/1" do
    test "starts with a fake port" do
      %{pid: pid} = start_instance()
      assert Process.alive?(pid)
      GenServer.stop(pid)
    end

    test "infers id from atom name" do
      %{pid: pid} = start_instance(name: :test_agent_infer_id)
      state = :sys.get_state(pid)
      assert state.id == :test_agent_infer_id
      GenServer.stop(pid, :normal)
    end

    test "uses explicit id over name" do
      %{pid: pid} = start_instance(id: "custom_id")
      state = :sys.get_state(pid)
      assert state.id == "custom_id"
      GenServer.stop(pid, :normal)
    end
  end

  describe "event dispatch" do
    test "dispatches events to owner process by default" do
      ctx = start_instance()
      send_line(ctx, ~s|{"type":"agent_start"}|)

      assert_receive {:pi_event, _, %PiEx.Event.AgentStart{}}
      GenServer.stop(ctx.pid, :normal)
    end

    test "dispatches events via broadcast function when provided" do
      test_pid = self()

      broadcast = fn id, event ->
        send(test_pid, {:broadcast, id, event})
      end

      ctx = start_instance(id: :my_agent, broadcast: broadcast)
      send_line(ctx, ~s|{"type":"agent_start"}|)

      assert_receive {:broadcast, :my_agent, %PiEx.Event.AgentStart{}}
      GenServer.stop(ctx.pid, :normal)
    end
  end

  # --- Task 8: Command Sending and Correlation ---

  describe "correlated commands" do
    test "get_state sends command and returns response when response arrives" do
      ctx = start_instance()

      task = Task.async(fn -> PiEx.Instance.get_state(ctx.pid) end)

      # Wait for the GenServer to process the call and park the caller
      assert_receive {:port_write, _}

      # Extract the pending call id from state to send a matching response
      state = :sys.get_state(ctx.pid)
      [{id, _from}] = Map.to_list(state.pending_calls)

      response =
        ~s|{"type":"response","command":"get_state","success":true,"id":"#{id}","data":{"isStreaming":false}}|

      send_line(ctx, response)

      assert {:ok, %PiEx.Response{success: true}} = Task.await(task)
      GenServer.stop(ctx.pid, :normal)
    end

    test "prompt writes command to port and returns :ok" do
      ctx = start_instance()
      assert :ok = PiEx.Instance.prompt(ctx.pid, "hello")
      assert_receive {:port_write, data}
      decoded = JSON.decode!(String.trim_trailing(data, "\n"))
      assert decoded["command"] == "prompt"
      assert decoded["message"] == "hello"
      GenServer.stop(ctx.pid, :normal)
    end
  end

  # --- Task 9: Line Buffering and Exit Handling ---

  describe "line buffering" do
    test "accumulates noeol chunks and decodes on eol" do
      ctx = start_instance()

      chunk1 = ~s|{"type":"agent|
      chunk2 = ~s|_start"}|

      send(ctx.pid, {ctx.port, {:data, {:noeol, chunk1}}})
      refute_receive {:pi_event, _, _}, 50

      send(ctx.pid, {ctx.port, {:data, {:eol, chunk2}}})
      assert_receive {:pi_event, _, %PiEx.Event.AgentStart{}}

      GenServer.stop(ctx.pid, :normal)
    end
  end

  describe "exit handling" do
    test "replies error to pending calls on exit" do
      ctx = start_instance()

      task = Task.async(fn -> PiEx.Instance.get_state(ctx.pid) end)

      # Wait for the command to be written
      assert_receive {:port_write, _}

      send(ctx.pid, {ctx.port, {:exit_status, 1}})

      assert {:error, {:pi_exited, 1}} = Task.await(task)
    end

    test "dispatches Exited event on exit" do
      ctx = start_instance()
      send(ctx.pid, {ctx.port, {:exit_status, 0}})

      assert_receive {:pi_event, _, %PiEx.Event.Exited{code: 0}}
    end
  end

  # --- Task 10: Extension UI Protocol ---

  describe "extension UI protocol" do
    test "dispatches UIRequest event and parks timer" do
      ctx = start_instance()

      json =
        ~s|{"type":"extension_ui_request","id":"ui-1","method":"select","title":"Pick","options":["a","b"]}|

      send_line(ctx, json)

      assert_receive {:pi_event, _, %PiEx.Event.UIRequest{id: "ui-1", method: :select}}

      state = :sys.get_state(ctx.pid)
      assert Map.has_key?(state.pending_ui, "ui-1")

      GenServer.stop(ctx.pid, :normal)
    end

    test "respond_ui clears timer and writes to port" do
      ctx = start_instance()

      json =
        ~s|{"type":"extension_ui_request","id":"ui-1","method":"select","title":"Pick","options":["a","b"]}|

      send_line(ctx, json)
      assert_receive {:pi_event, _, %PiEx.Event.UIRequest{}}

      PiEx.Instance.respond_ui(ctx.pid, "ui-1", %{value: "a"})

      assert_receive {:port_write, _}

      state = :sys.get_state(ctx.pid)
      refute Map.has_key?(state.pending_ui, "ui-1")

      GenServer.stop(ctx.pid, :normal)
    end

    test "auto-cancels UI request on timeout" do
      ctx = start_instance(ui_timeout: 100)

      json =
        ~s|{"type":"extension_ui_request","id":"ui-1","method":"select","title":"Pick","options":["a"]}|

      send_line(ctx, json)
      assert_receive {:pi_event, _, %PiEx.Event.UIRequest{}}

      # Wait for the auto-cancel response to be written to port
      assert_receive {:port_write, _}, 500

      state = :sys.get_state(ctx.pid)
      refute Map.has_key?(state.pending_ui, "ui-1")

      GenServer.stop(ctx.pid, :normal)
    end
  end

  # --- Task 11: Streaming Behavior Guard ---

  describe "streaming guard" do
    test "rejects prompt while streaming" do
      ctx = start_instance()

      # First prompt succeeds
      assert :ok = PiEx.Instance.prompt(ctx.pid, "first")
      assert_receive {:port_write, _}

      # Simulate Pi starting to stream
      send_line(ctx, ~s|{"type":"agent_start"}|)
      assert_receive {:pi_event, _, %PiEx.Event.AgentStart{}}

      # Second prompt should be rejected
      assert {:error, :already_streaming} = PiEx.Instance.prompt(ctx.pid, "second")

      GenServer.stop(ctx.pid, :normal)
    end

    test "steer writes to port regardless of streaming state" do
      ctx = start_instance()

      assert :ok = PiEx.Instance.steer(ctx.pid, "focus on tests")
      assert_receive {:port_write, _}

      GenServer.stop(ctx.pid, :normal)
    end

    test "allows prompt after streaming ends" do
      ctx = start_instance()

      assert :ok = PiEx.Instance.prompt(ctx.pid, "first")
      assert_receive {:port_write, _}

      send_line(ctx, ~s|{"type":"agent_start"}|)
      send_line(ctx, ~s|{"type":"agent_end","messages":[]}|)
      assert_receive {:pi_event, _, %PiEx.Event.AgentEnd{}}

      assert :ok = PiEx.Instance.prompt(ctx.pid, "second")
      assert_receive {:port_write, _}

      GenServer.stop(ctx.pid, :normal)
    end
  end
end
