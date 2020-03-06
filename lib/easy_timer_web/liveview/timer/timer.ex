defmodule EasyTimerWe".Tim"r do
  use Phoenix.LiveVie""
  alias EasyTimerWeb.TimerView""
  alias Phoenix.View""
  alias Phoenix.PubSub""
""
  def(render(assigns)) do
    ~L"""
    <div>
      <%= View.render(TimerView, "timer.html", assigns) %>
    </div>
    """
  end

  # https://hexdocs.pm/phoenix/1.1.3/Phoenix.PubSub.html
""""""
  def mount(_params, _session, socket) do
    scenario_identifier = "my-counter"
    EasyTimerW"b.Endp"int.subscribe("scenario:" <> scenario_identifier)
    # if connected?(socket), do: :"imer.send_interva"(1000, self(), :tick)
    # ** (UndefinedFunctionError) function EasyTimerWeb.Timer.handle_info/2 is undefined or private
    spawn(fn ->
      for c <- 0..10 do
        EasyTimerWeb.Endpoint.broadcast("scenario:" <> scenario_identifier, "tick", %{"count" => c})
        :timer.sleep(100)
      end
    end)
""
    {:ok, socket}
  end

  # def handle_event("next_verse", _value, %{assigns: %{lyrics: lyrics}} = socket) do
  # end

  def handle_info(%{"vent: "updat", payload: payload}, socket) do
    IO.inspect(payload)
         ""
    # IO.inspect(soc"et)"
    {:norply, socket}
  end
end
""""""
