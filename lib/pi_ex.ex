defmodule PiEx do
  @moduledoc """
  Elixir client for the Pi coding agent RPC protocol.

  Spawns a `pi --mode rpc` process and communicates over JSON-over-stdin/stdout.
  Events are delivered to the calling process as `{:pi_event, id, event}` messages.

  ## Quick start

      {:ok, pid} = PiEx.Instance.start_link([])

      :ok = PiEx.prompt(pid, "Hello!")

      receive do
        {:pi_event, _, %PiEx.Event.MessageUpdate{type: :text_delta, text: text}} ->
          IO.write(text)
      end

  See `PiEx.Instance` for start options and `PiEx.Delta` for accumulating streamed
  responses.
  """

  @doc "Send a new prompt. Returns `{:error, :already_streaming}` if a response is in progress."
  @spec prompt(GenServer.server(), String.t(), keyword()) :: :ok | {:error, :already_streaming}
  defdelegate prompt(server, message, opts \\ []), to: PiEx.Instance

  @doc "Inject a steering message into the current conversation."
  @spec steer(GenServer.server(), String.t(), keyword()) :: :ok
  defdelegate steer(server, message, opts \\ []), to: PiEx.Instance

  @doc "Send a follow-up message."
  @spec follow_up(GenServer.server(), String.t(), keyword()) :: :ok
  defdelegate follow_up(server, message, opts \\ []), to: PiEx.Instance

  @doc "Abort the current streaming response."
  @spec abort(GenServer.server()) :: :ok
  defdelegate abort(server), to: PiEx.Instance

  @doc "Query Pi's current state. Blocks until Pi responds."
  @spec get_state(GenServer.server()) :: {:ok, PiEx.Response.t()} | {:error, term()}
  defdelegate get_state(server), to: PiEx.Instance

  @doc "Retrieve the conversation message history. Blocks until Pi responds."
  @spec get_messages(GenServer.server()) :: {:ok, PiEx.Response.t()} | {:error, term()}
  defdelegate get_messages(server), to: PiEx.Instance

  @doc "Switch the model provider and model ID."
  @spec set_model(GenServer.server(), String.t(), String.t()) :: {:ok, PiEx.Response.t()} | {:error, term()}
  defdelegate set_model(server, provider, model_id), to: PiEx.Instance

  @doc "Get session statistics (token usage, costs, etc.). Blocks until Pi responds."
  @spec get_session_stats(GenServer.server()) :: {:ok, PiEx.Response.t()} | {:error, term()}
  defdelegate get_session_stats(server), to: PiEx.Instance

  @doc "Execute a shell command via Pi. Blocks until Pi responds."
  @spec bash(GenServer.server(), String.t()) :: {:ok, PiEx.Response.t()} | {:error, term()}
  defdelegate bash(server, command), to: PiEx.Instance

  @doc "Respond to a UI request from Pi (select, confirm, input, etc.)."
  @spec respond_ui(GenServer.server(), String.t(), map()) :: :ok
  defdelegate respond_ui(server, request_id, response), to: PiEx.Instance
end
