defmodule EasyTimer.ScenarioSupervisor do
@moduledoc """
  Supervisor that starts `ScenarioServer` processes dynamically.
  Created at Application startup and called via EasyTimer public API.
  """
  use DynamicSupervisor
  alias EasyTimer.ScenarioServer


  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a `ScenarioServer` process and supervises it.
  """
  def start_scenario(scenario_args) do
    child_spec = %{
      id: ScenarioServer,
      start: {ScenarioServer, :start_link, [scenario_args]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminates the `ScenarioServer` process normally. It won't be restarted.
  """
  def stop_scenario(scenario_name) do
    :ets.delete(:scenarios_table, scenario_name)

    child_pid = ScenarioServer.scenario_pid(scenario_name)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
end
