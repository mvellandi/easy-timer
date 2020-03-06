defmodule EasyTimer.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: EasyTimer.ScenarioRegistry},
      EasyTimer.ScenarioSupervisor,
      EasyTimerWeb.Endpoint
    ]

    :ets.new(:scenarios_table, [:public, :named_table])

    opts = [strategy: :one_for_one, name: EasyTimer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    EasyTimerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
