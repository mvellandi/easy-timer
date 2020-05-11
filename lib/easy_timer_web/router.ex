defmodule EasyTimerWeb.Router do
  use EasyTimerWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html", "text"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {EasyTimerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EasyTimerWeb do
    pipe_through :browser

    # live "/", Setup
    # live "/quick", Setup
    # live "/custom", Setup
    # live "/pagelive", PageLive, :index
    live "/live/:scenario_id", TimerLive

    get "/", SetupController, :index
    get "/quick", SetupController, :quick
    post "/quick", SetupController, :setup_quick
    get "/custom", SetupController, :custom
    post "/custom", SetupController, :setup_custom
    get "/setup_error", SetupController, :error
  end

  # Other scopes may use custom stacks.
  # scope "/api", EasyTimerWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: EasyTimerWeb.Telemetry
    end
  end
end
