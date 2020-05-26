defmodule Web.TimerLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias EasyTimer.TimeUtils
  import Web.TimerLiveMount

  def mount(_params, session, socket) do
    {:ok, assign_defaults(session, socket)}
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

  def handle_event("check_admin", _params, %{assigns: %{admin: admin, status: status}} = socket) do
    status =
      case status do
        :check_admin -> :loaded
        _ -> :check_admin
      end

    {:noreply, assign(socket, admin: %{admin | verify_error: false}, status: status)}
  end

  def handle_event("verify_admin", %{"false" => %{"pin" => pin}}, %{assigns: %{server: server}} = socket) do
    if EasyTimer.authorize_admin(server, pin) do
      IO.puts("Client: admin approved")
      {:noreply, assign(socket, admin: %{verified: true, verify_error: false}, status: :loaded)}
    else
      IO.puts("Client: admin rejected")
      {:noreply, assign(socket, admin: %{verified: false, verify_error: true})}
    end
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
