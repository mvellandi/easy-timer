# defmodule EasyTimerWeb.AuthController do
#   import Phoenix.LiveView.Controller

#   def show(conn, %{"id" => thermostat_id}) do
#     live_render(conn, TimerLive, session: %{
#       "admin" => true,
#       "current_user_id" => get_session(conn, :user_id)
#     })
#   end
# end