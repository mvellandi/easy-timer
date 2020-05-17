defmodule Web.TimerController do
  use Web, :controller
  alias Web.TimerLive
  import Plug.Conn
  import Phoenix.LiveView.Controller

  def show(conn, %{"scenario_id" => id}) do
    conn = fetch_cookies(conn, signed: "easytimer-#{id}")
    admin = get_session(conn, "admin") || false
    live_render(conn, TimerLive, session: %{"scenario_id" => id, "admin" => admin})
  end
end
