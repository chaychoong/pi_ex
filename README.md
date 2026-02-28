# PiEx

Elixir client for the [Pi](https://pi.dev/) coding agent RPC
protocol. Spawns a `pi --mode rpc` process and communicates over
JSON-over-stdin/stdout. Zero runtime dependencies - uses only Elixir 1.18+
built-in `JSON` module.

## Installation

Add `pi_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pi_ex, "~> 0.1.0"}
  ]
end
```

## Pi compatibility

`pi_ex` follows a **best-effort-latest** compatibility policy for the `pi` CLI.

- Last tracked `pi` version: `0.55.3`
- Last updated: `2026-02-28`

When validating against a newer `pi` release, update this section in the same change.

## Quick start

```elixir
# Start an instance (requires `pi` on PATH)
{:ok, pid} = PiEx.Instance.start_link([])

# Send a prompt
:ok = PiEx.prompt(pid, "Hello!")

# Receive streamed events
receive do
  {:pi_event, _, %PiEx.Event.MessageUpdate{type: :text_delta, text: text}} ->
    IO.write(text)
end
```

## Accumulating responses

Use `PiEx.Delta` to collect a full response from the event stream:

```elixir
delta = PiEx.Delta.new()

delta =
  receive do
    {:pi_event, _, event} -> PiEx.Delta.apply_event(delta, event)
  end

PiEx.Delta.text(delta)     # accumulated response text
PiEx.Delta.thinking(delta) # accumulated reasoning
PiEx.Delta.done?(delta)    # true when stream is complete
```

## Examples

Self-contained scripts under `examples/` can be run directly:

```bash
elixir examples/simple_prompt.exs "What is 2+2?"
elixir examples/streaming.exs "Write a haiku"
elixir examples/chat.exs

# Use a different binary
PI_PATH=/path/to/bin elixir examples/chat.exs
```

## License

MIT - see [LICENSE](LICENSE).
