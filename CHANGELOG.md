# Changelog

## v0.1.0

Initial release.

- GenServer-based instance management via `PiEx.Instance`
- Full command set for the Pi RPC protocol (prompt, steer, follow-up, model/session management, and more)
- Streaming event parsing with typed structs for all Pi event types
- `PiEx.Delta` accumulator for collecting streamed responses
- Correlated request/response support for commands that return data
- Zero runtime dependencies - uses only Elixir 1.18+ built-in `JSON` module
