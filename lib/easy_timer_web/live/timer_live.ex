defmodule EasyTimerWeb.TimerLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  def mount(%{"scenario_id" => scenario_id} = _params, _session, socket) do
    IO.puts("Client: mounted")
    server =
      case EasyTimer.get_scenario(scenario_id) do
        server when is_pid(server) ->
          IO.puts("Client: scenario is alive :)")
          IO.puts("Client: Received scenario server PID:")
          IO.inspect(server)
          server

        {:error, _msg} ->
          IO.puts("Client: scenario is dead :(")
          nil
      end

    scenario =
      if connected?(socket) do
        IO.puts("Client: connected")
        key = "scenario:" <> scenario_id
        IO.puts("Client: subscribing to #{key}")
        PubSub.subscribe(EasyTimer.PubSub, key)
        IO.puts("Client: requesting scenario data")
        scenario = EasyTimer.get_scenario_data(server)
        IO.puts("Client: received scenario data:")
        IO.inspect(scenario)
        scenario
      else
        nil
      end

    status = case is_pid(server) do
      true -> if is_map(scenario), do: :loaded, else: :loading
      _ -> :error
    end

    {scenario_type, seconds} = case status do
      :loaded ->
        type = if length(scenario.phase_queue) == 0, do: :quick, else: :custom
        seconds = scenario.current_phase.calc_remaining_seconds
        {type, seconds}
      _ ->
        {nil, nil}
    end

    {:ok,
     assign(socket,
      status: status,
      server: server,
      admin: true,
      scenario_type: scenario_type,
      seconds: seconds
     )}
  end

  def handle_event("start", _params, %{assigns: %{server: server}} = socket) do
    IO.puts("Client: requesting start")
    EasyTimer.start(server)
    {:noreply, socket}
  end

  def handle_event("pause", _params, %{assigns: %{server: server}} = socket) do
    IO.puts("Client: requesting pause")
    EasyTimer.pause(server)
    {:noreply, socket}
  end
  
  def handle_event("stop", _params, %{assigns: %{server: server}} = socket) do
    IO.puts("Client: requesting stop")
    EasyTimer.stop(server)
    {:noreply, socket}
  end

  def handle_event("previous", _params, %{assigns: %{server: server}} = socket) do
    EasyTimer.previous(server)
    {:noreply, socket}
  end

  def handle_event("next", _params, %{assigns: %{server: server}} = socket) do
    EasyTimer.next(server)
    {:noreply, socket}
  end

  def handle_info({"tick", phase}, socket) do
    IO.puts("Client: Tick")
    {:noreply, assign(socket, :seconds, phase.calc_remaining_seconds)}
  end

  def handle_info({"stop", phase}, socket) do
    IO.puts("Client: Stop")
    {:noreply, assign(socket, :seconds, phase.calc_remaining_seconds)}
  end
end
