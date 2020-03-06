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
    with {:ok, phase} <- Phase.create(:quick, Map.put(data, :id, 1)) do
      %Scenario{current_phase: phase}
      |> setup_url_and_pin()
      |> create_server()
    else
      {:error, errors} -> %{errors: errors}
    end
  end

  def create(:custom, data) do
    # A good conversion must then be adapted to a list of maps with atom keys, preferably also in CSV module.
    # Then the list needs to be batch processed into Phases.
    # Since the Phases need valid keys, it's best to test one Phase for a valid response, then continue the batch.
    # Convert associated keys in the Phase module where it can be validated at the appropriate stage.
    case CSV.load(data.file) do
      {:ok, csv_data} ->
        processed_phases =
          Enum.map(csv_data, fn unit ->
            case Phase.create(:custom, unit) do
              {:ok, phase} -> phase
              error -> error
            end
          end)

        if Enum.all?(
             processed_phases,
             &(is_map(&1) and Map.get(&1, :__struct__) == :"Elixir.EasyTimer.Phase")
           ) do
          [first | rest] = processed_phases

          %Scenario{current_phase: first, phase_queue: rest, rounds: length(processed_phases)}
          |> setup_url_and_pin()
          |> create_server()
        else
          errors = Enum.filter(processed_phases, &(is_tuple(&1) and elem(&1, 0) == :error))
          {:error, :phase_init_errors, errors}
        end

      {:error, :parsing_errors, errors} ->
        {:error, :parsing_errors, errors}

      {:error, :failed_to_open, nil} ->
        {:error, :failed_to_open}
    end
  end

  def create(_, _), do: {:error, "Invalid scenario type."}

  defp create_server(%Scenario{} = scenario) do
    ScenarioSupervisor.start_scenario(scenario)
  end

  defp setup_url_and_pin(scenario) do
    %{scenario | url: :rand.uniform(999_999), admin_pin: :rand.uniform(9999)}
  end

  #
  # ERROR HANDLING
  #
  def handle_datatype_error({:error, {:number_range, msg}}) do
    IO.inspect({:error, {:number_range, msg}})
  end
end
