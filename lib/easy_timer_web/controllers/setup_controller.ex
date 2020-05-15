defmodule EasyTimerWeb.SetupController do
  use EasyTimerWeb, :controller

  def index(conn, _params) do
    # conn |> put_layout("admin.html") |> render("index.html")
    # render(conn, "index.html")
    render(conn, "index.html")
  end

  def quick(conn, _params) do
    render(conn, "quick.html")
  end

  def custom(conn, _params) do
    render(conn, "custom.html")
  end

  def setup_quick(conn, %{"hours" => hours, "minutes" => mins, "seconds" => secs}) do
    case EasyTimer.create(:quick, %{
           duration_hours: hours,
           duration_minutes: mins,
           duration_seconds: secs
         }) do
      %{scenario_id: scenario_id, admin_pin: admin_pin} ->
        host = "http://localhost:4000/live/"
        # conn = Plug.Conn.put_resp_cookie(conn, "easytimer", %{admin: true}, sign: true)

        render(conn, "success.html",
          page_title: "Quick Timer",
          admin_pin: admin_pin,
          host: host,
          scenario_id: scenario_id
        )

      {:error, %{type: "phase_init_errors", errors: errors}} when is_list(errors) ->
        render(conn, "quick_error.html", phase_errors: errors)
    end
  end

  def setup_custom(conn, %{"file" => file}) do
    case EasyTimer.create(:custom, %{file: file.path}) do
      %{scenario_id: scenario_id, admin_pin: admin_pin} ->
        host = "http://localhost:4000/live/"
        # conn = Plug.Conn.put_resp_cookie(conn, "easytimer", %{admin: true}, sign: true)

        render(conn, "success.html",
          page_title: "Custom Timer",
          admin_pin: admin_pin,
          host: host,
          scenario_id: scenario_id
        )

      {:error, %{type: "phase_init_errors", errors: errors}} when is_list(errors) ->
        IO.inspect(errors)

        render(conn, "custom_error.html",
          phase_errors: [
            "There's a bunch of phase errors I can't list right now. Check your file."
          ]
        )

      {:error, %{type: "file_error", errors: nil}} ->
        render(conn, "custom_error.html",
          file_errors: ["Cannot read file. Please ensure this is a properly formatted CSV file."]
        )

      {:error, %{type: "parsing_errors", errors: errors}} ->
        IO.inspect(errors)

        render(conn, "custom_error.html",
          file_errors: ["Cannot parse file. Please ensure this is a properly formatted CSV file."]
        )
    end
  end
end
