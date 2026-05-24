defmodule Parapet.MixProject do
  use Mix.Project

  @source_url "https://github.com/szTheory/parapet"
  @version "0.10.0"

  def project do
    [
      app: :parapet,
      version: @version,
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,

      # Hex
      description: "An opinionated SRE reliability layer for Phoenix/Elixir SaaS — turn existing telemetry into user-journey SLOs, deploy correlation, incident evidence, and operator-grade runbooks.",
      source_url: @source_url,
      package: package(),

      # Docs
      docs: docs(),

      deps: deps(),
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:mix, :ex_unit]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Parapet.Internal.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ~w(lib priv .formatter.exs mix.exs README* CHANGELOG* LICENSE* docs),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/parapet",
        "Issues" => "#{@source_url}/issues",
        "Changelog" => "https://hexdocs.pm/parapet/changelog.html"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/HISTORY.md",
        "docs/adopter-flows.md",
        "docs/operator-ui.md",
        "docs/slo-reference.md",
        "docs/telemetry.md",
        "docs/getting-started.md",
        "docs/troubleshooting.md",
        "docs/slo-authoring-guide.md",
        "docs/integrations/sigra.md",
        "docs/integrations/accrue.md",
        "docs/integrations/rulestead.md",
        "docs/integrations/threadline.md"
      ],
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      groups_for_extras: [
        Guides: ~r/docs\//
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.20"},
      {:igniter, "~> 0.7.9"},
      {:opentelemetry_api, "~> 1.3", optional: true},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:oban, ">= 0.0.0", optional: true},
      {:req, "~> 0.5.17", optional: true},
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
