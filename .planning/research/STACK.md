# Stack Research

**Domain:** Elixir/Phoenix OSS SRE Library — v0.10 Adopter Success
**Researched:** 2026-05-23
**Confidence:** HIGH (all critical decisions verified against official sources or live repo state)

---

## Scope

This document covers only the tooling and configuration additions needed for v0.10's three
pillars: runnable demo harness, docs/packaging, and SLO authoring guidance. It does not
re-research anything already built through v0.9.

---

## Pillar A: Runnable Demo Harness

### Decision: Docker Compose + checked-in example Phoenix app

**Recommended approach:** a `demo/` directory at the repository root containing a minimal
Phoenix app (`demo/app/`) plus a Docker Compose file (`demo/docker-compose.yml`) that
brings up Prometheus, Grafana, and the demo app together.

**Why not a standalone checked-in example app without Docker Compose:**
A raw Phoenix app in `example/` with no infrastructure harness shifts the setup burden
to the adopter. They still have to wire Prometheus and Grafana themselves, which is
exactly the friction the demo is meant to remove. Real adopters evaluating an SRE library
need to see the full loop (metrics → alert → incident → runbook) fire end-to-end, not
just compile and guess.

**Why not Livebook (`.livemd`):**
Livebook requires adopters to run Livebook alongside their app, configure distributed
Erlang/cookies for the attached-node runtime, and still have no Prometheus or Grafana
running. That is three separate infrastructure concerns before the first metric appears.
A `.livemd` is well-suited for interactive exploration of a running system (Fly.io,
Bumblebee demos, etc.) but is the wrong medium for "prove the SRE loop works end-to-end
for a stranger." It also cannot substitute for the demo harness because the SLO burn rate
story requires a live TSDB.

**Why Docker Compose wins for this domain:**
- Single command (`docker compose up`) gives adopters Prometheus (scraping the app),
  Grafana (pre-provisioned dashboards), and the demo Phoenix app in one shot
- prom_ex (the closest Elixir analogue) ships an `example_applications/shared_docker/`
  directory with exactly this pattern — it is the de facto Elixir observability demo idiom
- Docker Compose is universally available to any engineer evaluating an Elixir library and
  requires no Erlang distribution knowledge
- Rot risk is lowest here: the Compose file pins image versions; the demo app pins Parapet
  via a local path reference (`{:parapet, path: "../../"}`), so it exercises the real lib
  and not a stale Hex snapshot
- Grafana Alertmanager tutorial and PromEx both use this exact pattern for demo harnesses

**Directory layout:**

```
demo/
  app/                  # Minimal Phoenix app (mix.exs, lib/, config/, priv/)
    mix.exs             # declares {:parapet, path: "../../"}
  docker-compose.yml    # services: app, prometheus, grafana
  prometheus/
    prometheus.yml      # scrape config pointing at demo app :9568
  grafana/
    provisioning/       # auto-provision Parapet dashboards from priv/parapet/grafana/
```

**files: whitelist impact — ZERO.**
The current whitelist is `~w(lib priv .formatter.exs mix.exs README* docs)`. The `demo/`
directory is not in this list. It will not enter the published Hex package. No change to
`mix.exs` `files:` is needed. This is the critical constraint and it is satisfied
automatically by using a top-level directory not named `lib`, `priv`, or `docs`.

**Demo app deps:**
The demo app's `mix.exs` is independent. It can freely declare `phoenix`, `phoenix_live_view`,
`ecto_sql`, `postgrex`, `oban`, and `parapet` (via local path). These deps never appear in
the published Parapet package.

**What NOT to add:**
- Do not add `demo/` or any `example*/` path to the Parapet `files:` whitelist — demo
  is repo-only
- Do not add demo-specific deps (e.g., `faker`, `phoenix_gen_socket_client`) to the
  top-level Parapet `mix.exs` — they must live only in `demo/app/mix.exs`
- Do not use a Livebook as the primary demo harness — it cannot demonstrate the TSDB loop
- Do not use Mix.install-based standalone scripts — fragile with private hex packages and
  no TSDB

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Docker Compose | v2 (compose spec) | Orchestrate Prometheus + Grafana + demo app | Single-command full-loop demo; universally available; no Erlang distribution required |
| Prometheus | `prom/prometheus:v3.x` | TSDB scraping demo app metrics | Matches what real adopters run; exercises the full recording-rule/alert pipeline |
| Grafana | `grafana/grafana:11.x` | Dashboard visualization | Auto-provision from existing `priv/parapet/grafana/` artifacts; zero dashboard hand-wiring |
| Phoenix (demo app) | `~> 1.7` | Minimal host app exercising Parapet | Demonstrates real install surface; dep declared via `path: "../../"` |

Pin Docker image versions in `docker-compose.yml` to prevent silent upstream breakage.
Use `prom/prometheus:v3.x` and `grafana/grafana:11.x` minor-pinned, not `latest`.

---

## Pillar B: Docs and Packaging

### ExDoc Configuration

**Current state:** mix.exs declares `{:ex_doc, "~> 0.31", only: :dev, runtime: false}`.
Installed version in mix.lock is `0.40.2`. Latest on hex.pm is `0.40.3`.

**Recommendation:** Bump the version constraint to `"~> 0.40"` to pick up 0.40.x
improvements (`.livemd` extras support, better sidebar grouping). No breaking changes
in the 0.31 → 0.40 range for the configuration surface Parapet uses.

**docs: key additions to mix.exs:**

The `project/0` function needs a `:docs` key added alongside the existing `:package` key.
These live at the project level, not inside `package:`.

```elixir
defp project do
  [
    # ... existing keys ...
    docs: docs()
  ]
end

defp docs do
  [
    main: "readme",
    source_url: "https://github.com/szTheory/parapet",
    extras: [
      "README.md",
      "CHANGELOG.md",
      "docs/adopter-flows.md",
      "docs/operator-ui.md",
      "docs/slo-reference.md",
      "docs/telemetry.md"
      # v0.10 additions (new files to create):
      # "docs/getting-started.md",
      # "docs/troubleshooting.md",
      # "docs/integrations/http.md",
      # "docs/integrations/oban.md",
      # "docs/integrations/mailglass.md",
      # "docs/integrations/chimeway.md",
      # "docs/integrations/rindle.md",
      # "docs/slo-packs/saas-api.md",
      # "docs/slo-packs/background-jobs.md",
      # "docs/slo-packs/delivery.md"
    ],
    groups_for_extras: [
      "Getting Started": ~r/docs\/getting-started/,
      "Integration Guides": ~r/docs\/integrations\//,
      "SLO Authoring": ~r/docs\/slo-packs\//,
      "Reference": ~r/docs\/(adopter-flows|operator-ui|slo-reference|telemetry)/,
      "Project": ["CHANGELOG.md"]
    ],
    groups_for_modules: [
      "SLO Engine": ~r/Parapet\.SLO/,
      "Runbooks": ~r/Parapet\.Runbook/,
      "Incident Management": ~r/Parapet\.(Incident|Evidence|Timeline)/,
      "Escalation": ~r/Parapet\.Escalation/,
      "Integrations": ~r/Parapet\.Integrations/,
      "Generators": ~r/Mix\.Tasks\.Parapet/,
      "Internals": ~r/Parapet\.Internal/
    ],
    nest_modules_by_prefix: [Parapet]
  ]
end
```

**Confidence:** HIGH — verified against ExDoc v0.40.x docs, ecto/mix.exs, req/mix.exs,
and ex_doc/mix.exs as authoritative real-world references.

### Package links: metadata

The current `links: %{}` is empty. Standard keys used by well-maintained Elixir packages
(verified from ecto, req, ex_doc themselves):

```elixir
package: [
  files: ~w(lib priv .formatter.exs mix.exs README* docs CHANGELOG*),
  licenses: ["MIT"],
  links: %{
    "GitHub" => "https://github.com/szTheory/parapet",
    "Changelog" => "https://hexdocs.pm/parapet/changelog.html"
  }
]
```

**"GitHub" and "Changelog" are the canonical two keys.** A "Docs" key pointing at
hexdocs.pm/parapet is redundant — Hex already renders the HexDocs link automatically.
Do not add "Issues" or "Sponsor" unless there is a specific reason; they clutter
the package sidebar.

**files: note:** Add `CHANGELOG*` to the whitelist so the generated CHANGELOG.md is
included in the published package and the `"Changelog"` link resolves correctly on
hexdocs.pm. The current whitelist does not include it.

### CHANGELOG.md and Release Please

**Release Please owns CHANGELOG.md — do not hand-edit it.**

Verification (HIGH confidence from elixirschool.com and googleapis/release-please):
- Release Please with `release-type: elixir` (as configured in `.github/workflows/release-please.yml`)
  automatically generates and maintains CHANGELOG.md
- On each merge to `main`, Release Please updates or creates a Release PR that bumps
  `mix.exs` version and prepends a new section to CHANGELOG.md
- Merging that Release PR tags the commit, creates a GitHub Release, and the CHANGELOG.md
  state in the repo is authoritative

**What humans do and do not touch:**

| Surface | Owner | Human action |
|---------|-------|--------------|
| `CHANGELOG.md` content | Release Please | None — do not manually edit; it regenerates from Conventional Commits |
| Commit messages | Developer | Must follow Conventional Commits (`feat:`, `fix:`, `docs:`, etc.) — this is the only human input to changelog quality |
| Release PR | Developer | Review and merge when ready to ship; no content editing needed |
| `.release-please-manifest.json` | Release Please | Auto-created on first run if absent; do not pre-create it |
| `release-please-config.json` | Optional human | Add only if needing multi-package or extra-files configuration |

**For v0.10:** The repo has no `.release-please-manifest.json` and no `release-please-config.json`.
This is correct for a simple single-package repo using the default `release-type: elixir` action.
Release Please will create the manifest on first successful release. No configuration files
need to be added unless extra-files tracking (e.g., auto-bumping a version constant elsewhere)
is needed.

**CHANGELOG.md initial state:** Since no CHANGELOG.md exists yet, Release Please will create
it on the first Release PR merge. Optionally, a minimal `CHANGELOG.md` stub can be committed
manually as a placeholder for hexdocs to render before the first Release Please run — but keep
it to a header only and let Release Please own all content below it.

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ex_doc | `~> 0.40` | Hexdocs HTML + sidebar generation | Bump from `~> 0.31`; enables clean extras grouping and `.livemd` support |

No other new libraries needed for the docs/packaging pillar.

---

## Pillar C: SLO Authoring Guidance

### Decision: Pure docs + provider modules — no new library

**Recommendation: do not add a new `mix parapet.gen.slo` task or a separate SLO-pack
catalog module. This is pure docs work plus adding new `Parapet.SLO.StarterPack.*`
modules using the existing `Parapet.SLO.Provider` behaviour.**

**Rationale:**

The SLO engine is complete and expressive. The `Parapet.SLO.Provider` behaviour and the
`Parapet.SLO.SliceSpec` struct are the correct extension point. The gap identified in
JTBD-MAP gap #3 is a **guidance gap**, not a capability gap. Adopters cannot choose good
first SLOs not because the engine cannot express them, but because there are no
opinionated defaults to copy.

The correct solution is:
1. New provider modules that ship pre-configured `SliceSpec` structs for common app types
   (SaaS API, background-job-heavy, delivery-heavy)
2. A `docs/slo-packs/` guide directory with examples, good-vs-bad journey-slicing
   comparisons, and low-traffic alerting guidance
3. A `mix parapet.gen.slo` Mix task only if there is genuine evidence that adopters need
   interactive scaffolding — the existing `mix parapet.install --with-*` flags cover
   registration already; a new task risks duplicating that surface

**No new deps are warranted for this pillar.** The existing `Parapet.SLO.Generator`
handles PromQL generation. New provider modules live in `lib/parapet/slo/`. The docs
live in `docs/slo-packs/` and will be in the `files:` whitelist via `docs`.

**What the starter pack modules look like:**
New modules following the existing `Parapet.SLO.Provider` pattern, e.g.:
- `Parapet.SLO.Pack.SaasApi` — HTTP error rate, latency P95, availability per route group
- `Parapet.SLO.Pack.BackgroundJobs` — Oban queue failure rate, throughput, latency
- `Parapet.SLO.Pack.Delivery` — Wraps the existing Mailglass/Chimeway providers with
  opinionated objectives rather than requiring adopters to tune them

These are registered the same way as existing built-in providers:

```elixir
config :parapet,
  providers: [Parapet.SLO.Pack.SaasApi]
```

**Runbook template enrichment:**
The existing four `priv/templates/parapet.gen.runbooks/*.ex.eex` templates are thin
(1-2 steps, no preconditions, no warning text). Richer templates with explicit preconditions,
warnings, and `guidance:` text are the right v0.10 deliverable for gap #1 (common recovery
depth). This is purely template content work — no new EEx tooling is needed. The existing
Igniter-based `mix parapet.gen.runbooks` generator already reads from `priv/templates/`.

**What NOT to add:**
- Do not add a `mix parapet.gen.slo` interactive task — complexity without evidence of need;
  `mix parapet.install --with-<pack>` flags are the correct registration surface
- Do not add a `Parapet.SLO.Catalog` GenServer or runtime registry — the compile-time
  Provider behaviour is correct; a catalog module risks becoming a second, unsynchronized
  registry
- Do not pull in external SLO library deps (e.g., `prometheus_plugs`, `telemetry_metrics_prometheus`)
  — Parapet already owns the full metrics/SLO stack and these would conflict

---

## Installation Changes

The only mix.exs changes needed for v0.10:

```elixir
# 1. Bump ex_doc constraint
{:ex_doc, "~> 0.40", only: :dev, runtime: false}

# 2. Add docs: key to project/0 (new function defp docs())
# 3. Add links: and CHANGELOG* to package/0
```

No new runtime deps. No new optional deps. No new applications. The demo app in `demo/`
is fully isolated with its own `mix.exs`.

---

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| `demo/` Docker Compose | Livebook `.livemd` | Requires distributed Erlang setup; no TSDB; wrong medium for full SRE loop |
| `demo/` Docker Compose | Standalone example Phoenix app (no Docker) | Shifts Prometheus/Grafana setup to adopter; breaks the "single command" promise |
| Pure docs + provider modules for SLO packs | New `mix parapet.gen.slo` task | No evidence of need; install flags already cover registration; adds surface to maintain |
| Pure docs + provider modules for SLO packs | `Parapet.SLO.Catalog` GenServer | Second registry risks drift from Provider behaviour; compile-time is already correct |
| ExDoc `groups_for_extras` for sidebar | Flat extras list | Flat list gives no navigation for 8+ guide pages; groups are necessary at this scale |
| Release Please owns CHANGELOG.md fully | Human-maintained CHANGELOG | Defeats the existing Conventional Commits + Release Please investment; causes merge conflicts |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Adding `demo/` to `files:` whitelist | Leaks demo deps and Phoenix app into published package | Keep `demo/` out of whitelist; it is git-only |
| `{:ex_doc, "~> 0.31"}` (current) | Pins below current 0.40.x line; misses sidebar grouping improvements | `"~> 0.40"` |
| `links: %{"Docs" => ...}` | Hex renders HexDocs link automatically; redundant | `"GitHub"` and `"Changelog"` only |
| Hand-editing CHANGELOG.md | Conflicts with Release Please automation | Write good Conventional Commit messages; let Release Please generate changelog |
| New `Parapet.SLO.Catalog` module | Second registry drifts from Provider behaviour | More provider modules using existing `Parapet.SLO.Provider` behaviour |
| Demo deps in top-level mix.exs | Pollutes published package dep tree | Demo deps declared only in `demo/app/mix.exs` |

---

## Version Compatibility

| Package | Current Constraint | Recommended Constraint | Notes |
|---------|-------------------|-----------------------|-------|
| ex_doc | `~> 0.31` | `~> 0.40` | Current locked: 0.40.2; latest: 0.40.3; no breaking changes in range |
| Phoenix (demo app only) | n/a | `~> 1.7` | In `demo/app/mix.exs` only; not in published package |
| Prometheus image | n/a | `v3.x` | Pin in `docker-compose.yml`; not a mix dep |
| Grafana image | n/a | `11.x` | Pin in `docker-compose.yml`; not a mix dep |

---

## Files: Whitelist Audit

Current: `~w(lib priv .formatter.exs mix.exs README* docs)`

Recommended changes for v0.10:

```elixir
files: ~w(lib priv .formatter.exs mix.exs README* docs CHANGELOG*)
```

| Path | In whitelist? | Correct? | Action |
|------|--------------|---------|--------|
| `lib/` | Yes | Yes | No change |
| `priv/` | Yes | Yes | No change (runbook templates live here) |
| `docs/` | Yes | Yes | New guide files added here are included automatically |
| `README*` | Yes | Yes | No change |
| `CHANGELOG*` | **No** | **Should be Yes** | Add `CHANGELOG*` — needed for `"Changelog"` link to resolve on hexdocs |
| `demo/` | No | Correct | Do NOT add — demo is repo-only |
| `.planning/` | No | Correct | Do NOT add |

---

## Sources

- `https://hexdocs.pm/ex_doc/ExDoc.html` — ExDoc configuration options (HIGH confidence, official)
- `https://github.com/elixir-ecto/ecto/blob/master/mix.exs` — links: keys pattern ("GitHub", "Changelog") (HIGH confidence, canonical OSS reference)
- `https://github.com/wojtekmach/req/blob/main/mix.exs` — extras + CHANGELOG pattern (HIGH confidence)
- `https://github.com/elixir-lang/ex_doc/blob/main/mix.exs` — groups_for_extras, module grouping (HIGH confidence)
- `https://elixirschool.com/blog/managing-releases-with-release-please` — Release Please Elixir CHANGELOG ownership (HIGH confidence)
- `https://hex.pm/packages/ex_doc` — current version 0.40.3 (HIGH confidence, verified live)
- `https://github.com/akoutmos/prom_ex` — `example_applications/` demo pattern with Docker Compose (MEDIUM confidence, verified structure)
- Repository state: `mix.exs`, `mix.lock`, `.github/workflows/release-please.yml`, `priv/templates/parapet.gen.runbooks/` (HIGH confidence, read directly)

---

*Stack research for: Parapet v0.10 Adopter Success*
*Researched: 2026-05-23*
