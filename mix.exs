defmodule EasyTimer.MixProject do
  use Mix.Project

  def project do
    [
      app: :easy_timer,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EasyTimer.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.5.4", override: true},
      {:phoenix_live_view, "~> 0.14.4"},
      {:floki, "~> 0.27.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.2.7"},
      {:telemetry_metrics, "~> 0.5.0"},
      {:telemetry_poller, "~> 0.5.1"},
      {:gettext, "~> 0.18.1"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.3"},
      {:csv, "~> 2.3"},
      {:ex_doc, "~> 0.22.2", only: :dev, runtime: false},
      {:plug, "~> 1.10"},
      {:timex, "~> 3.6"}
    ]
  end

  defp aliases do
    [
      "css.update": ["tailwind.gen.whitelist", "node.update", "phx.digest"]
    ]
  end
end
