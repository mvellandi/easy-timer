defmodule EasyTimer.ScenarioServer do
  use GenServer
  alias EasyTimer.{Scenario, Timer, Phase}
  alias Phoenix.PubSub

  @moduledoc """
  Create and administer a Scenario GenServer with one or more phases.
  """

  #
  # ADMIN API
  #
  def start_link(%Scenario{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def authorize_admin(server, pin) do
    GenServer.call(server, {:auth, pin})
  end

  #
  # API
  #

  def get(server) do
    GenServer.call(server, :get)
  end

  def start(server) do
    GenServer.call(server, :start)
  end

  def pause(server) do
    GenServer.call(server, :pause)
  end

  def stop(server) do
    GenServer.cast(server, :stop)
  end

  def previous(server) do
    GenServer.cast(server, :previous)
  end

  def next(server) do
    GenServer.cast(server, :next)
  end

  #
  # SERVER
  #

  def init(scenario) do
    Registry.register(EasyTimer.ScenarioServer, scenario.id, self())
    {:ok, scenario}
  end

  defp continue_timer do
    Timer.send_after_second(self(), :tick)
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:auth, pin}, _from, state) do
    {:reply, state.admin_pin === pin, state}
  end

  def handle_call(:start, _from, %{status: status} = state) do
    %{status: status} =
      state =
      case status do
        :started ->
          state

        :paused ->
          continue_timer()
          %{state | status: :started}

        :stopped ->
          continue_timer()
          %{state | status: :started}

        :created ->
          continue_timer()
          %{state | status: :started}
      end

    {:reply, status, state}
  end

  def handle_call(:pause, _from, state) do
    state = %{state | status: :paused}
    {:reply, state, state}
  end

  def handle_cast(:next, %{next_phases: []} = state) do
    {:noreply, state}
  end
  
  def handle_cast(:next, %{previous_phases: previous, current_phase: current, next_phases: [next | next_rest], id: id} = state) do
    %{current_phase: current} = state = reset_phase(current, state)
    state = %{state | previous_phases: [current | previous], current_phase: next, next_phases: next_rest}
    IO.puts("Server: Stop, Reset, and Go to Next Phase")
    broadcast(id, {"reset", next})
    {:noreply, state}
  end

  def handle_cast(:previous, %{previous_phases: []} = state) do
    {:noreply, state}
  end

  def handle_cast(:previous, %{previous_phases: [ previous | previous_rest], current_phase: current, next_phases: next,  id: id} = state) do
    %{current_phase: current} = state = reset_phase(current, state)
    state = %{state | previous_phases: previous_rest, current_phase: previous, next_phases: [current | next]}
    IO.puts("Server: Stop, Reset, and Go to Previous Phase")
    broadcast(id, {"reset", previous})
    {:noreply, state}
  end

  def handle_cast(:stop, %{current_phase: current, id: id} = state) do
    %{current_phase: current} = state = reset_phase(current, state)
    IO.puts("Server: Stop and Reset")
    broadcast(id, {"reset", current})
    {:noreply, state}
  end
  
  def handle_info(:tick, %{current_phase: phase, id: id} = state) do
    key = "scenario:" <> id

    phase =
      if state.status == :started do
        {remaining, phase} =
          Map.get_and_update!(phase, :calc_remaining_seconds, fn seconds ->
            {seconds, seconds - 1}
          end)

        case remaining do
          0 ->
            timeout()

          _ ->
            IO.puts("Server: Tick")
            PubSub.broadcast(EasyTimer.PubSub, key, {"tick", phase})
        end

        continue_timer()
        phase
      else
        phase
      end

    {:noreply, %{state | current_phase: phase}}
  end

  defp timeout do
    IO.puts("Server: Phase complete, moving on...")
    next(self())
  end

  defp reset_phase(%Phase{duration_hours: hours, duration_minutes: minutes, duration_seconds: seconds} = phase, state) do
    phase = %{phase | calc_remaining_seconds: Timer.calc_seconds(hours, minutes, seconds)}
    %{state | status: :stopped, current_phase: phase}
  end

  defp broadcast(id, message) do
    PubSub.broadcast(EasyTimer.PubSub, "scenario:#{id}", message)
  end

end
