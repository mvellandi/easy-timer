# defmodule Web.Setup do
#   use Phoenix.LiveView
#   alias Web.Setup

#   @defaults %{timer_type: nil}

#   def render(assigns) do
#     render_component(assigns)
#   end

#   def render_component(%{timer_type: type} = assigns) do
#     [id, component] =
#       case type do
#         nil -> [:home, Setup.Home]
#         "quick" -> [:home, Setup.Quick]
#         "custom" -> [:home, Setup.Custom]
#       end

#     ~L"""
#     <div><%= live_component @socket, component, id: id, timer_type: @timer_type %></div>
#     """
#   end

#   def mount(_params, _session, socket) do
#     {:ok, assign(socket, Map.merge(@defaults, socket.assigns))}
#   end

#   def handle_event("update_timer_type", %{"type" => type}, socket) do
#     socket = assign(socket, :timer_type, type)
#     {:noreply, push_patch(socket, to: "/#{type}", replace: true)}
#   end

#   def handle_params(_params, _uri, socket) do
#     {:noreply, socket}
#   end
# end
