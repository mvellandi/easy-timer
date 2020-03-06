# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :easy_timer, EasyTimerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "umRpCPYNWA6d0def94Ddm1svc8G8tDGoVd8pMvX5iGixP2bdN8qTpFIc9hQzxzyk",
  render_errors: [view: EasyTimerWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: EasyTimer.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "dmK9bL+us/6csweJlmT/OpzNGpRJ2GuH"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
