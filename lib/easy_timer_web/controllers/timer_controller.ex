defmodule Web.TimerController do
  use Web, :controller
  alias Web.TimerLive
  import Phoenix.LiveView.Controller

  def show(conn, %{"scenario_id" => id}) do
    admin = Plug.Conn.get_session(conn, "easytimer-admin-#{id}") || false
    live_render(conn, TimerLive, session: %{"scenario_id" => id, "admin" => admin})
  end
end
