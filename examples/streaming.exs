# Stream a Pi response to the terminal in real time.
#
#   elixir examples/streaming.exs "Write a haiku about Elixir"
#
# Set PI_PATH to use a different binary (default: "pi"):
#
#   PI_PATH=/path/to/bin elixir examples/streaming.exs

Mix.install([{:pi_ex, path: Path.expand("..", __DIR__)}])

message = List.first(System.argv()) || "Write a short poem about Elixir"

pi_path = System.get_env("PI_PATH", "pi")

IO.puts("Starting #{pi_path}...")
{:ok, pid} = PiEx.Instance.start_link(pi_path: pi_path)

IO.puts("Prompt: #{message}\n")
:ok = PiEx.prompt(pid, message)

defmodule StreamPrinter do
  alias PiEx.Event.{AgentEnd, MessageUpdate}

  def loop do
    receive do
      {:pi_event, _, %MessageUpdate{type: :thinking_start}} ->
        IO.write(IO.ANSI.faint() <> "--- thinking ---\n")
        loop()

      {:pi_event, _, %MessageUpdate{type: :thinking_delta, text: text}} ->
        IO.write(text)
        loop()

      {:pi_event, _, %MessageUpdate{type: :thinking_end}} ->
        IO.write("\n--- end thinking ---" <> IO.ANSI.reset() <> "\n\n")
        loop()

      {:pi_event, _, %MessageUpdate{type: :text_delta, text: text}} ->
        IO.write(text)
        loop()

      {:pi_event, _, %AgentEnd{}} ->
        IO.puts("")

      {:pi_event, _, _} ->
        loop()
    after
      30_000 ->
        IO.puts("\n[timed out waiting for response]")
    end
  end
end

StreamPrinter.loop()
GenServer.stop(pid, :normal)
