defmodule PiEx.TestFixtures.CommandShapeMatrix do
  @moduledoc false

  alias PiEx.Command

  @type command_case :: %{
          name: String.t(),
          module: module(),
          minimal: struct(),
          expected_minimal: map(),
          full: struct(),
          expected_full: map(),
          forbidden_keys: [String.t()]
        }

  @spec cases() :: [command_case()]
  def cases do
    [
      %{
        name: "prompt",
        module: Command.Prompt,
        minimal: %Command.Prompt{message: "hello"},
        expected_minimal: %{"type" => "prompt", "message" => "hello"},
        full: %Command.Prompt{
          id: "req-prompt",
          message: "describe",
          images: [%{data: "base64", mime_type: "image/png"}]
        },
        expected_full: %{
          "type" => "prompt",
          "id" => "req-prompt",
          "message" => "describe",
          "images" => [%{"data" => "base64", "mimeType" => "image/png"}]
        },
        forbidden_keys: ["model_id", "mime_type", "request_id", "shell_command"]
      },
      %{
        name: "steer",
        module: Command.Steer,
        minimal: %Command.Steer{message: "focus"},
        expected_minimal: %{"type" => "steer", "message" => "focus"},
        full: %Command.Steer{id: "req-steer", message: "focus", images: [%{data: "x", mime_type: "image/png"}]},
        expected_full: %{
          "type" => "steer",
          "id" => "req-steer",
          "message" => "focus",
          "images" => [%{"data" => "x", "mimeType" => "image/png"}]
        },
        forbidden_keys: ["mime_type", "request_id", "shell_command"]
      },
      %{
        name: "follow_up",
        module: Command.FollowUp,
        minimal: %Command.FollowUp{message: "continue"},
        expected_minimal: %{"type" => "follow_up", "message" => "continue"},
        full: %Command.FollowUp{id: "req-follow-up", message: "continue", images: [%{data: "x", mime_type: "image/jpeg"}]},
        expected_full: %{
          "type" => "follow_up",
          "id" => "req-follow-up",
          "message" => "continue",
          "images" => [%{"data" => "x", "mimeType" => "image/jpeg"}]
        },
        forbidden_keys: ["mime_type", "request_id", "shell_command"]
      },
      %{
        name: "abort",
        module: Command.Abort,
        minimal: %Command.Abort{},
        expected_minimal: %{"type" => "abort"},
        full: %Command.Abort{id: "req-abort"},
        expected_full: %{"type" => "abort", "id" => "req-abort"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "get_state",
        module: Command.GetState,
        minimal: %Command.GetState{},
        expected_minimal: %{"type" => "get_state"},
        full: %Command.GetState{id: "req-state"},
        expected_full: %{"type" => "get_state", "id" => "req-state"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "get_messages",
        module: Command.GetMessages,
        minimal: %Command.GetMessages{},
        expected_minimal: %{"type" => "get_messages"},
        full: %Command.GetMessages{id: "req-messages"},
        expected_full: %{"type" => "get_messages", "id" => "req-messages"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_model",
        module: Command.SetModel,
        minimal: %Command.SetModel{provider: "openai-codex", model_id: "gpt-5.3-codex"},
        expected_minimal: %{"type" => "set_model", "provider" => "openai-codex", "modelId" => "gpt-5.3-codex"},
        full: %Command.SetModel{id: "req-model", provider: "anthropic", model_id: "claude-sonnet"},
        expected_full: %{
          "type" => "set_model",
          "id" => "req-model",
          "provider" => "anthropic",
          "modelId" => "claude-sonnet"
        },
        forbidden_keys: ["model_id", "request_id", "shell_command"]
      },
      %{
        name: "cycle_model",
        module: Command.CycleModel,
        minimal: %Command.CycleModel{},
        expected_minimal: %{"type" => "cycle_model"},
        full: %Command.CycleModel{id: "req-cycle-model"},
        expected_full: %{"type" => "cycle_model", "id" => "req-cycle-model"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "get_available_models",
        module: Command.GetAvailableModels,
        minimal: %Command.GetAvailableModels{},
        expected_minimal: %{"type" => "get_available_models"},
        full: %Command.GetAvailableModels{id: "req-models"},
        expected_full: %{"type" => "get_available_models", "id" => "req-models"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_thinking_level",
        module: Command.SetThinkingLevel,
        minimal: %Command.SetThinkingLevel{level: "medium"},
        expected_minimal: %{"type" => "set_thinking_level", "level" => "medium"},
        full: %Command.SetThinkingLevel{id: "req-thinking", level: "high"},
        expected_full: %{"type" => "set_thinking_level", "id" => "req-thinking", "level" => "high"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "cycle_thinking_level",
        module: Command.CycleThinkingLevel,
        minimal: %Command.CycleThinkingLevel{},
        expected_minimal: %{"type" => "cycle_thinking_level"},
        full: %Command.CycleThinkingLevel{id: "req-cycle-thinking"},
        expected_full: %{"type" => "cycle_thinking_level", "id" => "req-cycle-thinking"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_steering_mode",
        module: Command.SetSteeringMode,
        minimal: %Command.SetSteeringMode{mode: "one-at-a-time"},
        expected_minimal: %{"type" => "set_steering_mode", "mode" => "one-at-a-time"},
        full: %Command.SetSteeringMode{id: "req-steering-mode", mode: "parallel"},
        expected_full: %{"type" => "set_steering_mode", "id" => "req-steering-mode", "mode" => "parallel"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_follow_up_mode",
        module: Command.SetFollowUpMode,
        minimal: %Command.SetFollowUpMode{mode: "one-at-a-time"},
        expected_minimal: %{"type" => "set_follow_up_mode", "mode" => "one-at-a-time"},
        full: %Command.SetFollowUpMode{id: "req-follow-up-mode", mode: "always"},
        expected_full: %{"type" => "set_follow_up_mode", "id" => "req-follow-up-mode", "mode" => "always"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "compact",
        module: Command.Compact,
        minimal: %Command.Compact{},
        expected_minimal: %{"type" => "compact"},
        full: %Command.Compact{id: "req-compact", custom_instructions: "keep critical context"},
        expected_full: %{"type" => "compact", "id" => "req-compact", "customInstructions" => "keep critical context"},
        forbidden_keys: ["custom_instructions", "request_id", "shell_command"]
      },
      %{
        name: "set_auto_compaction",
        module: Command.SetAutoCompaction,
        minimal: %Command.SetAutoCompaction{enabled: true},
        expected_minimal: %{"type" => "set_auto_compaction", "enabled" => true},
        full: %Command.SetAutoCompaction{id: "req-auto-compaction", enabled: false},
        expected_full: %{"type" => "set_auto_compaction", "id" => "req-auto-compaction", "enabled" => false},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_auto_retry",
        module: Command.SetAutoRetry,
        minimal: %Command.SetAutoRetry{enabled: true},
        expected_minimal: %{"type" => "set_auto_retry", "enabled" => true},
        full: %Command.SetAutoRetry{id: "req-auto-retry", enabled: false},
        expected_full: %{"type" => "set_auto_retry", "id" => "req-auto-retry", "enabled" => false},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "abort_retry",
        module: Command.AbortRetry,
        minimal: %Command.AbortRetry{},
        expected_minimal: %{"type" => "abort_retry"},
        full: %Command.AbortRetry{id: "req-abort-retry"},
        expected_full: %{"type" => "abort_retry", "id" => "req-abort-retry"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "bash",
        module: Command.Bash,
        minimal: %Command.Bash{shell_command: "echo hi"},
        expected_minimal: %{"type" => "bash", "command" => "echo hi"},
        full: %Command.Bash{id: "req-bash", shell_command: "mix test"},
        expected_full: %{"type" => "bash", "id" => "req-bash", "command" => "mix test"},
        forbidden_keys: ["shell_command", "request_id"]
      },
      %{
        name: "abort_bash",
        module: Command.AbortBash,
        minimal: %Command.AbortBash{},
        expected_minimal: %{"type" => "abort_bash"},
        full: %Command.AbortBash{id: "req-abort-bash"},
        expected_full: %{"type" => "abort_bash", "id" => "req-abort-bash"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "new_session",
        module: Command.NewSession,
        minimal: %Command.NewSession{},
        expected_minimal: %{"type" => "new_session"},
        full: %Command.NewSession{id: "req-new-session", parent_session: "session-1"},
        expected_full: %{"type" => "new_session", "id" => "req-new-session", "parentSession" => "session-1"},
        forbidden_keys: ["parent_session", "request_id", "shell_command"]
      },
      %{
        name: "switch_session",
        module: Command.SwitchSession,
        minimal: %Command.SwitchSession{session_path: "/tmp/session.jsonl"},
        expected_minimal: %{"type" => "switch_session", "sessionPath" => "/tmp/session.jsonl"},
        full: %Command.SwitchSession{id: "req-switch-session", session_path: "/tmp/another.jsonl"},
        expected_full: %{"type" => "switch_session", "id" => "req-switch-session", "sessionPath" => "/tmp/another.jsonl"},
        forbidden_keys: ["session_path", "request_id", "shell_command"]
      },
      %{
        name: "fork",
        module: Command.Fork,
        minimal: %Command.Fork{entry_id: "entry-1"},
        expected_minimal: %{"type" => "fork", "entryId" => "entry-1"},
        full: %Command.Fork{id: "req-fork", entry_id: "entry-2"},
        expected_full: %{"type" => "fork", "id" => "req-fork", "entryId" => "entry-2"},
        forbidden_keys: ["entry_id", "request_id", "shell_command"]
      },
      %{
        name: "get_fork_messages",
        module: Command.GetForkMessages,
        minimal: %Command.GetForkMessages{},
        expected_minimal: %{"type" => "get_fork_messages"},
        full: %Command.GetForkMessages{id: "req-fork-messages"},
        expected_full: %{"type" => "get_fork_messages", "id" => "req-fork-messages"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "get_last_assistant_text",
        module: Command.GetLastAssistantText,
        minimal: %Command.GetLastAssistantText{},
        expected_minimal: %{"type" => "get_last_assistant_text"},
        full: %Command.GetLastAssistantText{id: "req-last-text"},
        expected_full: %{"type" => "get_last_assistant_text", "id" => "req-last-text"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "get_session_stats",
        module: Command.GetSessionStats,
        minimal: %Command.GetSessionStats{},
        expected_minimal: %{"type" => "get_session_stats"},
        full: %Command.GetSessionStats{id: "req-session-stats"},
        expected_full: %{"type" => "get_session_stats", "id" => "req-session-stats"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "set_session_name",
        module: Command.SetSessionName,
        minimal: %Command.SetSessionName{name: "incident triage"},
        expected_minimal: %{"type" => "set_session_name", "name" => "incident triage"},
        full: %Command.SetSessionName{id: "req-session-name", name: "bughunt"},
        expected_full: %{"type" => "set_session_name", "id" => "req-session-name", "name" => "bughunt"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "export_html",
        module: Command.ExportHtml,
        minimal: %Command.ExportHtml{output_path: "/tmp/session.html"},
        expected_minimal: %{"type" => "export_html", "outputPath" => "/tmp/session.html"},
        full: %Command.ExportHtml{id: "req-export", output_path: "/tmp/another.html"},
        expected_full: %{"type" => "export_html", "id" => "req-export", "outputPath" => "/tmp/another.html"},
        forbidden_keys: ["output_path", "request_id", "shell_command"]
      },
      %{
        name: "get_commands",
        module: Command.GetCommands,
        minimal: %Command.GetCommands{},
        expected_minimal: %{"type" => "get_commands"},
        full: %Command.GetCommands{id: "req-get-commands"},
        expected_full: %{"type" => "get_commands", "id" => "req-get-commands"},
        forbidden_keys: ["request_id", "shell_command"]
      },
      %{
        name: "respond_ui",
        module: Command.RespondUI,
        minimal: %Command.RespondUI{request_id: "ui-1", response: %{value: "yes"}},
        expected_minimal: %{"type" => "extension_ui_response", "id" => "ui-1", "value" => "yes"},
        full: %Command.RespondUI{
          id: "ignored-id",
          request_id: "ui-2",
          response: %{"id" => "user-id", "type" => "user-type", "value" => "approved"}
        },
        expected_full: %{"type" => "extension_ui_response", "id" => "ui-2", "value" => "approved"},
        forbidden_keys: ["request_id", "requestId", "response", "shell_command"]
      }
    ]
  end

  @spec covered_modules() :: [module()]
  def covered_modules do
    cases() |> Enum.map(& &1.module) |> Enum.sort()
  end
end
