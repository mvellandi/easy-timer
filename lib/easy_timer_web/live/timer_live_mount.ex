defmodule Web.TimerLiveMount do
  alias Phoenix.PubSub
  alias EasyTimer.TimeUtils
  import Phoenix.LiveView

  def assign_defaults(%{"scenario_id" => scenario_id, "admin" => admin}, socket) do
    IO.puts("Client: mounted")

    server =
      case EasyTimer.get_scenario(scenario_id) do
        server when is_pid(server) ->
          IO.puts("Client: scenario is alive :)")
          IO.puts("Client: Received scenario server PID:")
          IO.inspect(server)
          server

        {:error, _msg} ->
          IO.puts("Client: scenario is dead :(")
          nil
      end

    scenario =
      if connected?(socket) do
        IO.puts("Client: connected")
        key = "scenario:" <> scenario_id
        IO.puts("Client: subscribing to #{key}")
        PubSub.subscribe(EasyTimer.PubSub, key)
        IO.puts("Client: requesting scenario data")
        scenario = EasyTimer.get_scenario_data(server)
        IO.puts("Client: received scenario data")
        scenario
      else
        nil
      end

    status =
      case is_pid(server) do
        true -> if is_map(scenario), do: :loaded, else: :loading
        _ -> :error
      end

    {scenario_type, time, current_round, total_rounds, phase_name} =
      case status do
        :loaded ->
          type = if length(scenario.next_phases) == 0, do: :quick, else: :custom

          time =
            scenario.current_phase.calc_remaining_seconds
            |> TimeUtils.seconds_to_clock(":")

          {cr, tr, name} =
            if type === :custom do
              {scenario.current_round, scenario.total_rounds, scenario.current_phase.name}
            else
              {nil, nil, nil}
            end

          IO.puts("Client: ready to go!\n")
          {type, time, cr, tr, name}

        _ ->
          {nil, %{seconds: nil}, nil, nil, nil}
      end

    admin = %{verified: admin, verify_error: false}

    assign(socket,
      status: status,
      server: server,
      admin: admin,
      scenario_type: scenario_type,
      time: time,
      current_round: current_round,
      total_rounds: total_rounds,
      phase_name: phase_name
    )
  end
end
