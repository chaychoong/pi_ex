defmodule PiEx.Instance do
  @moduledoc "GenServer that owns a Port to a pi --mode rpc process."
  use GenServer

  alias PiEx.Command.RespondUI
  alias PiEx.Protocol

  require Logger

  defmodule State do
    @moduledoc false
    @enforce_keys [:port, :id, :owner, :writer]
    defstruct [
      :port,
      :id,
      :owner,
      :broadcast,
      :writer,
      pending_calls: %{},
      pending_ui: %{},
      ui_timeout: 30_000,
      line_buffer: "",
      is_streaming: false
    ]
  end

  def child_spec(opts) do
    id = Keyword.get(opts, :id, Keyword.get(opts, :name, __MODULE__))
    %{id: id, start: {__MODULE__, :start_link, [opts]}, restart: :transient}
  end

  def start_link(opts) do
    # Pass :name through to init for id inference, and set owner to caller
    opts = Keyword.put_new(opts, :owner, self())
    {gen_opts, instance_opts} = Keyword.split(opts, [:name])
    name = Keyword.get(gen_opts, :name)
    instance_opts = if name, do: Keyword.put_new(instance_opts, :name, name), else: instance_opts
    GenServer.start_link(__MODULE__, instance_opts, gen_opts)
  end

  @impl true
  def init(opts) do
    owner = Keyword.fetch!(opts, :owner)

    {port, writer} =
      case Keyword.fetch(opts, :port) do
        {:ok, port} ->
          writer = Keyword.get(opts, :writer, fn _port, _data -> :ok end)
          {port, writer}

        :error ->
          pi_path = Keyword.get(opts, :pi_path, "pi")
          args = Keyword.get(opts, :args, ["--mode", "rpc"])

          executable =
            System.find_executable(pi_path) ||
              raise ArgumentError, "could not find executable: #{inspect(pi_path)}"

          port = Port.open({:spawn_executable, executable}, [:binary, {:line, 1_048_576}, {:args, args}, :exit_status])
          {port, &Port.command/2}
      end

    id =
      Keyword.get_lazy(opts, :id, fn ->
        Keyword.get(opts, :name, port)
      end)

    state = %State{
      port: port,
      id: id,
      owner: owner,
      writer: writer,
      broadcast: Keyword.get(opts, :broadcast),
      ui_timeout: Keyword.get(opts, :ui_timeout, 30_000)
    }

    {:ok, state}
  end

  # --- Public API ---

  def prompt(server, message, opts \\ []) do
    GenServer.call(server, {:prompt, message, opts})
  end

  def steer(server, message, opts \\ []) do
    GenServer.call(server, {:steer, message, opts})
  end

  def follow_up(server, message, opts \\ []) do
    GenServer.call(server, {:follow_up, message, opts})
  end

  def abort(server) do
    GenServer.cast(server, :abort)
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  def get_messages(server) do
    GenServer.call(server, :get_messages)
  end

  def set_model(server, provider, model_id) do
    GenServer.call(server, {:set_model, provider, model_id})
  end

  def get_session_stats(server) do
    GenServer.call(server, :get_session_stats)
  end

  def bash(server, command) do
    GenServer.call(server, {:bash, command})
  end

  def respond_ui(server, request_id, response) do
    GenServer.cast(server, {:respond_ui, request_id, response})
  end

  # --- Callbacks ---

  @impl true
  def handle_call({:prompt, message, opts}, _from, %State{is_streaming: true} = state) do
    _ = opts
    _ = message
    {:reply, {:error, :already_streaming}, state}
  end

  def handle_call({:prompt, message, opts}, _from, %State{} = state) do
    cmd = %PiEx.Command.Prompt{message: message, images: Keyword.get(opts, :images)}
    write_command(state, cmd)
    {:reply, :ok, %{state | is_streaming: true}}
  end

  def handle_call({:steer, message, opts}, _from, %State{} = state) do
    cmd = %PiEx.Command.Steer{message: message, images: Keyword.get(opts, :images)}
    write_command(state, cmd)
    {:reply, :ok, state}
  end

  def handle_call({:follow_up, message, opts}, _from, %State{} = state) do
    cmd = %PiEx.Command.FollowUp{message: message, images: Keyword.get(opts, :images)}
    write_command(state, cmd)
    {:reply, :ok, state}
  end

  def handle_call(:get_state, from, %State{} = state) do
    send_correlated(state, %PiEx.Command.GetState{}, from)
  end

  def handle_call(:get_messages, from, %State{} = state) do
    send_correlated(state, %PiEx.Command.GetMessages{}, from)
  end

  def handle_call({:set_model, provider, model_id}, from, %State{} = state) do
    send_correlated(state, %PiEx.Command.SetModel{provider: provider, model_id: model_id}, from)
  end

  def handle_call(:get_session_stats, from, %State{} = state) do
    send_correlated(state, %PiEx.Command.GetSessionStats{}, from)
  end

  def handle_call({:bash, command}, from, %State{} = state) do
    send_correlated(state, %PiEx.Command.Bash{shell_command: command}, from)
  end

  @impl true
  def handle_cast(:abort, %State{} = state) do
    write_command(state, %PiEx.Command.Abort{})
    {:noreply, state}
  end

  def handle_cast({:respond_ui, request_id, response}, %State{} = state) do
    case Map.pop(state.pending_ui, request_id) do
      {nil, _} ->
        :ok

      {timer, _} ->
        Process.cancel_timer(timer)
    end

    cmd = %RespondUI{request_id: request_id, response: response}
    write_command(state, cmd)
    {:noreply, %{state | pending_ui: Map.delete(state.pending_ui, request_id)}}
  end

  @impl true
  def handle_info({port, {:data, {:eol, line}}}, %State{port: port, line_buffer: buffer} = state) do
    full_line = buffer <> line
    state = %{state | line_buffer: ""}

    case Protocol.decode_line(full_line) do
      {:response, id, response} ->
        handle_response(id, response, state)

      {:event, event} ->
        dispatch(state, event)
        state = track_streaming(event, state)
        {:noreply, state}

      {:ui_request, event} ->
        dispatch(state, event)
        timer = Process.send_after(self(), {:ui_timeout, event.id}, state.ui_timeout)
        state = put_in(state.pending_ui[event.id], timer)
        {:noreply, state}

      {:error, _reason} ->
        require Logger

        Logger.warning("PiEx.Instance failed to decode line: #{inspect(full_line)}")
        {:noreply, state}
    end
  end

  def handle_info({port, {:data, {:noeol, chunk}}}, %State{port: port} = state) do
    {:noreply, %{state | line_buffer: state.line_buffer <> chunk}}
  end

  def handle_info({port, {:exit_status, code}}, %State{port: port} = state) do
    dispatch(state, %PiEx.Event.Exited{code: code})

    for {_id, from} <- state.pending_calls do
      GenServer.reply(from, {:error, {:pi_exited, code}})
    end

    reason = if code == 0, do: :normal, else: {:pi_exited, code}
    {:stop, reason, %{state | pending_calls: %{}}}
  end

  def handle_info({:ui_timeout, id}, %State{} = state) do
    case Map.pop(state.pending_ui, id) do
      {nil, _} ->
        {:noreply, state}

      {_timer, pending_ui} ->
        cancel_response = Protocol.encode(%RespondUI{request_id: id, response: %{cancelled: true}})
        state.writer.(state.port, cancel_response <> "\n")
        {:noreply, %{state | pending_ui: pending_ui}}
    end
  end

  def handle_info(msg, state) do
    require Logger

    Logger.warning("PiEx.Instance received unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end

  defp handle_response(id, response, state) do
    case Map.pop(state.pending_calls, id) do
      {nil, _} ->
        dispatch(state, response)
        {:noreply, state}

      {from, pending_calls} ->
        result = if response.success, do: {:ok, response}, else: {:error, response}
        GenServer.reply(from, result)
        {:noreply, %{state | pending_calls: pending_calls}}
    end
  end

  defp dispatch(%State{broadcast: broadcast, id: id}, event) when is_function(broadcast) do
    broadcast.(id, event)
  end

  defp dispatch(%State{owner: owner, id: id}, event) do
    send(owner, {:pi_event, id, event})
  end

  defp track_streaming(%PiEx.Event.AgentStart{}, state), do: %{state | is_streaming: true}
  defp track_streaming(%PiEx.Event.AgentEnd{}, state), do: %{state | is_streaming: false}
  defp track_streaming(_, state), do: state

  defp write_command(%State{} = state, cmd) do
    json = Protocol.encode(cmd)
    state.writer.(state.port, json <> "\n")
  end

  defp send_correlated(%State{} = state, cmd, from) do
    id = generate_id()
    cmd = %{cmd | id: id}
    write_command(state, cmd)
    {:noreply, put_in(state.pending_calls[id], from)}
  end

  defp generate_id do
    8 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end
end
