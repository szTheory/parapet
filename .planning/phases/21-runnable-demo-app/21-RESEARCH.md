# Phase 21: Runnable Demo App - Research

**Researched:** 2026-05-25
**Domain:** Phoenix demo app scaffold, CI gate design, Hex exclusion verification
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Demo App Structure (DEMO-01)**
- D-01: Standalone committed Phoenix app at `examples/demo_app/` — not an umbrella child.
- D-02: `mix setup` = `deps.get → ecto.create → ecto.migrate → run priv/repo/seeds.exs`. Demo supplies its own `DemoApp.Repo` and registers it via `Application.put_env(:parapet, :repo, DemoApp.Repo)` (or config).
- D-03: Phoenix version `~> 1.7`. Research confirms latest stable is `1.8.7`.

**Seeding Strategy (DEMO-02)**
- D-04: Seeds call Stable `Parapet.Evidence.*` API exclusively — `create_incident/1`, `append_timeline/2`, `log_tool_audit/1`. No direct `Repo.insert(%Incident{})` for incidents.
- D-05: Runbook with `warning:` step seeded as static JSON map written to `Incident.runbook_data`. Shape: `%{"title" => "...", "description" => "...", "steps" => [%{"id" => ..., "label" => ..., "warning" => "...", ...}]}`.
- D-06: Seed coverage — open/investigating/resolved incidents; ≥2 timeline entries each; ≥1 tool audit; ≥1 runbook-with-warning; WebSaaS SLO registered via config.

**CI Gate Design (DEMO-03)**
- D-07: `demo` job inside existing `.github/workflows/ci.yml`. New `release_gate` job with `needs: [test, demo]`. No `continue-on-error`.
- D-08: Smoke test via `Phoenix.ConnTest` (no running server). Tag `@tag :smoke`. CI runs `cd examples/demo_app && mix test --only smoke`. Asserts: GET /parapet = 200, at least one Incident record in DB.
- D-09: Same Elixir/OTP as `test` job (1.19.0 / OTP 27.2). PostgreSQL service via `services:` block.

**Hex Exclusion & Docs Link (DEMO-04)**
- D-10: `examples/demo_app/` already excluded — `files:` whitelist does not include `examples/`. No `mix.exs` change needed.
- D-11: "Next steps" bullet added to `docs/getting-started.md` linking to GitHub tree URL.

**Demo App Auth**
- D-12: Routes mounted open (no auth) with prominent `# WARNING: demo only` comment in router. GET /parapet must return 200 directly.

### Claude's Discretion
- Exact Phoenix version within `~> 1.7` — research confirms **1.8.7** (current lock file has 1.8.7 as transitive dep; latest stable on Hex.pm confirmed 1.8.7).
- Demo app module naming — research recommends **`DemoApp`** (see Q14 below).
- Exact set of seed incidents beyond minimum.
- PostgreSQL vs SQLite for CI — research recommends **PostgreSQL with service container** for realism and consistency with D-09.
- Exact `release_gate` job structure — research recommends **minimal fan-in job** (no extra steps, just `needs:` + a trivial `run: echo` step to satisfy GitHub Actions requirements).

### Deferred Ideas (OUT OF SCOPE)
- None specified in CONTEXT.md.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-01 | Runnable demo Phoenix app at `examples/demo_app/` with `mix setup && mix phx.server` serving Operator UI at `/parapet` | Generator output files, router pattern, Application.get_env(:parapet, :repo) pattern all verified |
| DEMO-02 | Seeded with open/investigating/resolved incidents, timeline entries, tool audit, runbook with warning: step, WebSaaS SLO state | Evidence API signatures verified, runbook_data shape verified against WorkbenchContract.derive/3 |
| DEMO-03 | Smoke test returning 200, at least one incident, wired as required CI gate in release_gate, no continue-on-error | CI structure verified, Phoenix.ConnTest pattern established |
| DEMO-04 | Excluded from Hex package (verified), linked from getting-started guide "Next steps" section | files: whitelist confirmed, getting-started.md lines 94-99 identified |
</phase_requirements>

---

## Summary

Phase 21 builds `examples/demo_app/` — a full, committed Phoenix 1.8.7 child app with a path dep on parapet, seeded Postgres incidents, and a Phoenix.ConnTest smoke test wired into a new `release_gate` CI job.

All 14 research questions are answered with codebase evidence below. The key findings:

1. **The Incident schema has no `source` or `alert_name` fields** — CONTEXT.md references these incorrectly. The actual castable fields are: `title`, `description`, `state`, `correlation_key`, `trace_id`, `runbook_data`. Seeds must use only these.
2. **The `runbook_data` map uses string keys** when read by WorkbenchContract — seed the map with string keys (`"title"`, `"steps"`, etc.) and step maps also with string keys. The Runbook DSL `__runbook_schema__/0` returns atom-keyed maps (`:id`, `:label`, `:warning`, etc.) but WorkbenchContract.derive/3 calls `stringify_keys/1` on each step, so either atom or string keys work. For static seed data, **use string keys throughout** to avoid serialization surprises via Ecto's `:map` type (which round-trips through JSON, converting atoms to strings).
3. **The main `test` CI job has no explicit postgres service** — it relies on the pre-installed PostgreSQL on the ubuntu-latest runner. The `demo` job must use an explicit `services: postgres:` block because it is a separate job running in its own container context.
4. **The `mix parapet.gen.ui` generator generates 3 files** (operator_live.ex, operator_detail_live.ex, operator_components.ex) into `lib/<app_name>_web/live/parapet/` and emits a router notice. For the demo, commit the generated output directly — do not re-run the generator in CI.
5. **Phoenix.ConnTest smoke test requires the demo app's Endpoint to be in the conn test setup** — use `use DemoAppWeb.ConnCase` (which the demo app must define) or directly use `Phoenix.ConnTest` with `@endpoint DemoAppWeb.Endpoint`.

**Primary recommendation:** Build the demo app as a committed Phoenix 1.8.7 app with PostgreSQL, seed using `Parapet.Evidence.*` Stable API only, run the smoke test with a dedicated postgres service container in CI, and add `release_gate: needs: [test, demo]` as a fan-in gate.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Demo app Phoenix endpoint | Frontend Server (demo app) | — | DemoApp.Endpoint starts the app, serves LiveView |
| Operator UI LiveView | Frontend Server (demo app) | API/Backend (parapet library) | Generated LiveView in demo app calls Parapet.Operator.* |
| Incident storage | Database/Storage | — | PostgreSQL via DemoApp.Repo, parapet spine tables |
| Seed data | Database/Storage | — | `priv/repo/seeds.exs` inserts via Evidence API |
| CI smoke test | CI/Test | — | Phoenix.ConnTest against demo app's endpoint |
| Hex exclusion | Build artifact | — | `files:` whitelist in parapet's mix.exs (already correct) |
| Getting-started link | Documentation | — | `docs/getting-started.md` edit only |

---

## Research Question Answers

### Q1: Phoenix version for the demo

**Answer:** Use `{:phoenix, "~> 1.8"}` which resolves to **1.8.7** (current latest stable). [VERIFIED: hex.pm/packages/phoenix]

The parapet library's existing `mix.lock` already carries `phoenix 1.8.7` as a transitive dependency from `sigra`. The demo app's own `mix.lock` will independently resolve to the same version since `~> 1.8` is satisfied by 1.8.7.

**Dep entry:**
```elixir
{:phoenix, "~> 1.8"}
```

### Q2: Exact `__runbook_schema__/0` output shape

**Answer:** [VERIFIED: lib/parapet/runbook.ex, lib/parapet/operator/workbench_contract.ex]

`Parapet.Runbook.__runbook_schema__/0` returns a map with **atom keys**:

```elixir
%{
  module: "Elixir.DemoApp.LoginFailureRunbook",   # string (to_string(__MODULE__))
  title: "Login Failure Runbook",                   # atom key
  description: "Runbook for login failures",        # atom key
  steps: [                                          # atom key, list of maps with atom keys
    %{
      id: :check_metrics,
      label: "Check metrics",
      description: "Verify DB connection pool",
      type: :manual,
      kind: :guidance,
      capability: nil,
      target_kind: nil,
      requires_preview: false,
      preview_only: false,
      auto_execute: false,
      guidance: nil,
      warning: "High cardinality risk — check for label explosion"
    },
    %{
      id: :acknowledge,
      label: "Acknowledge",
      description: "Acknowledge the incident",
      type: :manual,
      kind: :guidance,
      ...
      warning: nil
    }
  ]
}
```

**CRITICAL: When storing in `runbook_data` (an Ecto `:map` field)**, the map is serialized to PostgreSQL JSONB, which converts **atom keys to string keys on round-trip**. When WorkbenchContract reads it back, it calls `stringify_keys/1` explicitly. Therefore, **seed `runbook_data` with string keys** to avoid confusion:

```elixir
runbook_data: %{
  "title" => "Login Failure Runbook",
  "description" => "Steps to diagnose and mitigate login failures",
  "steps" => [
    %{
      "id" => "check_metrics",
      "label" => "Check metrics",
      "description" => "Verify DB connection pool and error rate",
      "type" => "manual",
      "kind" => "guidance",
      "warning" => "High cardinality risk — check for label explosion before proceeding",
      "guidance" => nil,
      "requires_preview" => false,
      "preview_only" => false,
      "auto_execute" => false
    },
    %{
      "id" => "acknowledge",
      "label" => "Acknowledge incident",
      "description" => "Confirm incident is being investigated",
      "type" => "manual",
      "kind" => "guidance",
      "warning" => nil,
      "guidance" => nil,
      "requires_preview" => false,
      "preview_only" => false,
      "auto_execute" => false
    }
  ]
}
```

The `"module"` key is optional for display-only seeds (Operator UI renders runbook steps without needing to dynamically invoke the module). Include it if testing runbook dispatch; omit it to keep seed data purely display-focused per D-05.

### Q3: Does `Parapet.Evidence.create_incident/1` exist and what are its parameters?

**Answer:** [VERIFIED: lib/parapet/evidence.ex lines 57-68]

Yes. Signature: `create_incident(attrs \\ %{})` — returns `{:ok, incident}` or `{:error, changeset}`.

**Castable fields** (from `Parapet.Spine.Incident.changeset/2`, verified at lib/parapet/spine/incident.ex):
- `title` (required, string)
- `description` (string)
- `state` (default `"open"`, validated to: `"open"`, `"investigating"`, `"resolved"`)
- `correlation_key` (string)
- `trace_id` (string)
- `runbook_data` (map)

**There is NO `source` or `alert_name` field in the Incident schema.** The CONTEXT.md mention of these fields is incorrect — they do not exist in the actual schema. Seeds must use only the fields listed above.

**Example usage:**
```elixir
{:ok, incident} = Parapet.Evidence.create_incident(%{
  title: "Login service elevated error rate",
  description: "Auth endpoint returning 5xx > 2% for 10 min",
  state: "open",
  runbook_data: %{
    "title" => "Login Failure Runbook",
    "steps" => [...]
  }
})
```

The function runs an `Ecto.Multi` transaction and optionally enqueues an escalation job if `Parapet.Escalation.Worker` is loaded and `:escalation_policy` is configured. In the demo app, neither will be configured, so the multi reduces to a single insert.

### Q4 & Q5: Does `parapet.gen.ui` work standalone? What does it generate?

**Answer:** [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex, priv/templates/parapet.gen.ui/]

`mix parapet.gen.ui` uses Igniter and generates **3 files** into `lib/<app_name>_web/live/parapet/`:

| Generated File | Destination (for DemoApp) |
|---------------|--------------------------|
| `operator_live.ex.eex` → `operator_live.ex` | `lib/demo_app_web/live/parapet/operator_live.ex` |
| `operator_detail_live.ex.eex` → `operator_detail_live.ex` | `lib/demo_app_web/live/parapet/operator_detail_live.ex` |
| `operator_components.ex.eex` → `operator_components.ex` | `lib/demo_app_web/live/parapet/operator_components.ex` |

The generator also emits an Igniter notice with a commented router snippet (it does NOT directly patch the router — it just prints the snippet to stdout).

**Can we commit generated output directly?** Yes — and this is the correct approach per D-01 and the prior art (V1-DEMO-APP.md Section 6, point 2). The demo ships the committed output of running the generator against `DemoApp`. CI does NOT re-run the generator. This proves the generator works and shows adopters what a post-install app looks like.

**Generator assigns used:**
- `web_module`: `DemoAppWeb`
- `app_name`: `:demo_app`
- `repo_module`: `DemoApp.Repo`

The generated files reference these as: `use DemoAppWeb, :live_view`, `DemoApp.Repo.get!(...)`, etc.

### Q6: Current structure of `priv/templates/parapet.gen.ui/`

**Answer:** [VERIFIED: filesystem listing]

```
priv/templates/parapet.gen.ui/
  operator_components.ex.eex   # OperatorComponents module (~720 lines, all UI components)
  operator_detail_live.ex.eex  # OperatorDetailLive (mobile detail view)
  operator_live.ex.eex         # OperatorLive (main queue + detail split view)
  router_snippet.ex.eex        # Commented-out router example (printed as notice, not injected)
```

The `router_snippet.ex.eex` produces a commented-out scope with auth guidance. The demo router should NOT use this authenticated snippet — it should mount open routes directly per D-12.

### Q7 & Q8: Does `mix parapet.install` need to run? What are the generated outputs to commit?

**Answer:** [VERIFIED: lib/mix/tasks/parapet.install.ex, lib/mix/tasks/parapet.gen.spine.ex]

`mix parapet.install` composes: `parapet.gen.spine`, `parapet.gen.prometheus`, `parapet.gen.ui`, and optionally `parapet.gen.scoria`.

`parapet.gen.spine` generates a migration named `add_parapet_spine_tables` that creates all 5 spine tables. The demo app must have this migration committed (not regenerate it at CI time).

For the demo app, we commit the outputs of running these generators once locally:
1. **Migration** from `mix parapet.gen.spine` (or `mix parapet.install`): `priv/repo/migrations/<timestamp>_add_parapet_spine_tables.exs`
2. **LiveView files** from `mix parapet.gen.ui`: the 3 files listed in Q5
3. **Parapet Instrumenter module**: `lib/demo_app/parapet_instrumenter.ex` (output of `mix parapet.install`)

The Prometheus files (`priv/parapet/prometheus/`) are generated by `mix parapet.gen.prometheus` but are not required for the demo to serve the Operator UI — they are for Prometheus scraping, not for the LiveView. Omit or include optionally.

### Q9: Existing `examples/` or `demo_app/` files

**Answer:** [VERIFIED: filesystem] None exist. `ls examples/` returns "NO EXAMPLES DIR". The entire `examples/demo_app/` tree must be created from scratch.

### Q10: `Application.get_env(:parapet, :repo)` pattern

**Answer:** [VERIFIED: lib/parapet/evidence.ex line 24, lib/parapet/operator/workbench_contract.ex]

`Parapet.Evidence.repo/0` calls:
```elixir
Application.get_env(:parapet, :repo) ||
  raise ArgumentError, "Parapet requires a :repo to be configured..."
```

This is used throughout the library (Evidence, Operator, all DB access paths). The demo must set this before any Evidence/Operator calls. Two valid patterns:

**Option A — config file (preferred for demo):**
```elixir
# examples/demo_app/config/config.exs
config :parapet, repo: DemoApp.Repo
```

**Option B — Application.put_env in seeds:**
```elixir
# examples/demo_app/priv/repo/seeds.exs
Application.put_env(:parapet, :repo, DemoApp.Repo)
```

Option A is preferred because it ensures the repo is configured before the application starts, covering all runtime paths including the LiveView.

### Q11: Operator UI LiveView socket config requirements (PubSub, etc.)

**Answer:** [VERIFIED: grep across lib/ — no PubSub references in parapet library code]

The parapet library itself has **no PubSub requirement**. The generated `OperatorLive` handles `handle_info(:parapet_queue_changed, socket)` but this is only called if something broadcasts to the socket — it's not a startup requirement.

The demo app needs:
- Standard Phoenix endpoint with LiveView socket (`/live`) configured
- `phoenix_live_view` dep
- `Phoenix.PubSub` started in the supervisor (standard Phoenix app includes this by default with `phoenix_pubsub`)

**No special parapet-specific PubSub subscription is needed.** The `queue_refresh_available?` UI feature simply won't fire unless a broadcaster is wired up — which is fine for a demo.

### Q12: PostgreSQL version for CI postgres service

**Answer:** Use `postgres:16-alpine` in the demo CI job's services block.

Rationale: The main `test` job relies on the pre-installed PostgreSQL on the ubuntu-latest runner (currently PostgreSQL 16 on ubuntu-24.04). Using the same major version avoids behavioral divergence. The alpine variant is lighter for CI.

```yaml
services:
  postgres:
    image: postgres:16-alpine
    env:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: demo_app_test
    ports: ['5432:5432']
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

**Note on main `test` job postgres:** The existing `test` job has NO explicit postgres service container — it relies on the pre-installed PostgreSQL on ubuntu-latest runner (started by default on GitHub-hosted runners). The `test_helper.exs` calls `ConcurrencyRepo.start_link(config)` with `hostname: localhost, username: postgres, password: postgres` — which works against the runner's pre-installed postgres. The `demo` job must use an explicit service container because it runs in a clean job context.

### Q13: Seed strategy — Evidence API vs direct Repo inserts

**Answer:** [VERIFIED per D-04, CONTEXT.md]

Seeds use **`Parapet.Evidence.*` Stable API exclusively** for all incident, timeline, and tool audit creation. The smoke test may use direct `DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count)` for the count assertion — this is acceptable in a test context (D-08 explicitly permits it).

**One nuance with `log_tool_audit/1`:** The function signature shows it takes `attrs \\ %{}` and requires `tool_name`, `input`, and `success` per the ToolAudit changeset. The `audit_mode` config defaults to `:dual_write` which writes to DB and emits telemetry — this is fine for seeds (telemetry handlers may or may not be attached; `:telemetry.execute/3` is safe regardless).

Example seed call:
```elixir
{:ok, _audit} = Parapet.Evidence.log_tool_audit(%{
  tool_name: "parapet_doctor",
  input: %{"env" => "dev"},
  output: %{"status" => "ok", "findings" => []},
  success: true,
  duration_ms: 42
})
```

### Q14: Module name convention for demo app

**Answer (Claude's discretion):** Use **`DemoApp`** (not `ParapetDemo`).

Rationale:
- `DemoApp` is shorter and more idiomatic for a `mix new demo_app` scaffold
- It communicates "this is a demo of a host app" more clearly than `ParapetDemo` which sounds like a sub-module of Parapet
- The generator produces `DemoAppWeb` as the web module, which reads naturally
- The PromEx precedent uses `WebApp` / `WebAppWeb` for similar demo apps

**Module names generated:**
- App module: `DemoApp`
- Web module: `DemoAppWeb`
- Repo: `DemoApp.Repo`
- Endpoint: `DemoAppWeb.Endpoint`
- Router: `DemoAppWeb.Router`

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.8` (resolves 1.8.7) | Web framework for demo app | Required for Operator UI LiveView; already in parapet lock file [VERIFIED: mix.lock] |
| `phoenix_live_view` | `~> 1.1` (resolves 1.1.30) | LiveView for Operator UI | Generated templates use LiveView; already in lock file [VERIFIED: mix.lock] |
| `phoenix_ecto` | `~> 4.4` | Ecto-Phoenix integration | Standard Phoenix + Ecto bridge [VERIFIED: hex.pm, version 4.7.0] |
| `ecto_sql` | `~> 3.10` | Ecto SQL adapter | Matches parapet's own constraint [VERIFIED: mix.exs] |
| `postgrex` | `~> 0.20` | PostgreSQL driver | Matches parapet's own constraint [VERIFIED: mix.exs] |
| `bandit` | `~> 1.5` | HTTP server | Modern Phoenix default (replaces Cowboy in Phoenix 1.7+) [VERIFIED: hex.pm, version 1.11.1] |
| `parapet` | `path: "../.."` | Library under test | Path dep ensures demo tracks HEAD [VERIFIED: V1-DEMO-APP.md] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | `~> 4.1` | HTML helpers | Required by phoenix_live_view [VERIFIED: mix.lock] |
| `jason` | `~> 1.2` | JSON encode/decode | Required by Phoenix for JSON; standard |
| `heroicons` | `~> 0.5` | Icon set | Standard Phoenix 1.7+ default; used in generated LiveView components |
| `tailwind` | `~> 0.2` | CSS utility framework | Standard Phoenix 1.7+ default; generated templates use Tailwind classes |

**Note on heroicons/tailwind:** The generated `operator_components.ex.eex` uses Tailwind CSS classes throughout (e.g. `bg-gray-50`, `flex`, `md:flex-row`) and SVG icons inline. The demo app needs a working Tailwind build or the CSS classes will have no effect (the HTML renders but looks unstyled). For the smoke test (GET /parapet = 200), styling does not affect correctness. For the human-facing demo, Tailwind should be configured.

### Demo app `mix.exs` deps section (complete)

```elixir
defp deps do
  [
    {:parapet, path: "../.."},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.20"},
    {:bandit, "~> 1.5"},
    {:phoenix_html, "~> 4.1"},
    {:jason, "~> 1.2"},
    {:heroicons,
     github: "tailwindlabs/heroicons",
     tag: "v2.1.1",
     sparse: "optimized",
     app: false,
     compile: false,
     depth: 1},
    {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
    # Test only
    {:phoenix_live_view, "~> 1.1", only: :test, override: true}
  ]
end
```

**Simpler alternative for smoke-test-only demo** (no Tailwind build needed):
```elixir
defp deps do
  [
    {:parapet, path: "../.."},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    {:phoenix_ecto, "~> 4.4"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.20"},
    {:bandit, "~> 1.5"},
    {:phoenix_html, "~> 4.1"},
    {:jason, "~> 1.2"}
  ]
end
```

The simpler form is recommended — heroicons and tailwind are compile-time only and the smoke test does not require styled output. The planner should decide based on whether the "human-facing demo" goal requires a styled UI.

---

## Package Legitimacy Audit

All packages listed are long-established components of the official Phoenix ecosystem. No new/obscure packages are introduced. All are confirmed in parapet's existing `mix.lock` as transitive dependencies.

| Package | Registry | Age | Downloads | Source Repo | Disposition |
|---------|----------|-----|-----------|-------------|-------------|
| phoenix | hex.pm | ~10 yrs | Very high | phoenixframework/phoenix | Approved [VERIFIED: mix.lock] |
| phoenix_live_view | hex.pm | ~5 yrs | Very high | phoenixframework/phoenix_live_view | Approved [VERIFIED: mix.lock] |
| phoenix_ecto | hex.pm | ~10 yrs | Very high | phoenixframework/phoenix_ecto | Approved [ASSUMED — not in lock file but standard Phoenix ecosystem] |
| ecto_sql | hex.pm | ~7 yrs | Very high | elixir-ecto/ecto_sql | Approved [VERIFIED: mix.exs] |
| postgrex | hex.pm | ~10 yrs | Very high | elixir-ecto/postgrex | Approved [VERIFIED: mix.exs] |
| bandit | hex.pm | ~3 yrs | High | mtrudel/bandit | Approved [VERIFIED: mix.lock] |
| jason | hex.pm | ~7 yrs | Very high | michalmuskala/jason | Approved [VERIFIED: mix.lock] |

**Packages removed due to slopcheck [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
          Developer / CI runner
                |
       mix test --only smoke
                |
      DemoApp.ConnCase (Phoenix.ConnTest)
                |
       [Phoenix dispatch — no running server]
                |
       DemoAppWeb.Endpoint
                |
       DemoAppWeb.Router
       scope "/parapet" (open, no auth)
                |
         Phoenix.LiveView
         OperatorLive (generated by parapet.gen.ui)
                |
         Parapet.Operator.list_incident_queue/1
         Parapet.Operator.incident_detail/1
                |
         Application.get_env(:parapet, :repo)
                |
         DemoApp.Repo  ←──── config :parapet, repo: DemoApp.Repo
                |
         PostgreSQL (parapet_incidents, parapet_timeline_entries, etc.)
                ↑
         priv/repo/seeds.exs
         Parapet.Evidence.create_incident/1
         Parapet.Evidence.append_timeline/2
         Parapet.Evidence.log_tool_audit/1
```

### Recommended Project Structure

```
examples/demo_app/
  mix.exs                          # path dep on parapet, phoenix, ecto, postgrex
  mix.lock                         # locked deps for reproducibility
  .formatter.exs                   # standard Phoenix formatter config
  README.md                        # "Clone, mix setup, visit /parapet"
  config/
    config.exs                     # config :parapet, repo: DemoApp.Repo
                                   # config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]
    dev.exs                        # dev endpoint config (debug_errors, etc.)
    test.exs                       # test DB config, Sandbox pool
  lib/
    demo_app/
      application.ex               # starts DemoApp.Repo, DemoAppWeb.Endpoint
      parapet_instrumenter.ex      # committed output of mix parapet.install
      repo.ex                      # use Ecto.Repo, otp_app: :demo_app, adapter: Ecto.Adapters.Postgres
    demo_app_web/
      endpoint.ex                  # plug Parapet.Plug.Metrics; socket "/live", Phoenix.LiveView.Socket
      router.ex                    # scope "/parapet" → OperatorLive (open, WARNING comment)
      live/
        parapet/
          operator_live.ex         # committed output of mix parapet.gen.ui
          operator_detail_live.ex  # committed output of mix parapet.gen.ui
          operator_components.ex   # committed output of mix parapet.gen.ui
  priv/
    repo/
      migrations/
        <timestamp>_add_parapet_spine_tables.exs   # output of mix parapet.gen.spine
      seeds.exs                    # seeding via Parapet.Evidence.* Stable API
  test/
    test_helper.exs                # ExUnit.start(); Ecto.Adapters.SQL.Sandbox.mode(...)
    support/
      conn_case.ex                 # DemoAppWeb.ConnCase using Phoenix.ConnTest
      data_case.ex                 # DemoApp.DataCase using Ecto sandbox
    demo_app/
      operator_smoke_test.exs      # @tag :smoke; GET /parapet = 200; incident count > 0
```

### Pattern 1: Demo Repo Configuration

**What:** Register `DemoApp.Repo` as the `:parapet` repo via application config.
**When to use:** Always — the library reads `Application.get_env(:parapet, :repo)` on every Evidence/Operator call.
**Example:**
```elixir
# examples/demo_app/config/config.exs
import Config

config :parapet,
  repo: DemoApp.Repo,
  providers: [Parapet.SLO.StarterPack.WebSaaS]

config :demo_app, DemoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "demo_app_dev",
  pool_size: 10
```

```elixir
# examples/demo_app/config/test.exs
import Config

config :demo_app, DemoApp.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "demo_app_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

### Pattern 2: Open Route Mount (no auth)

**What:** Mount Operator UI at `/parapet` with an explicit `# WARNING: demo only` comment, no pipeline auth.
**When to use:** Demo app only — production apps must use authenticated scope.
**Example:**
```elixir
# examples/demo_app/lib/demo_app_web/router.ex
defmodule DemoAppWeb.Router do
  use DemoAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # WARNING: demo only — do not copy to production.
  # Parapet does not provide its own auth. In production, mount the
  # Operator UI inside an authenticated scope with your app's auth plugs.
  scope "/", DemoAppWeb do
    pipe_through :browser

    live_session :parapet_operator do
      live "/parapet", DemoAppWeb.Parapet.OperatorLive, :index
      live "/parapet/:id", DemoAppWeb.Parapet.OperatorDetailLive, :show
    end
  end
end
```

### Pattern 3: Phoenix.ConnTest Smoke Test

**What:** Test GET /parapet returns 200 using Phoenix.ConnTest (no running server).
**When to use:** `mix test --only smoke` in CI demo job.
**Example:**
```elixir
# examples/demo_app/test/demo_app/operator_smoke_test.exs
defmodule DemoApp.OperatorSmokeTest do
  use DemoAppWeb.ConnCase

  @moduletag :smoke

  test "GET /parapet returns 200", %{conn: conn} do
    conn = get(conn, "/parapet")
    assert conn.status == 200
  end

  test "at least one seeded incident exists" do
    count = DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count)
    assert count > 0
  end
end
```

**ConnCase must be defined in `test/support/conn_case.ex`:**
```elixir
# examples/demo_app/test/support/conn_case.ex
defmodule DemoAppWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      @endpoint DemoAppWeb.Endpoint
      import DemoAppWeb.Router.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DemoApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
```

**Test helper must seed + sandbox:**
```elixir
# examples/demo_app/test/test_helper.exs
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(DemoApp.Repo, :manual)
```

**Important:** The smoke test needs seeds to be loaded before the test. Seeds are loaded by `mix setup` before running `mix test --only smoke` in CI. The CI job must run seeds before running tests:
```yaml
- run: cd examples/demo_app && mix run priv/repo/seeds.exs
- run: cd examples/demo_app && mix test --only smoke
```

### Pattern 4: `mix setup` alias

```elixir
# examples/demo_app/mix.exs
defp aliases do
  [
    setup: ["deps.get", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"]
  ]
end
```

### Pattern 5: Seeding with Evidence API

```elixir
# examples/demo_app/priv/repo/seeds.exs
# Configure parapet repo for seed context
Application.put_env(:parapet, :repo, DemoApp.Repo)

# Incident 1: Open with runbook + warning step
{:ok, incident_open} = Parapet.Evidence.create_incident(%{
  title: "Login service elevated error rate",
  description: "Auth endpoint returning 5xx > 2% for 10 consecutive minutes",
  state: "open",
  correlation_key: "login-error-rate-spike",
  runbook_data: %{
    "title" => "Login Failure Runbook",
    "description" => "Steps to diagnose and mitigate login service failures",
    "steps" => [
      %{
        "id" => "check_metrics",
        "label" => "Check metrics dashboard",
        "description" => "Verify DB connection pool saturation and error distribution",
        "type" => "manual",
        "kind" => "guidance",
        "warning" => "High cardinality risk — check for label explosion before querying Prometheus",
        "guidance" => nil,
        "requires_preview" => false,
        "preview_only" => false,
        "auto_execute" => false
      },
      %{
        "id" => "acknowledge",
        "label" => "Acknowledge and notify team",
        "description" => "Post update to #incidents channel",
        "type" => "manual",
        "kind" => "guidance",
        "warning" => nil,
        "guidance" => nil,
        "requires_preview" => false,
        "preview_only" => false,
        "auto_execute" => false
      }
    ]
  }
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_open.id, %{
  type: "note",
  payload: %{"text" => "Alert triggered — investigating DB connection pool saturation"}
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_open.id, %{
  type: "status_change",
  payload: %{"new_state" => "open", "actor" => "alert_system"}
})

# Incident 2: Investigating
{:ok, incident_inv} = Parapet.Evidence.create_incident(%{
  title: "Checkout webhook delivery failures",
  description: "Payment webhook callbacks timing out > 5s",
  state: "investigating"
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_inv.id, %{
  type: "note",
  payload: %{"text" => "Traced to upstream provider rate limiting — monitoring"}
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_inv.id, %{
  type: "status_change",
  payload: %{"new_state" => "investigating", "actor" => "operator_ui"}
})

# Incident 3: Resolved
{:ok, incident_resolved} = Parapet.Evidence.create_incident(%{
  title: "Signup email delivery degraded",
  description: "Transactional email provider returning 429s",
  state: "resolved"
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_resolved.id, %{
  type: "note",
  payload: %{"text" => "Provider confirmed rate limit lifted at 14:32 UTC"}
})

{:ok, _} = Parapet.Evidence.append_timeline(incident_resolved.id, %{
  type: "note",
  payload: %{"text" => "All metrics nominal — marking resolved"}
})

# Tool audit entry
{:ok, _} = Parapet.Evidence.log_tool_audit(%{
  tool_name: "parapet_doctor",
  input: %{"env" => "demo", "check" => "operator_ui_accessible"},
  output: %{"status" => "ok", "route" => "/parapet", "http_status" => 200},
  success: true,
  duration_ms: 23
})
```

### Anti-Patterns to Avoid

- **Seeding via `DemoApp.Repo.insert!(%Incident{...})`:** Bypasses the Evidence API and breaks DEMO-02's contract test purpose. Use `Parapet.Evidence.create_incident/1` exclusively.
- **Using `source` or `alert_name` as incident fields:** These fields do NOT exist in `Parapet.Spine.Incident` schema. Using them in changeset attrs will be silently ignored (Ecto's cast/3 drops unknown fields).
- **Atom keys in `runbook_data` map:** The `:map` Ecto field serializes through JSONB, converting all atom keys to strings on read-back. Always use string keys in seed data.
- **`continue-on-error: true` on the demo job:** Explicitly forbidden by D-07 and DEMO-03.
- **Auth in demo routes:** Breaks the smoke test (GET /parapet would return 302/401 instead of 200).
- **Re-running `mix parapet.gen.ui` in CI:** The demo commits generated output; CI should not regenerate it (this would require the demo app to be in a state where Igniter can run, which adds complexity).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phoenix.ConnTest setup | Custom HTTP test client | `use Phoenix.ConnTest` + `@endpoint DemoAppWeb.Endpoint` | Built into Phoenix; no server needed; exactly what DEMO-03 requires |
| Ecto sandbox for tests | Custom DB isolation | `Ecto.Adapters.SQL.Sandbox` | Standard Ecto test pattern; handles concurrency correctly |
| Incident seeding | Direct `Repo.insert!(%Incident{})` | `Parapet.Evidence.create_incident/1` | D-04: demo IS the contract test; must use Stable API |
| Router snippet | Custom LiveView mounting logic | Generated `priv/templates/parapet.gen.ui/router_snippet.ex.eex` | Commit generated output; proves generator works |
| Postgres service config | Custom CI health checks | Standard `postgres:16-alpine` with `--health-cmd pg_isready` | Idiomatic GitHub Actions pattern; already proven in V1-DEMO-APP.md |

---

## Common Pitfalls

### Pitfall 1: `source`/`alert_name` fields don't exist on Incident

**What goes wrong:** Seeds fail with Ecto changeset error OR silently discard unknown attrs, producing incidents with missing data.
**Why it happens:** CONTEXT.md mentions `source` and `alert_name` fields in D-06, but these do not exist in `Parapet.Spine.Incident` schema. The actual castable fields are: `title`, `description`, `state`, `correlation_key`, `trace_id`, `runbook_data`.
**How to avoid:** Use only the verified fields listed above. Put variant info (source system, alert name) in `title` or `description`.
**Warning signs:** `create_incident` silently succeeds but incident has unexpected nil fields, or changeset validation failure if you accidentally try to validate unknown fields.

### Pitfall 2: Atom keys in `runbook_data` vanish on reload

**What goes wrong:** Seeds insert `runbook_data` with atom keys (e.g., `%{title: "Runbook", steps: [...]}`). After a round-trip through JSONB, all keys become strings. WorkbenchContract reads `runbook_data["title"]` which works, but `runbook_data[:title]` (with atom key) returns nil. The Operator UI correctly uses `Map.get(runbook_data, "title") || Map.get(runbook_data, :title)` so this doesn't break rendering — but it's confusing during development.
**How to avoid:** Use string keys throughout the seed `runbook_data` map.
**Warning signs:** `IEx> incident.runbook_data.title` raises KeyError after reload; `incident.runbook_data["title"]` works fine.

### Pitfall 3: Smoke test DB is empty (seeds not run before test)

**What goes wrong:** `mix test --only smoke` passes GET /parapet = 200, but the "incident count > 0" assertion fails because seeds weren't loaded.
**Why it happens:** Seeds are run by `mix setup` (which aliases `run priv/repo/seeds.exs`). If the CI job only runs `mix test`, the DB is empty.
**How to avoid:** CI job must explicitly run seeds before running the smoke test:
```yaml
- run: cd examples/demo_app && mix ecto.create && mix ecto.migrate
- run: cd examples/demo_app && mix run priv/repo/seeds.exs
- run: cd examples/demo_app && mix test --only smoke
```
**Warning signs:** Test output shows `assert count > 0` failure with `count == 0`.

### Pitfall 4: LiveView routes not accessible because of missing `:browser` pipeline

**What goes wrong:** GET /parapet returns 500 or unexpected redirect because the LiveView route is outside the `:browser` pipeline (which provides session, flash, CSRF protection required by LiveView).
**How to avoid:** Ensure router scope for `/parapet` pipes through `:browser`. The `live_session` block must be inside a `scope` that has `pipe_through :browser`.
**Warning signs:** ConnTest returns 500; LiveView mount fails with session-related error.

### Pitfall 5: `release_gate` job requires at least one `runs-on` and a step

**What goes wrong:** GitHub Actions rejects a job with only `needs:` and no `runs-on:` or steps.
**How to avoid:** The `release_gate` fan-in job must have `runs-on: ubuntu-latest` and at least one trivial step:
```yaml
release_gate:
  needs: [test, demo]
  runs-on: ubuntu-latest
  steps:
    - run: echo "All required checks passed"
```
**Warning signs:** GitHub Actions syntax validation error on push.

### Pitfall 6: Demo app Endpoint not started in ConnCase setup

**What goes wrong:** `Phoenix.ConnTest` uses `@endpoint DemoAppWeb.Endpoint` but the endpoint is not started in the test environment, causing connection errors.
**How to avoid:** Add the endpoint to the demo app's `application.ex` supervisor and configure it in `config/test.exs`. The endpoint's `server: false` setting (standard for test env) means it doesn't bind a port but still processes conn-based requests via ConnTest.
```elixir
# config/test.exs
config :demo_app, DemoAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "...",
  server: false
```
**Warning signs:** `(exit) exited in: GenServer.call(DemoAppWeb.Endpoint, ...)` — endpoint not started.

---

## Files to Create for `examples/demo_app/`

Complete file manifest. All files must be created:

### Configuration files
- `examples/demo_app/mix.exs` — app metadata, deps, aliases (`setup`)
- `examples/demo_app/.formatter.exs` — `[import_deps: [:ecto, :ecto_sql, :phoenix], inputs: ["*.exs", "{lib,test}/**/*.{ex,exs}"]]`
- `examples/demo_app/config/config.exs` — repo config, parapet providers config
- `examples/demo_app/config/dev.exs` — endpoint debug config
- `examples/demo_app/config/test.exs` — test DB config, server: false
- `examples/demo_app/README.md` — quick start instructions

### Application code
- `examples/demo_app/lib/demo_app/application.ex` — starts Repo and Endpoint
- `examples/demo_app/lib/demo_app/repo.ex` — `use Ecto.Repo, otp_app: :demo_app, adapter: Ecto.Adapters.Postgres`
- `examples/demo_app/lib/demo_app/parapet_instrumenter.ex` — committed output of `mix parapet.install`
- `examples/demo_app/lib/demo_app_web/endpoint.ex` — standard Phoenix endpoint with LiveView socket, Parapet.Plug.Metrics
- `examples/demo_app/lib/demo_app_web/router.ex` — open /parapet routes with WARNING comment

### Generated LiveView files (commit generator output)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`

### Database
- `examples/demo_app/priv/repo/migrations/<timestamp>_add_parapet_spine_tables.exs` — output of `mix parapet.gen.spine`
- `examples/demo_app/priv/repo/seeds.exs` — seeding via Evidence API

### Tests
- `examples/demo_app/test/test_helper.exs` — ExUnit.start() + Sandbox.mode
- `examples/demo_app/test/support/conn_case.ex` — DemoAppWeb.ConnCase
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — @tag :smoke tests

### CI
- `.github/workflows/ci.yml` — add `demo:` job + `release_gate:` job

### Documentation
- `docs/getting-started.md` — add one bullet to "Next steps" section

---

## Exact CI Changes Needed

### Add `demo` job to `.github/workflows/ci.yml`

Insert after the `test:` job:

```yaml
demo:
  runs-on: ubuntu-latest
  needs: [test]
  env:
    MIX_ENV: test
  services:
    postgres:
      image: postgres:16-alpine
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: demo_app_test
      ports: ['5432:5432']
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  steps:
    - uses: actions/checkout@v4
    - name: Setup Elixir
      uses: erlef/setup-beam@v1
      with:
        elixir-version: '1.19.0'
        otp-version: '27.2'
    - name: Cache demo deps
      uses: actions/cache@v4
      with:
        path: examples/demo_app/deps
        key: ${{ runner.os }}-demo-mix-${{ hashFiles('examples/demo_app/mix.lock') }}
        restore-keys: ${{ runner.os }}-demo-mix-
    - name: Cache demo _build
      uses: actions/cache@v4
      with:
        path: examples/demo_app/_build
        key: ${{ runner.os }}-demo-build-${{ hashFiles('examples/demo_app/mix.lock') }}
        restore-keys: ${{ runner.os }}-demo-build-
    - name: Install demo deps
      run: cd examples/demo_app && mix deps.get
    - name: Create and migrate demo DB
      run: cd examples/demo_app && mix ecto.create && mix ecto.migrate
    - name: Seed demo DB
      run: cd examples/demo_app && mix run priv/repo/seeds.exs
    - name: Demo smoke test
      run: cd examples/demo_app && mix test --only smoke
```

### Add `release_gate` job

Insert after the `demo:` job:

```yaml
release_gate:
  needs: [test, demo]
  runs-on: ubuntu-latest
  steps:
    - run: echo "All required CI checks passed"
```

### Key CI design notes

- `demo` depends on `test` via `needs: [test]` — only runs if main test suite passes first
- `demo` uses explicit postgres service container (not relying on runner's pre-installed postgres)
- `release_gate` is a pure fan-in with `needs: [test, demo]` — its failure if either parent fails ensures neither job can be bypassed
- No `continue-on-error` anywhere
- The `release_gate` job must be configured as a required status check in GitHub branch protection settings — this is a manual step outside the workflow file (planner should include a `checkpoint:human` task for this)

---

## Exact `docs/getting-started.md` Change

Add one bullet to the "Next steps" section (currently lines 94-99). The current section ends at line 99 with the Sigra integration link. Append:

```markdown
- [Runnable Demo App](https://github.com/szTheory/parapet/tree/main/examples/demo_app) — explore a live, seeded Parapet setup end-to-end: incidents, timeline entries, runbook steps, and the Operator UI populated and ready to browse
```

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir 1.19 | mix tasks | ✓ | 1.19.0 (CI pinned) | — |
| OTP 27.2 | mix tasks | ✓ | 27.2 (CI pinned) | — |
| PostgreSQL | Demo Repo, smoke test | ✓ | 16 (ubuntu-latest pre-installed) | Service container in CI |
| mix hex.build | DEMO-04 verification | ✓ | Standard mix task | — |

**Note:** The `mix hex.build --dry-run` verification that `examples/` is excluded should be run once locally to confirm D-10 — it is a single-step verification task, not a recurring CI gate.

---

## Validation Architecture

Note: `workflow.nyquist_validation` key is absent from `.planning/config.json` — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (standard Elixir) |
| Config file | `examples/demo_app/test/test_helper.exs` — to be created |
| Quick run command | `cd examples/demo_app && mix test --only smoke` |
| Full suite command | `cd examples/demo_app && mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-01 | Operator UI accessible at /parapet | smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0 |
| DEMO-02 | At least one seeded incident exists after seeds | smoke | `cd examples/demo_app && mix test --only smoke` | ❌ Wave 0 |
| DEMO-03 | CI job `demo` returns green; wired in `release_gate` | CI/integration | GitHub Actions run | ❌ Wave 0 |
| DEMO-04 | `examples/demo_app/` absent from Hex tarball | manual | `mix hex.build --dry-run` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `examples/demo_app/test/test_helper.exs` — required before any ExUnit tests run
- [ ] `examples/demo_app/test/support/conn_case.ex` — covers DEMO-01 smoke test setup
- [ ] `examples/demo_app/test/demo_app/operator_smoke_test.exs` — covers DEMO-01, DEMO-02

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `phoenix_ecto ~> 4.4` is the correct version constraint | Standard Stack | Minor: planner would need to check hex.pm; confirmed 4.7.0 is current [ASSUMED version constraint — package confirmed real] |
| A2 | `bandit ~> 1.5` is a suitable constraint for Phoenix 1.8.7 | Standard Stack | Low: bandit 1.11.1 is current; ~> 1.5 allows up to but not including 2.0 |
| A3 | GitHub branch protection "required status checks" must be manually configured for release_gate | CI Changes | Low: this is standard GitHub behavior, not a code issue |
| A4 | The ubuntu-latest runner's pre-installed postgres uses default credentials `postgres/postgres` on localhost:5432 | CI/Environment | Low for demo job (it uses explicit service container); medium for main test job (but that already works so this is moot) |

**If this table is empty:** Not empty — four minor assumptions.

---

## Open Questions

1. **Tailwind and heroicons in the demo**
   - What we know: Generated `operator_components.ex` uses Tailwind CSS classes. Demo will render but look unstyled without Tailwind compilation.
   - What's unclear: Is a fully styled human-facing demo a requirement, or is a functionally correct but plain-looking UI acceptable for v1.0?
   - Recommendation: Include `tailwind` and `heroicons` deps for a polished demo. If build time is a concern, omit and note in demo README that styles require `mix assets.build`.

2. **Parapet instrumenter module content**
   - What we know: `mix parapet.install` generates a `ParapetInstrumenter` module into the host app.
   - What's unclear: The exact content of the generated module (we'd need to run the installer against the demo app to see its output).
   - Recommendation: Run `mix parapet.install` locally against the demo app scaffold before committing, then commit the result. Alternatively, read `lib/mix/tasks/parapet.install.ex` more deeply to reconstruct the expected output.

3. **Demo app `mix.lock` maintenance**
   - What we know: V1-DEMO-APP.md recommends Dependabot for the `examples/demo_app` directory.
   - What's unclear: Whether creating a `dependabot.yml` is in scope for this phase.
   - Recommendation: Add `dependabot.yml` with an `examples/demo_app` entry — it's a 10-line file and prevents demo rot (Section 6 of V1-DEMO-APP.md).

---

## Sources

### Primary (HIGH confidence)
- `lib/parapet/evidence.ex` — Evidence API signatures, create_incident, append_timeline, log_tool_audit [VERIFIED]
- `lib/parapet/runbook.ex` — __runbook_schema__/0 output shape [VERIFIED]
- `lib/parapet/spine/incident.ex` — Incident schema fields (confirming no source/alert_name) [VERIFIED]
- `lib/parapet/operator/workbench_contract.ex` — runbook_data consumption pattern, string key usage [VERIFIED]
- `lib/mix/tasks/parapet.gen.ui.ex` — generator assigns, output file paths [VERIFIED]
- `priv/templates/parapet.gen.ui/` — all 4 template files confirmed [VERIFIED]
- `mix.exs` files whitelist — `examples/` absence confirmed [VERIFIED]
- `mix.lock` — Phoenix 1.8.7, phoenix_live_view 1.1.30 confirmed [VERIFIED]
- `.github/workflows/ci.yml` — existing CI structure (no postgres service, no release_gate) [VERIFIED]
- `docs/getting-started.md` — "Next steps" section at lines 94-99 [VERIFIED]
- hex.pm Phoenix latest stable — 1.8.7 [VERIFIED]

### Secondary (MEDIUM confidence)
- `.planning/research/V1-DEMO-APP.md` — prior art analysis, postgres:15-alpine CI pattern, PromEx precedent [VERIFIED against codebase]
- `.planning/phases/21-runnable-demo-app/21-CONTEXT.md` — locked decisions [VERIFIED as authoritative]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Phoenix 1.8.7 + live_view 1.1.30 verified in existing lock file; all deps are official Phoenix ecosystem
- Architecture: HIGH — all patterns verified against actual generator templates and library source
- Pitfalls: HIGH — sourced from direct schema inspection (source/alert_name absence) and JSONB behavior (atom→string key conversion)
- CI structure: HIGH — ci.yml read directly; postgres:16-alpine and service block pattern from V1-DEMO-APP.md

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (30 days — Phoenix 1.8.x is stable; parapet library code is frozen for v1.0)

---

## RESEARCH COMPLETE
