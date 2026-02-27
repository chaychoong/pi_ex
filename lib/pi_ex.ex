defmodule PiEx do
  @moduledoc "Elixir client for the Pi coding agent RPC protocol."

  defdelegate prompt(server, message, opts \\ []), to: PiEx.Instance
  defdelegate steer(server, message, opts \\ []), to: PiEx.Instance
  defdelegate follow_up(server, message, opts \\ []), to: PiEx.Instance
  defdelegate abort(server), to: PiEx.Instance
  defdelegate get_state(server), to: PiEx.Instance
  defdelegate get_messages(server), to: PiEx.Instance
  defdelegate set_model(server, provider, model_id), to: PiEx.Instance
  defdelegate get_session_stats(server), to: PiEx.Instance
  defdelegate bash(server, command), to: PiEx.Instance
  defdelegate respond_ui(server, request_id, response), to: PiEx.Instance
end
