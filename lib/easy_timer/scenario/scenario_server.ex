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
  @doc "Start new ScenarioServer with provided scenario struct"
  def start_link(%Scenario{} = scenario) do
    GenServer.start_link(__MODULE__, scenario)
  end

  @doc "Return true/false if a provided pin matches the scenario's admin_pin"
  def authorize_admin(server, pin) do
    GenServer.call(server, {:auth, pin})
  end

  #
  # API
  #
  @doc "Retrieve the current scenario data"
  def get(server) do
    GenServer.call(server, :get)
  end

  @doc """
  Start counting down on the current phase
  """
  def start(server) do
    GenServer.cast(server, :start)
  end
  
  @doc "Pause counting down on the current phase"
  def pause(server) do
    GenServer.cast(server, :pause)
  end

  @doc """
  Stop the timer.
  
  If the auto_reset flag is set on the scenario, then the current phase is reset on server and client.
  Logs "phase complete" if remaining seconds is 0.
  Logs "scenario complete" if remaining seconds is 0 and there are no more phases.
  Adds :stopped status to scenario, which disables additional 
  """
  def stop(server) do
    GenServer.cast(server, :stop)
  end

  @doc "Go to previous phase"
  def previous(server) do
    GenServer.cast(server, :previous)
  end
  
  @doc "Advance to next phase"
  def next(server) do
    GenServer.cast(server, :next)
  end

  #
  # SERVER
  #

  @doc "Register the ScenarioServer using the scenario's id and the server PID"
  def init(scenario) do
    Registry.register(EasyTimer.ScenarioServer, scenario.id, self())
    {:ok, scenario}
  end

  def handle_call(:get, _from, scenario) do
    {:reply, scenario, scenario}
  end

  def handle_call({:auth, pin}, _from, scenario) do
    {:reply, scenario.admin_pin === pin, scenario}
  end

  def handle_cast(:next, %Scenario{next_phases: []} = scenario) do
    IO.puts("Server: scenario complete")
    scenario = if scenario.auto_reset, do: reset_phase(scenario), else: scenario
    {:noreply, scenario}
  end

  def handle_cast(:pause, %Scenario{status: :started} = scenario) do
    IO.puts("Server: pausing timer")
    {:noreply, %{scenario | status: :paused}}
  end

  def handle_cast(:pause, scenario), do: {:noreply, scenario}

  def handle_cast(:previous, %Scenario{previous_phases: []} = scenario), do: {:noreply, scenario}

  def handle_cast(action, %Scenario{status: status} = scenario)
      when action in [:next, :previous] do
    scenario =
      if status === :stopped do
        scenario
      else
        IO.puts("Server: stopping timer")
        %{scenario | status: :stopped}
      end

    IO.puts("Server: resetting timer")
    IO.puts("Server: going to #{Atom.to_string(action)} phase")

    %{current_phase: cp, current_round: cr} =
      scenario = reset_phase(scenario) |> change_phase(action)

    broadcast(
      scenario.id,
      {"change_phase", {cr, cp.calc_remaining_seconds, cp.name}}
    )

    {:noreply, scenario}
  end

  def handle_cast(:start, %{status: :started} = scenario), do: {:noreply, scenario}

  def handle_cast(:start, %{current_phase: current} = scenario) do
    scenario =
      if current.calc_remaining_seconds > 0 do
        IO.puts("Server: Counting down from #{current.calc_remaining_seconds}")
        continue_timer()
        %{scenario | status: :started}
      else
        scenario
      end

    {:noreply, scenario}
  end

  def handle_cast(:stop, %Scenario{status: status} = scenario)
      when status in [:created, :stopped] do
    {:noreply, scenario}
  end

  def handle_cast(:stop, %Scenario{next_phases: next_phases} = scenario) do
    IO.puts("Server: stopping timer")

    scenario =
      case scenario.auto_reset do
        true ->
          IO.puts("Server: resetting timer")
          scenario = reset_phase(scenario)
          broadcast(scenario.id, {"stop", scenario.current_phase.calc_remaining_seconds})
          scenario

        false ->
          scenario
      end

    if scenario.current_phase.calc_remaining_seconds === 0 do
      IO.puts("Server: phase complete")
      if next_phases === [], do: IO.puts("Server: scenario complete")
    end

    {:noreply, %{scenario | status: :stopped}}
  end

  def handle_info(:tick, %Scenario{status: :started, current_phase: current_phase} = scenario) do
    {remaining, updated_phase} =
      Map.get_and_update!(current_phase, :calc_remaining_seconds, fn remaining ->
        updated =
          if remaining > 0 do
            continue_timer()
            remaining - 1
          else
            0
          end

        {remaining, updated}
      end)

    case remaining do
      0 ->
        timeout(scenario)

      _ ->
        IO.puts("Server: tick -- #{updated_phase.calc_remaining_seconds}")
        broadcast(scenario.id, {"tick", updated_phase})
    end

    {:noreply, %{scenario | current_phase: updated_phase}}
  end
  def handle_info(:tick, %Scenario{} = scenario), do: {:noreply, scenario}

  defp broadcast(id, message) do
    PubSub.broadcast(EasyTimer.PubSub, "scenario:#{id}", message)
  end

  defp change_phase(
         %Scenario{previous_phases: pp, current_phase: cp, next_phases: np, current_round: round} =
           scenario,
         direction
       ) do
    {pp, cp, np, round} =
      case direction do
        :previous -> {tl(pp), hd(pp), [cp | np], round - 1}
        :next -> {[cp | pp], hd(np), tl(np), round + 1}
      end

    %Scenario{
      scenario
      | previous_phases: pp,
        current_phase: cp,
        next_phases: np,
        current_round: round
    }
  end

  defp continue_timer() do
    Timer.send_after_second(self(), :tick)
  end

  defp reset_phase(
         %Scenario{
           current_phase:
             %Phase{duration_hours: h, duration_minutes: m, duration_seconds: s} = phase
         } = scenario
       ) do
    phase = %{phase | calc_remaining_seconds: Timer.calc_seconds(h, m, s)}
    %{scenario | current_phase: phase}
  end

  defp timeout(%Scenario{auto_advance: advance}) do
    IO.puts("Server: phase complete")

    case advance do
      true ->
        next(self())

      false ->
        stop(self())
    end
  end
end
