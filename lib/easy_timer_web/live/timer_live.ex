defmodule EasyTimerWeb.TimerLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  def mount(_params, %{"scenario_id" => scenario_id, "admin" => admin}, socket) do
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
        IO.puts("Client: received scenario data")
        scenario
      else
        nil
      end

    status =
      case is_pid(server) do
        true -> if is_map(scenario), do: :loaded, else: :loading
        _ -> :error
      end

    {scenario_type, seconds, current_round, total_rounds, phase_name} =
      case status do
        :loaded ->
          type = if length(scenario.next_phases) == 0, do: :quick, else: :custom
          seconds = scenario.current_phase.calc_remaining_seconds

          {cr, tr, name} =
            if type === :custom do
              {scenario.current_round, scenario.total_rounds, scenario.current_phase.name}
            else
              {nil, nil, nil}
            end

          {type, seconds, cr, tr, name}

        _ ->
          {nil, nil, nil, nil, nil}
      end

    {:ok,
     assign(socket,
       status: status,
       server: server,
       admin: admin,
       scenario_type: scenario_type,
       seconds: seconds,
       current_round: current_round,
       total_rounds: total_rounds,
       phase_name: phase_name
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

  def handle_info({"change_phase", {current_round, remaining_seconds, phase_name}}, socket) do
    # reset_value = phase.calc_remaining_seconds
    # IO.puts("Client: reset timer to #{reset_value} seconds")
    IO.puts("Client: changing phase to round: #{current_round}")
    IO.puts("Client: setting timer to #{remaining_seconds} seconds")

    {:noreply,
     assign(socket,
       seconds: remaining_seconds,
       current_round: current_round,
       phase_name: phase_name
     )}
  end

  def handle_info({"stop", remaining_seconds}, socket) do
    # reset_value = phase.calc_remaining_seconds
    # IO.puts("Client: reset timer to #{reset_value} seconds")
    IO.puts("Client: reset timer to #{remaining_seconds} seconds")
    {:noreply, assign(socket, :seconds, remaining_seconds)}
  end

  def handle_info({"tick", phase}, socket) do
    remaining = phase.calc_remaining_seconds
    IO.puts("Client: tick -- #{remaining}")
    {:noreply, assign(socket, :seconds, remaining)}
  end
end
