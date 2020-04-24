# defmodule EasyTimerWeb.Setup.Quick do
#   use Phoenix.LiveComponent
#   alias EasyTimerWeb.SetupView
#   alias Phoenix.View

#   def render(assigns) do
#     ~L"""
#     <div>
#       <%= View.render(SetupView, "quick.html", assigns) %>
#     </div>
#     """
#   end

#   def handle_event("timer_type", %{"type" => type}, socket) do
#     send(self(), {:updated_timer_type, type})
#     {:noreply, socket}
#   end
# end
