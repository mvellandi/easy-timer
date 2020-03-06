defmodule EasyTimerWeb.Router do
  use EasyTimerWeb, :router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EasyTimerWeb do
    pipe_through :browser

    live "/", Setup
    live "/timer", Timer
  end

  # Other scopes may use custom stacks.
  # scope "/api", EasyTimerWeb do
  #   pipe_through :api
  # end
end
