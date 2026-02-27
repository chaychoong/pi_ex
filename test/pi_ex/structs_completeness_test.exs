defmodule PiEx.StructsCompletenessTest do
  use ExUnit.Case, async: true

  @all_commands [
    PiEx.Command.Prompt,
    PiEx.Command.Steer,
    PiEx.Command.FollowUp,
    PiEx.Command.Abort,
    PiEx.Command.GetState,
    PiEx.Command.GetMessages,
    PiEx.Command.SetModel,
    PiEx.Command.CycleModel,
    PiEx.Command.GetAvailableModels,
    PiEx.Command.SetThinkingLevel,
    PiEx.Command.CycleThinkingLevel,
    PiEx.Command.SetSteeringMode,
    PiEx.Command.SetFollowUpMode,
    PiEx.Command.Compact,
    PiEx.Command.SetAutoCompaction,
    PiEx.Command.SetAutoRetry,
    PiEx.Command.AbortRetry,
    PiEx.Command.Bash,
    PiEx.Command.AbortBash,
    PiEx.Command.NewSession,
    PiEx.Command.SwitchSession,
    PiEx.Command.Fork,
    PiEx.Command.GetForkMessages,
    PiEx.Command.GetLastAssistantText,
    PiEx.Command.GetSessionStats,
    PiEx.Command.SetSessionName,
    PiEx.Command.ExportHtml,
    PiEx.Command.GetCommands,
    PiEx.Command.RespondUI
  ]

  @all_events [
    PiEx.Event.AgentStart,
    PiEx.Event.AgentEnd,
    PiEx.Event.TurnStart,
    PiEx.Event.TurnEnd,
    PiEx.Event.MessageStart,
    PiEx.Event.MessageUpdate,
    PiEx.Event.MessageEnd,
    PiEx.Event.ToolExecutionStart,
    PiEx.Event.ToolExecutionUpdate,
    PiEx.Event.ToolExecutionEnd,
    PiEx.Event.AutoCompactionStart,
    PiEx.Event.AutoCompactionEnd,
    PiEx.Event.AutoRetryStart,
    PiEx.Event.AutoRetryEnd,
    PiEx.Event.ExtensionError,
    PiEx.Event.UIRequest,
    PiEx.Event.Exited,
    PiEx.Event.Unknown
  ]

  test "all command modules define a struct" do
    for mod <- @all_commands do
      Code.ensure_loaded!(mod)

      assert function_exported?(mod, :__struct__, 0),
             "#{inspect(mod)} does not define a struct"
    end
  end

  test "all event modules define a struct" do
    for mod <- @all_events do
      Code.ensure_loaded!(mod)

      assert function_exported?(mod, :__struct__, 0),
             "#{inspect(mod)} does not define a struct"
    end
  end

  test "all commands have an :id field" do
    for mod <- @all_commands, mod != PiEx.Command.RespondUI do
      struct = struct(mod)

      assert Map.has_key?(struct, :id),
             "#{inspect(mod)} is missing :id field"
    end
  end
end
