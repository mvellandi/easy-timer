defmodule EasyTimerWeb.Setup do
  use Phoenix.LiveView
  alias EasyTimerWeb.{Setup, SetupView}
  alias Phoenix.View

  def(render(assigns)) do
    ~L"""
    <%= live_component @socket, Setup.Home, assigns %>
    """
  end

  def mount(_params, _session, socket) do
    # if connected?(socket), do: :timer.send_interval(1000, self(), :tick)
    {:ok, socket}
  end

  # def handle_event("next_verse", _value, %{assigns: %{lyrics: lyrics}} = socket) do

  # end
end
