defmodule Parapet.DocsPhase33Test do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)

  defp read!(path), do: File.read!(Path.join(@root, path))

  defp project_docs do
    Parapet.MixProject.project()
    |> Keyword.fetch!(:docs)
  end

  test "migration guide gives adopters the v1 upgrade checks and SLO provider migration path" do
    guide = read!("docs/migration-v1.md")

    assert guide =~ "HISTORY.md"
    assert guide =~ "Parapet.SLO.define/2"
    assert guide =~ "Parapet.SLO.Provider"
    assert guide =~ "mix compile --warnings-as-errors"
    assert guide =~ "mix test"
    assert guide =~ "mix parapet.doctor --ci"
  end

  test "deployment guide documents host-owned production surfaces and validation" do
    guide = read!("docs/deployment.md")

    assert guide =~ "Parapet.Plug.DeployMarker"
    assert guide =~ "mix parapet.gen.prometheus"
    assert guide =~ "mix ecto.migrate"
    assert guide =~ "mix parapet.doctor --ci"
    assert guide =~ ~r/auth|authentication/i
    assert guide =~ ~r/metrics endpoint|\/metrics/i
    assert guide =~ ~r/optional dependenc/i
  end

  test "ExDoc publishes phase 33 guides with docs-local branding assets" do
    docs = project_docs()

    assert Keyword.fetch!(docs, :logo) == "docs/assets/parapet-logo.svg"
    assert Keyword.fetch!(docs, :favicon) == "docs/assets/favicon.svg"

    extras = Keyword.fetch!(docs, :extras)
    assert "docs/migration-v1.md" in extras
    assert "docs/deployment.md" in extras

    groups = Keyword.fetch!(docs, :groups_for_extras)
    guides = Keyword.fetch!(groups, :Guides)
    assert "docs/migration-v1.md" in guides
    assert "docs/deployment.md" in guides

    logo = read!("docs/assets/parapet-logo.svg")
    favicon = read!("docs/assets/favicon.svg")

    for svg <- [logo, favicon] do
      assert svg =~ "width="
      assert svg =~ "height="
      assert svg =~ "viewBox="
    end
  end

  test "package file whitelist still ships docs without adding root assets" do
    files =
      Parapet.MixProject.project()
      |> Keyword.fetch!(:package)
      |> Keyword.fetch!(:files)

    assert "docs" in files

    refute Enum.any?(
             files,
             &(&1 in ["assets", "docs/assets/parapet-logo.svg", "docs/assets/favicon.svg"])
           )
  end

  test "maintainer and contributor docs preserve release ownership contracts" do
    maintaining = read!("MAINTAINING.md")
    contributing = read!("CONTRIBUTING.md")

    assert maintaining =~ "release_gate"
    assert maintaining =~ "Release-As:"
    assert maintaining =~ "do-not-merge"
    assert maintaining =~ "docs/release-policy.md"
    assert maintaining =~ "docs/branch-protection.md"

    assert contributing =~ ~r/Release Please|ReleasePlease/
    assert contributing =~ ~r/stable-line maintenance/i
    assert contributing =~ "feat:"
    assert contributing =~ "fix:"
    assert contributing =~ "docs:"
    assert contributing =~ "refactor:"
    assert contributing =~ "test:"
    assert contributing =~ "chore:"
    assert contributing =~ "BREAKING CHANGE"
  end

  test "demo app docs describe the reproducible Compose smoke path and demo-only boundary" do
    readme = read!("examples/demo_app/README.md")
    makefile = read!("examples/demo_app/Makefile")
    compose = read!("examples/demo_app/docker-compose.yml")

    assert readme =~ "make up"
    assert readme =~ "make urls"
    assert readme =~ "make down"
    assert readme =~ "make reset"
    assert readme =~ "make up-response"
    assert readme =~ "make up-recovery"
    assert readme =~ "make up-escalation"
    assert readme =~ "make up-history"
    assert readme =~ "GRAFANA_ADMIN_USER"
    assert readme =~ "Prometheus"
    assert readme =~ "Grafana"
    assert readme =~ "make up-db-port"
    assert readme =~ ~r/route in this demo app is intentionally\s+open/i
    assert readme =~ "Production deployments must wrap these routes in an authenticated scope"

    assert makefile =~ "docker compose"
    assert makefile =~ "docker-compose"
    assert makefile =~ "PARAPET_DEMO_SCENARIO"
    assert makefile =~ "SCENARIO=response|recovery|escalation|history|all"
    assert compose =~ "WEB_PORT"
    assert compose =~ "GRAFANA_PORT"
    assert compose =~ "PROMETHEUS_PORT"
    assert compose =~ "prom/prometheus"
    assert compose =~ "grafana/grafana"
    assert compose =~ "GF_AUTH_ANONYMOUS_ENABLED=true"
    assert compose =~ "PARAPET_DEMO_SCENARIO"
  end
end
