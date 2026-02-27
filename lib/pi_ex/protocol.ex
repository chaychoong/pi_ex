defmodule PiEx.Protocol do
  @moduledoc "Pure functions for encoding commands and decoding events."

  alias PiEx.Command
  alias PiEx.Event
  alias PiEx.Response

  @doc "Encode a command struct to a JSON string for Pi's stdin."
  @spec encode(struct()) :: String.t()
  def encode(%Command.RespondUI{} = cmd) do
    # RespondUI has a special wire format - it's an extension_ui_response.
    # Protocol fields are merged last so user-provided response cannot overwrite them.
    cmd.response
    |> Map.merge(%{"type" => "extension_ui_response", "id" => cmd.request_id})
    |> JSON.encode!()
  end

  def encode(%Command.Bash{} = cmd) do
    # Bash command uses "command" key for the shell string in Pi's wire format,
    # but we also need "type" to identify this as a bash command.
    map = %{"type" => "bash", "command" => cmd.shell_command}
    map = if cmd.id, do: Map.put(map, "id", cmd.id), else: map
    JSON.encode!(map)
  end

  def encode(%{__struct__: module} = cmd) do
    case Module.split(module) do
      ["PiEx", "Command" | _] ->
        :ok

      _ ->
        raise ArgumentError,
              "PiEx.Protocol.encode/1 only accepts PiEx.Command.* structs, got: #{inspect(module)}"
    end

    command_name = command_name(module)

    cmd
    |> Map.from_struct()
    |> Map.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new(fn {k, v} -> {to_camel(Atom.to_string(k)), convert_value(v)} end)
    |> Map.put("type", command_name)
    |> JSON.encode!()
  end

  # Derive command name from module name. RespondUI -> "respond_ui" is handled
  # by Macro.underscore ("RespondUI" -> "respond_ui"), but if any future module
  # needs a special mapping, add an explicit clause here.
  defp command_name(module) do
    module |> Module.split() |> List.last() |> Macro.underscore()
  end

  defp to_camel(key) do
    key
    |> String.split("_")
    |> then(fn [first | rest] -> [first | Enum.map(rest, &String.capitalize/1)] end)
    |> Enum.join()
  end

  defp convert_value(list) when is_list(list), do: Enum.map(list, &convert_map_keys/1)
  defp convert_value(value), do: value

  defp convert_map_keys(%{} = map) do
    Map.new(map, fn {k, v} ->
      key = if is_atom(k), do: to_camel(Atom.to_string(k)), else: to_camel(k)
      {key, v}
    end)
  end

  defp convert_map_keys(value), do: value

  # --- Decoding ---

  @ui_methods %{
    "select" => :select,
    "confirm" => :confirm,
    "input" => :input,
    "editor" => :editor,
    "notify" => :notify,
    "setStatus" => :set_status,
    "setWidget" => :set_widget,
    "setTitle" => :set_title,
    "set_editor_text" => :set_editor_text
  }

  @message_types %{
    "start" => :start,
    "text_start" => :text_start,
    "text_delta" => :text_delta,
    "text_end" => :text_end,
    "thinking_start" => :thinking_start,
    "thinking_delta" => :thinking_delta,
    "thinking_end" => :thinking_end,
    "toolcall_start" => :toolcall_start,
    "toolcall_delta" => :toolcall_delta,
    "toolcall_end" => :toolcall_end,
    "done" => :done,
    "error" => :error
  }

  @doc "Decode a JSON line from Pi's stdout into a tagged tuple."
  @spec decode_line(String.t()) ::
          {:response, String.t() | nil, Response.t()}
          | {:event, struct()}
          | {:ui_request, Event.UIRequest.t()}
          | {:error, term()}
  def decode_line(line) do
    case JSON.decode(line) do
      {:ok, data} -> decode_parsed(data)
      {:error, reason} -> {:error, reason}
    end
  end

  defp decode_parsed(%{"type" => "response"} = data) do
    response = %Response{
      command: data["command"],
      success: data["success"],
      error: data["error"],
      data: data["data"]
    }

    {:response, data["id"], response}
  end

  defp decode_parsed(%{"type" => "extension_ui_request"} = data) do
    event = %Event.UIRequest{
      id: data["id"],
      method: Map.get(@ui_methods, data["method"], :unknown),
      title: data["title"],
      options: data["options"],
      message: data["message"],
      placeholder: data["placeholder"],
      prefill: data["prefill"],
      timeout: data["timeout"]
    }

    {:ui_request, event}
  end

  defp decode_parsed(%{"type" => "agent_start"}), do: {:event, %Event.AgentStart{}}

  defp decode_parsed(%{"type" => "agent_end"} = data) do
    {:event, %Event.AgentEnd{messages: data["messages"]}}
  end

  defp decode_parsed(%{"type" => "message_start"}), do: {:event, %Event.MessageStart{}}
  defp decode_parsed(%{"type" => "message_end"}), do: {:event, %Event.MessageEnd{}}
  defp decode_parsed(%{"type" => "turn_start"}), do: {:event, %Event.TurnStart{}}
  defp decode_parsed(%{"type" => "turn_end"}), do: {:event, %Event.TurnEnd{}}

  defp decode_parsed(%{"type" => "message_update"} = data) do
    msg_event = data["assistantMessageEvent"] || %{}

    # Pi uses "delta" for text content in text_delta/thinking_delta events,
    # and "text" for toolcall_start. Fall back to "text" for compatibility.
    text = msg_event["delta"] || msg_event["text"]

    event = %Event.MessageUpdate{
      type: to_message_type(msg_event["type"] || "start"),
      text: text,
      reason: msg_event["reason"]
    }

    {:event, event}
  end

  defp decode_parsed(%{"type" => "tool_execution_start"} = data) do
    event = %Event.ToolExecutionStart{
      tool_call_id: data["toolCallId"],
      tool_name: data["toolName"],
      args: data["args"]
    }

    {:event, event}
  end

  defp decode_parsed(%{"type" => "tool_execution_update"} = data) do
    event = %Event.ToolExecutionUpdate{
      tool_call_id: data["toolCallId"],
      tool_name: data["toolName"],
      partial_result: data["partialResult"]
    }

    {:event, event}
  end

  defp decode_parsed(%{"type" => "tool_execution_end"} = data) do
    event = %Event.ToolExecutionEnd{
      tool_call_id: data["toolCallId"],
      tool_name: data["toolName"],
      result: data["result"],
      is_error: data["isError"]
    }

    {:event, event}
  end

  defp decode_parsed(%{"type" => "auto_compaction_start"}), do: {:event, %Event.AutoCompactionStart{}}
  defp decode_parsed(%{"type" => "auto_compaction_end"}), do: {:event, %Event.AutoCompactionEnd{}}
  defp decode_parsed(%{"type" => "auto_retry_start"}), do: {:event, %Event.AutoRetryStart{}}
  defp decode_parsed(%{"type" => "auto_retry_end"}), do: {:event, %Event.AutoRetryEnd{}}

  defp decode_parsed(%{"type" => "extension_error"} = data) do
    {:event, %Event.ExtensionError{message: data["message"], code: data["code"]}}
  end

  defp decode_parsed(%{"type" => type} = data) do
    {:event, %Event.Unknown{type: type, data: data}}
  end

  defp to_message_type(str), do: Map.get(@message_types, str, :unknown)
end
