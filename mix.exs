defmodule Parapet.MixProject do
  use Mix.Project

  def project do
    [
      app: :parapet,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      package: [files: ~w(lib priv .formatter.exs mix.exs README* docs), licenses: ["MIT"], links: %{}],
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Parapet.Internal.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:igniter, "~> 0.7.9"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:oban, ">= 0.0.0", optional: true},
      {:sigra, ">= 0.0.0", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      "verify.public_api": ["docs --warnings-as-errors"]
    ]
  end
end
