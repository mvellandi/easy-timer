defmodule EasyTimer.ScenarioServer do
  use GenServer
  alias EasyTimer.{Scenario, Timer}
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
    GenServer.call(server, :previous)
  end

  def next(server) do
    GenServer.cast(server, :next)
  end

  #
  # SERVER
  #

  def init(scenario) do
    %{id: id} = scenario
    Registry.register(EasyTimer.ScenarioServer, id, self())
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

  def handle_cast(:next, %{phase_queue: []} = state) do
    stop(self())
    {:noreply, state}
  end
  
  # TODO: Handle :previous phase actions
  # use two stacks (completed/remaining) and transfer phases accordingly between them and current_phase
  def handle_cast(:next, %{phase_queue: [next_phase | queue]} = state) do
    state = %{state | current_phase: next_phase, phase_queue: queue}
    {:noreply, state}
  end

  def handle_cast(:stop, %{current_phase: phase, id: id} = state) do
    %{duration_hours: hours, duration_minutes: minutes, duration_seconds: seconds} = phase
    phase = %{phase | calc_remaining_seconds: Timer.calc_seconds(hours, minutes, seconds)}
    state = %{state | status: :stopped, current_phase: phase}
    key = "scenario:" <> id
    IO.puts("Server: Stop")
    PubSub.broadcast(EasyTimer.PubSub, key, {"stop", phase})
    {:noreply, state}
  end
  
  def handle_info(:tick, %{current_phase: phase, id: id} = state) do
    # Check if state's current phase has run out of time
    # Otherwise,decrement remainder
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
    # Move current to end of queue. Load new phase from queue into current phase.
    next(self())
  end
end
