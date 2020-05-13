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

  def handle_call(:get, _from, scenario) do
    {:reply, scenario, scenario}
  end

  def handle_call({:auth, pin}, _from, scenario) do
    {:reply, scenario.admin_pin === pin, scenario}
  end

  def handle_call(:start, _from, %{status: status} = scenario) do
    scenario =
      case status do
        :started ->
          scenario

        _ ->
          continue_timer()
          %{scenario | status: :started}
      end

    {:reply, scenario, scenario}
  end

  def handle_call(:pause, _from, scenario) do
    scenario = %{scenario | status: :paused}
    {:reply, scenario, scenario}
  end

  def handle_cast(:previous, %Scenario{previous_phases: []} = scenario), do: {:noreply, scenario}
  def handle_cast(:next, %Scenario{next_phases: []} = scenario), do: {:noreply, scenario}

  def handle_cast(action, %Scenario{} = scenario) when action in [:next, :previous] do
    IO.puts("Server: stop and reset")
    scenario = reset_phase(scenario) |> change_phase(action)
    broadcast(scenario.id, {"reset", scenario.current_phase})
    {:noreply, scenario}
  end

  def handle_cast(:stop, %Scenario{} = scenario) do
    IO.puts("Server: stop and reset")
    scenario = reset_phase(scenario)
    broadcast(scenario.id, {"reset", scenario.current_phase})
    {:noreply, scenario}
  end

  def handle_info(:tick, %Scenario{current_phase: current_phase} = scenario) do
    phase =
      if scenario.status == :started do
        {remaining, updated_phase} =
          Map.get_and_update!(current_phase, :calc_remaining_seconds, fn seconds ->
            {seconds, seconds - 1}
          end)

        case remaining do
          0 ->
            timeout()

          _ ->
            IO.puts("Server: Tick")
            broadcast(scenario.id, {"tick", updated_phase})
        end

        continue_timer()
        updated_phase
      else
        current_phase
      end

    {:noreply, %{scenario | current_phase: phase}}
  end

  defp broadcast(id, message) do
    PubSub.broadcast(EasyTimer.PubSub, "scenario:#{id}", message)
  end

  defp change_phase(
         %Scenario{previous_phases: pp, current_phase: c, next_phases: np} = scenario,
         direction
       ) do
    IO.puts("Server: going to #{Atom.to_string(direction)} phase")

    {pp, cp, np} =
      case direction do
        :previous -> {tl(pp), hd(pp), [c | np]}
        :next -> {[c | pp], hd(np), tl(np)}
      end

    %Scenario{
      scenario
      | previous_phases: pp,
        current_phase: cp,
        next_phases: np
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
    %{scenario | status: :stopped, current_phase: phase}
  end

  defp timeout do
    IO.puts("Server: phase complete, moving on...")
    next(self())
  end
end
