defmodule EasyTimer.Scenario do
  alias EasyTimer.Phase

  @moduledoc """
  Defines a Scenario struct which is an ordered series of Phases.
  Sports example:
    - Stretch, 5min
    - Cardio, 5min
    - Weight lifting, 20min
    - Bike, 30min
  """
  defstruct id: nil,
            admin_pin: nil,
            phase_queue: [],
            phases_completed: [],
            current_phase: %Phase{},
            rounds: 1,
            current_round: 1,
            status: :created
end
