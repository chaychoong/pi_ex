# Interactive multi-turn chat with Pi.
#
#   elixir examples/chat.exs
#
# Type messages at the prompt. Ctrl-C to exit.
#
# Set PI_PATH to use a different binary (default: "pi"):
#
#   PI_PATH=/path/to/bin elixir examples/chat.exs

Mix.install([{:pi_ex, path: Path.expand("..", __DIR__)}])

pi_path = System.get_env("PI_PATH", "pi")

IO.puts("Starting #{pi_path}...")
{:ok, pid} = PiEx.Instance.start_link(pi_path: pi_path)
IO.puts("Ready. Type your messages below.\n")

defmodule Chat do
  alias PiEx.Event.{AgentEnd, MessageUpdate}

  def loop(pid) do
    case IO.gets("you> ") do
      :eof ->
        :ok

      line ->
        message = String.trim(line)

        if message != "" do
          :ok = PiEx.prompt(pid, message)
          collect_response()
        end

        loop(pid)
    end
  end

  defp collect_response do
    receive do
      {:pi_event, _, %MessageUpdate{type: :thinking_start}} ->
        IO.write(IO.ANSI.faint() <> "\n--- thinking ---\n")
        collect_response()

      {:pi_event, _, %MessageUpdate{type: :thinking_delta, text: text}} ->
        IO.write(text)
        collect_response()

      {:pi_event, _, %MessageUpdate{type: :thinking_end}} ->
        IO.write("\n--- end thinking ---" <> IO.ANSI.reset() <> "\n\n")
        collect_response()

      {:pi_event, _, %MessageUpdate{type: :text_start}} ->
        IO.write("pi> ")
        collect_response()

      {:pi_event, _, %MessageUpdate{type: :text_delta, text: text}} ->
        IO.write(text)
        collect_response()

      {:pi_event, _, %AgentEnd{}} ->
        IO.puts("\n")

      {:pi_event, _, _} ->
        collect_response()
    after
      60_000 ->
        IO.puts("\n[timed out]")
    end
  end
end

Chat.loop(pid)
GenServer.stop(pid, :normal)
