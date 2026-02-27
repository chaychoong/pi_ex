# Send a single prompt to Pi and print the full response.
#
#   elixir examples/simple_prompt.exs "What is the factorial of 10?"
#
# Set PI_PATH to use a different binary (default: "pi"):
#
#   PI_PATH=/path/to/bin elixir examples/simple_prompt.exs
#
# If no argument is given, a default greeting is sent.

Mix.install([{:pi_ex, path: Path.expand("..", __DIR__)}])

message = List.first(System.argv()) || "Hello! Briefly introduce yourself."

pi_path = System.get_env("PI_PATH", "pi")

IO.puts("Starting #{pi_path}...")
{:ok, pid} = PiEx.Instance.start_link(pi_path: pi_path)

IO.puts("Prompt: #{message}\n")
:ok = PiEx.prompt(pid, message)

delta =
  Stream.repeatedly(fn ->
    receive do
      {:pi_event, _, event} -> event
    after
      30_000 -> :timeout
    end
  end)
  |> Enum.reduce_while(PiEx.Delta.new(), fn
    :timeout, delta ->
      {:halt, delta}

    event, delta ->
      delta = PiEx.Delta.apply_event(delta, event)
      if PiEx.Delta.done?(delta), do: {:halt, delta}, else: {:cont, delta}
  end)

IO.puts(PiEx.Delta.text(delta))

if PiEx.Delta.thinking(delta) != "" do
  IO.puts("\n--- Thinking ---")
  IO.puts(PiEx.Delta.thinking(delta))
end

GenServer.stop(pid, :normal)
