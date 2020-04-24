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
    %{url_slug: _slug} = scenario_args

    child_spec = %{
      id: ScenarioServer,
      start: {ScenarioServer, :start_link, [scenario_args]},
      restart: :transient
    }

    {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  # @doc """
  # Terminates the `ScenarioServer` process normally. It won't be restarted.
  # TODO: How and when should a scenario be stopped ? Via LiveUI -> ScenarioServer ?
  # """
  # def stop_scenario(key) do
  # scenario_pid = Registry.lookup(EasyTimer.ScenarioServer, key)
  # DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  # end
end
