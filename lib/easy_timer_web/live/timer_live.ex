defmodule Web.TimerLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub
  alias EasyTimer.TimeUtils

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

    {scenario_type, time, current_round, total_rounds, phase_name} =
      case status do
        :loaded ->
          type = if length(scenario.next_phases) == 0, do: :quick, else: :custom

          time =
            scenario.current_phase.calc_remaining_seconds
            |> TimeUtils.seconds_to_clock(":")

          {cr, tr, name} =
            if type === :custom do
              {scenario.current_round, scenario.total_rounds, scenario.current_phase.name}
            else
              {nil, nil, nil}
            end

          IO.puts("Client: ready to go!\n")
          {type, time, cr, tr, name}

        _ ->
          {nil, %{seconds: nil}, nil, nil, nil}
      end

    {:ok,
     assign(socket,
       status: status,
       server: server,
       admin: admin,
       scenario_type: scenario_type,
       time: time,
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

  def handle_event("check_admin", _params, %{assigns: %{status: status}} = socket) do
    status =
      case status do
        :check_admin -> :loaded
        _ -> :check_admin
      end

    {:noreply, assign(socket, status: status)}
  end

  def handle_info({"change_phase", {current_round, remaining_seconds, phase_name}}, socket) do
    IO.puts("Client: changing phase to round: #{current_round}")
    time = remaining_seconds |> TimeUtils.seconds_to_clock(":")
    IO.puts("Client: setting timer to #{time.hours}#{time.minutes}#{time.seconds}\n")

    {:noreply,
     assign(socket,
       time: time,
       current_round: current_round,
       phase_name: phase_name
     )}
  end

  def handle_info({"stop", remaining_seconds}, socket) do
    time = remaining_seconds |> TimeUtils.seconds_to_clock(":")
    IO.puts("Client: reset timer to #{time.hours}#{time.minutes}#{time.seconds}\n")
    {:noreply, assign(socket, :time, time)}
  end

  def handle_info({"tick", remaining_seconds}, socket) do
    time = remaining_seconds |> TimeUtils.seconds_to_clock(":")
    IO.puts("Client: tick -- #{time.hours}#{time.minutes}#{time.seconds}\n")
    {:noreply, assign(socket, :time, time)}
  end
end
