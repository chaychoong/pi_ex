defmodule PiExTest do
  use ExUnit.Case, async: true

  test "PiEx.prompt/2 delegates to Instance" do
    test_pid = self()
    writer = fn _port, data -> send(test_pid, {:port_write, data}) end
    {:ok, pid} = PiEx.Instance.start_link(port: make_ref(), writer: writer)
    assert :ok = PiEx.prompt(pid, "hello")
    assert_receive {:port_write, _}
    GenServer.stop(pid, :normal)
  end
end
