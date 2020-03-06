defmodule EasyTimerWeb.Setup.Home do
  use Phoenix.LiveComponent
  alias EasyTimerWeb.SetupView
  alias Phoenix.View

  def(render(assigns)) do
    ~L"""
    <div>
      <%= View.render(SetupView, "home.html", assigns) %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # if connected?(socket), do: :timer.send_interval(1000, self(), :tick)
    {:ok, socket}
  end

  # def handle_event("next_verse", _value, %{assigns: %{lyrics: lyrics}} = socket) do

  # end
end
