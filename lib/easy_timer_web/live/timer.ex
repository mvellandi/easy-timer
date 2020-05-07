defmodule EasyTimerWeb.Timer do
  use Phoenix.LiveView
  alias Phoenix.PubSub

  def mount(%{"scenario" => scenario} = _params, _session, socket) do
    {alive, seconds} =
      if scenario_alive?(scenario),
        do: {true, EasyTimer.get_current_time(scenario)},
        else: {false, nil}

    if connected?(socket) do
      IO.puts("second mount: connected")
      key = "scenario:" <> scenario
      PubSub.subscribe(EasyTimer.PubSub, key)
    else
      IO.puts("first mount: static render")
    end

    {:ok,
     assign(socket,
       scenario: scenario,
       alive: alive,
       admin: true,
       seconds: seconds
     )}
  end

  def handle_event("start", _params, %{assigns: %{scenario: scenario}} = socket) do
    EasyTimer.start(scenario)
    {:noreply, socket}
  end

  def handle_event("pause", _params, %{assigns: %{scenario: scenario}} = socket) do
    EasyTimer.pause(scenario)
    {:noreply, socket}
  end

  def handle_event("stop", _params, %{assigns: %{scenario: scenario}} = socket) do
    EasyTimer.stop(scenario)
    {:noreply, socket}
  end

  def handle_event("previous", _params, %{assigns: %{scenario: _scenario}} = socket) do
    # EasyTimer.previous(scenario)
    {:noreply, socket}
  end

  def handle_event("next", _params, %{assigns: %{scenario: _scenario}} = socket) do
    # EasyTimer.next(scenario)
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
