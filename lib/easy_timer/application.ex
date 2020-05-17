defmodule EasyTimer.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: EasyTimer.ScenarioServer},
      {Phoenix.PubSub, [name: EasyTimer.PubSub]},
      EasyTimer.ScenarioSupervisor,
      Web.Endpoint
    ]

    opts = [strategy: :one_for_one, name: EasyTimer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Web.Endpoint.config_change(changed, removed)
    :ok
  end
end
