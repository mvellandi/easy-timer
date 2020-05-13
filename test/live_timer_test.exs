defmodule EasyTimerTest do
  use ExUnit.Case
  doctest EasyTimer
  alias EasyTimer.ScenarioServer
  alias EasyTimer.Scenario

  test "create live timer" do
    duration = 5

    {:ok, pid} =
      EasyTimer.create(:quick, %{
        duration_hours: 0,
        duration_minutes: 0,
        duration_seconds: duration
      })

    assert %Scenario{current_phase: %{calc_remaining_seconds: duration}} = ScenarioServer.get(pid)
    ScenarioServer.start(pid)
    :timer.sleep(300)
    assert %Scenario{status: :stopped} = ScenarioServer.get(pid)
  end

  test "multi-phase" do
    duration = 5

    {:ok, pid} = EasyTimer.create(:custom, %{file: "scenario.csv"})

    assert %Scenario{current_phase: %{calc_remaining_seconds: duration}} = ScenarioServer.get(pid)
    ScenarioServer.start(pid)
    :timer.sleep(2500)
    assert %Scenario{status: :stopped, next_phases: []} = ScenarioServer.get(pid)
  end
end
