#!/usr/bin/env bash
# Pi RPC contract test double.
# Reads JSON commands from stdin, writes deterministic JSON events/responses to stdout.

while IFS= read -r line; do
  command=$(echo "$line" | jq -r '.type // ""')
  id=$(echo "$line" | jq -r '.id // ""')

  case "$command" in
    prompt)
      echo '{"type":"agent_start"}'
      echo '{"type":"turn_start"}'
      echo '{"type":"message_start"}'
      echo '{"type":"message_update","assistantMessageEvent":{"type":"text_start"}}'
      echo '{"type":"message_update","assistantMessageEvent":{"type":"text_delta","delta":"Hello from contract pi"}}'
      echo '{"type":"message_update","assistantMessageEvent":{"type":"text_end"}}'
      echo '{"type":"message_update","assistantMessageEvent":{"type":"done","reason":"stop"}}'
      echo '{"type":"message_end"}'
      echo '{"type":"turn_end"}'
      echo '{"type":"agent_end","messages":[]}'
      ;;
    get_state)
      echo "{\"type\":\"response\",\"command\":\"get_state\",\"success\":true,\"id\":\"$id\",\"data\":{\"isStreaming\":false}}"
      ;;
    *)
      echo "{\"type\":\"response\",\"command\":\"$command\",\"success\":true,\"id\":\"$id\",\"data\":{}}"
      ;;
  esac
done
