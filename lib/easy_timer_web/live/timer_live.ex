defmodule EasyTimerWeb.TimerLive do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  def mount(%{"scenario_id" => scenario_id} = _params, _session, socket) do
    {alive, seconds} =
      if scenario_alive?(scenario_id),
        do: {true, EasyTimer.get_current_time(scenario_id)},
        else: {false, nil}

    if connected?(socket) do
      IO.puts("second mount: connected")
      key = "scenario:" <> scenario_id
      PubSub.subscribe(EasyTimer.PubSub, key)
    else
      IO.puts("first mount: static render")
    end

    {:ok,
     assign(socket,
       scenario_id: scenario_id,
       alive: alive,
       admin: true,
       seconds: seconds
     )}
  end

  def handle_event("start", _params, %{assigns: %{scenario_id: scenario_id}} = socket) do
    EasyTimer.start(scenario_id)
    {:noreply, socket}
  end

  def handle_event("pause", _params, %{assigns: %{scenario_id: scenario_id}} = socket) do
    EasyTimer.pause(scenario_id)
    {:noreply, socket}
  end

  def handle_event("stop", _params, %{assigns: %{scenario_id: scenario_id}} = socket) do
    EasyTimer.stop(scenario_id)
    {:noreply, socket}
  end

  def handle_event("previous", _params, %{assigns: %{scenario_id: _scenario_id}} = socket) do
    # EasyTimer.previous(scenario_id)
    {:noreply, socket}
  end

  def handle_event("next", _params, %{assigns: %{scenario_id: _scenario_id}} = socket) do
    # EasyTimer.next(scenario_id)
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

  defp scenario_alive?(scenario) do
    case EasyTimer.get_scenario(scenario) do
      {:error, _msg} -> false
      _ -> true
    end
  end
end
