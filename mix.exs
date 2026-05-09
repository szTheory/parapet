defmodule Parapet.MixProject do
  use Mix.Project

  def project do
    [
      app: :parapet,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      package: [files: ~w(lib .formatter.exs mix.exs README* docs), licenses: ["MIT"], links: %{}],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Parapet.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:igniter, "~> 0.7.9"},
      {:telemetry, "~> 1.2"},
      {:oban, ">= 0.0.0", optional: true},
      {:sigra, ">= 0.0.0", optional: true}
    ]
  end
end
