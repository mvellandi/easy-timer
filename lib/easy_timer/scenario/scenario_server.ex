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

  def get(server) do
    GenServer.call(server, :get)
  end

  def authorize_admin(server, pin) do
    GenServer.call(server, {:auth, pin})
  end

  #
  # API
  #

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
    %{url_slug: slug} = scenario
    Registry.register(EasyTimer.ScenarioServer, slug, self())
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
          # TODO tell Timer to resume counting down
          continue_timer()
          %{state | status: :started}

        :stopped ->
          # TODO tell Timer to restart the clock from the beginning
          continue_timer()
          %{state | status: :started}

        :created ->
          continue_timer()
          %{state | status: :started}
      end

    {:reply, status, state}
  end

  def handle_call(:pause, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(:stop, %{current_phase: phase} = state) do
    %{duration_hours: hours, duration_minutes: minutes, duration_seconds: seconds} = phase
    phase = %{phase | calc_remaining_seconds: Timer.calc_seconds(hours, minutes, seconds)}
    state = %{state | status: :stopped, current_phase: phase}
    {:noreply, state}
  end

  def handle_cast(:next, %{phase_queue: []} = state) do
    stop(self())
    {:noreply, state}
  end

  def handle_cast(:next, %{phase_queue: [next_phase | queue]} = state) do
    state = %{state | current_phase: next_phase, phase_queue: queue}
    {:noreply, state}
  end

  def handle_info(:tick, %{current_phase: phase, url_slug: slug} = state) do
    # Check if state's current phase has run out of time
    # Otherwise,decrement remainder

    phase =
      if state.status == :started do
        {remaining, phase} =
          Map.get_and_update!(phase, :calc_remaining_seconds, fn seconds ->
            {seconds, seconds - 1}
          end)

        case remaining do
          0 -> timeout()
          _ -> nil
        end

        continue_timer()
        phase
      else
        phase
      end

    IO.puts("ticking on the server #{slug}")
    key = "scenario:" <> slug
    IO.puts("Server about to broadcast...")
    PubSub.broadcast(EasyTimer.PubSub, key, {"tick", phase})

    {:noreply, %{state | current_phase: phase}}
  end

  defp timeout do
    IO.puts("Phase complete, moving on...")
    # Move current to end of queue. Load new phase from queue into current phase.
    next(self())
  end
end
