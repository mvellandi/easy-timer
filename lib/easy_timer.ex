defmodule EasyTimer do
  @moduledoc """
  Public API to create a series of live timers, grouped into a Scenario.
  A Scenario is made up of one or more phases.
  """
  alias EasyTimer.{Scenario, ScenarioSupervisor, Phase, CSV}

  @doc """
  Create a new scenario server with client options.
  Client receives either:
    - Pid to store in conn.session ?, (url slug to lookup named server option), so client can interact with its scenario server.
    - Error(s) map

    Note: https://hexdocs.pm/elixir/GenServer.html#module-name-registration
  """
  def create(:quick, data) when is_map(data) do
    case Phase.create(:quick, Map.put(data, :id, 1)) do
      {:ok, phase} ->
        response = setup_timer([phase])
        {:ok, response}

      {:error, %{} = response} ->
        {:error, %{type: "phase_init_errors", errors: response.errors}}
    end
  end

  def create(:custom, %{file: file}) do
    with {:ok, data} <- CSV.load(file),
         {:ok, phases} <- process_custom_timer_data(data) do
      response = setup_timer(phases)
      {:ok, response}
    else
      {:error, %{} = response} -> {:error, response}
    end
  end

  def create(_, _), do: {:error, %{type: "invalid_scenario_type", errors: nil}}

  defp process_custom_timer_data(data) do
    processed_phases =
      Enum.map(data, fn item ->
        case Phase.create(:custom, item) do
          {:ok, phase} -> phase
          error -> error
        end
      end)

    if Enum.all?(
         processed_phases,
         &(is_map(&1) and Map.get(&1, :__struct__) == :"Elixir.EasyTimer.Phase")
       ) do
      {:ok, processed_phases}
    else
      errors = Enum.filter(processed_phases, &(is_tuple(&1) and elem(&1, 0) == :error))
      {:error, %{type: "phase_init_errors", errors: errors}}
    end
  end

  defp setup_timer([first | rest] = phases) do
    scenario = %Scenario{
      current_phase: first,
      phase_queue: rest,
      rounds: length(phases),
      id: "#{:rand.uniform(999_999)}",
      admin_pin: :rand.uniform(9999)
    }

    {:ok, _pid} = ScenarioSupervisor.start_scenario(scenario)

    %{scenario: scenario.id, admin_pin: scenario.admin_pin}
  end

  def start(scenario) do
    IO.puts("Client mounted and starting scenario...")

    get_scenario(scenario)
    |> EasyTimer.ScenarioServer.start()
  end

  def stop(scenario) do
    IO.puts("Stopping scenario...")

    get_scenario(scenario)
    |> EasyTimer.ScenarioServer.stop()
  end

  def pause(scenario) do
    IO.puts("Pausing scenario...")

    get_scenario(scenario)
    |> EasyTimer.ScenarioServer.pause()
  end

  def previous(scenario) do
    IO.puts("Attempting to go to previous phase...")

    get_scenario(scenario)
    |> EasyTimer.ScenarioServer.previous()
  end

  def next(scenario) do
    IO.puts("Attempting to go to next phase...")

    get_scenario(scenario)
    |> EasyTimer.ScenarioServer.next()
  end

  def get_current_time(scenario) do
    IO.puts("Getting current phase timestamp...")

    %{current_phase: %{calc_remaining_seconds: seconds}} =
      get_scenario(scenario)
      |> EasyTimer.ScenarioServer.get_current_time()

    to_string(seconds)
  end

  def get_scenario(scenario) do
    case Registry.lookup(EasyTimer.ScenarioServer, scenario) do
      [{pid, _} | _] -> pid
      [] -> {:error, "Scenario not found or no longer alive"}
    end
  end
end
