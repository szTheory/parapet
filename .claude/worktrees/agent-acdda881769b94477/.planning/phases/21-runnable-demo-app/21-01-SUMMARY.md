---
phase: 21-runnable-demo-app
plan: 01
subsystem: demo
tags: [phoenix, ecto, postgres, elixir, demo-app, parapet]

# Dependency graph
requires: []
provides:
  - "examples/demo_app/ Phoenix 1.8 skeleton app with path dep on parapet"
  - "DemoApp.Repo registered as :parapet repo via config :parapet, repo: DemoApp.Repo"
  - "WebSaaS SLO provider registered via config :parapet, providers: [Parapet.SLO.StarterPack.WebSaaS]"
  - "Supervision tree: DemoApp.Repo + DemoAppWeb.Telemetry + Phoenix.PubSub + DemoAppWeb.Endpoint"
  - "DemoApp.ParapetInstrumenter matching minimal mix parapet.install output"
  - "Single spine migration with all five tables + runbook_data + trace_id on parapet_incidents"
  - "DemoAppWeb.Endpoint with Parapet.Plug.Metrics before router"
affects:
  - "21-02 (router, LiveView, assets)"
  - "21-03 (seeds use DemoApp.Repo registered here)"
  - "21-04 (smoke test + CI gate build on this skeleton)"

# Tech tracking
tech-stack:
  added:
    - "phoenix ~> 1.8 (demo app dep)"
    - "phoenix_live_view ~> 1.1 (demo app dep)"
    - "phoenix_ecto ~> 4.4 (demo app dep)"
    - "ecto_sql ~> 3.10 (demo app dep)"
    - "postgrex ~> 0.20 (demo app dep)"
    - "bandit ~> 1.5 (demo app dep, Bandit.PhoenixAdapter)"
    - "phoenix_html ~> 4.1 (demo app dep)"
    - "jason ~> 1.2 (demo app dep)"
  patterns:
    - "Path dep: {:parapet, path: \"../..\"} connects demo app to HEAD of library"
    - "Config-time repo registration: config :parapet, repo: DemoApp.Repo"
    - "Minimal Supervisor child pattern for Telemetry (no telemetry_metrics dep)"
    - "Inline DemoAppWeb.Layouts + CoreComponents + ErrorHTML in demo_app_web.ex for standalone compile"

key-files:
  created:
    - "examples/demo_app/mix.exs"
    - "examples/demo_app/.formatter.exs"
    - "examples/demo_app/.gitignore"
    - "examples/demo_app/config/config.exs"
    - "examples/demo_app/config/dev.exs"
    - "examples/demo_app/config/test.exs"
    - "examples/demo_app/lib/demo_app/application.ex"
    - "examples/demo_app/lib/demo_app/repo.ex"
    - "examples/demo_app/lib/demo_app/parapet_instrumenter.ex"
    - "examples/demo_app/lib/demo_app_web.ex"
    - "examples/demo_app/lib/demo_app_web/endpoint.ex"
    - "examples/demo_app/lib/demo_app_web/telemetry.ex"
    - "examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs"
  modified: []

key-decisions:
  - "Inline DemoAppWeb.Layouts, CoreComponents, ErrorHTML in demo_app_web.ex for Plan 01 standalone compile — Plan 02 may refine layouts for Tailwind"
  - "Force-added config/test.exs: root .gitignore blocks bare 'test.exs' pattern; demo app's test config is intentionally committed"
  - "Single migration combining parapet.gen.spine output + runbook_data + trace_id columns — avoids three separate migration files and ensures Plan 03 seeds succeed"
  - "Simpler deps list (no heroicons/tailwind) — smoke test does not require styled output; Plan 02 owns asset tooling decision"
  - "Minimal DemoAppWeb.Telemetry supervisor with empty children — avoids telemetry_metrics dep requirement for Plan 01"

patterns-established:
  - "Demo app supervision: Repo -> Telemetry -> PubSub -> Endpoint (standard Phoenix order)"
  - "Parapet.Plug.Metrics placed before DemoAppWeb.Router in endpoint pipeline"
  - "ParapetInstrumenter: Parapet.Metrics.Probe.setup() + :ok (exact mix parapet.install minimal output)"

requirements-completed: [DEMO-01]

# Metrics
duration: 25min
completed: 2026-05-25
---

# Phase 21 Plan 01: Demo App Skeleton Summary

**Phoenix 1.8 demo app skeleton at examples/demo_app/ with path dep on parapet, DemoApp.Repo as :parapet repo, five-table spine migration with runbook_data + trace_id columns, and Parapet.Plug.Metrics in endpoint pipeline**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-25T00:00:00Z
- **Completed:** 2026-05-25T00:25:00Z
- **Tasks:** 3
- **Files modified:** 13 created

## Accomplishments

- Created complete Phoenix 1.8 app skeleton at `examples/demo_app/` as a standalone committed app (not umbrella child)
- Registered `DemoApp.Repo` as the `:parapet` repo and `Parapet.SLO.StarterPack.WebSaaS` as SLO provider via config
- Created single spine migration combining all five tables + `runbook_data` + `trace_id` columns on parapet_incidents — critical for Plan 03 seeds

## Task Commits

Each task was committed atomically:

1. **Task 1: Create mix.exs, formatter, gitignore, and config files** - `c7b4df9` (feat)
2. **Task 1b: Add config/test.exs (force-add past root gitignore)** - `db3299e` (feat)
3. **Task 2: Create application, repo, web entry, endpoint, telemetry, instrumenter** - `f575117` (feat)
4. **Task 3: Create spine migration with runbook_data and trace_id columns** - `5e92fc6` (feat)

## Files Created/Modified

- `examples/demo_app/mix.exs` - DemoApp.MixProject with path dep {:parapet, path: "../.."} and setup alias
- `examples/demo_app/.formatter.exs` - Formatter with import_deps: [:ecto, :ecto_sql, :phoenix]
- `examples/demo_app/.gitignore` - Phoenix app gitignore
- `examples/demo_app/config/config.exs` - Parapet repo + WebSaaS provider + Bandit endpoint config
- `examples/demo_app/config/dev.exs` - Dev server on port 4000 with code reloading
- `examples/demo_app/config/test.exs` - Test config with Ecto.Adapters.SQL.Sandbox + server: false
- `examples/demo_app/lib/demo_app/application.ex` - Supervision tree starting Repo/Telemetry/PubSub/Endpoint
- `examples/demo_app/lib/demo_app/repo.ex` - DemoApp.Repo using Ecto.Adapters.Postgres
- `examples/demo_app/lib/demo_app/parapet_instrumenter.ex` - Minimal instrumenter with Probe.setup/0
- `examples/demo_app/lib/demo_app_web.ex` - DemoAppWeb entry + inline Layouts/CoreComponents/ErrorHTML
- `examples/demo_app/lib/demo_app_web/endpoint.ex` - Phoenix endpoint with /live socket + Parapet.Plug.Metrics
- `examples/demo_app/lib/demo_app_web/telemetry.ex` - Minimal Supervisor child (empty children)
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` - All five spine tables + runbook_data + trace_id

## Decisions Made

- **Inline modules in demo_app_web.ex:** DemoAppWeb.Layouts, CoreComponents, and ErrorHTML placed inline to enable standalone Plan 01 compile without requiring Plan 02's router/layout files. Plan 02 may refine layouts.
- **Force-added config/test.exs:** The root `.gitignore` contains a bare `test.exs` pattern (line 30) that blocks the demo app's config file. Used `git add -f` to force-track this intentional demo file.
- **Single combined migration:** Rather than three separate files (gen.spine + add_runbook_data + add_trace_id), created one migration containing all columns. Functionally equivalent for a fresh DB and avoids migration ordering issues.
- **Simpler deps (no heroicons/tailwind):** Asset tooling deferred to Plan 02 per the plan's instruction. Smoke test correctness does not depend on styled output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Root .gitignore blocks config/test.exs**
- **Found during:** Task 1 (config files commit)
- **Issue:** Root `.gitignore` contains bare `test.exs` pattern (line 30) — git refused to track `examples/demo_app/config/test.exs`
- **Fix:** Force-added using `git add -f examples/demo_app/config/test.exs` in a separate commit
- **Files modified:** `examples/demo_app/config/test.exs`
- **Verification:** File now tracked in git; test.exs appears in commit db3299e
- **Committed in:** `db3299e` (separate force-add commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Force-add necessary for correctness — test.exs is a required demo app config file. No scope creep.

## Issues Encountered

- Root `.gitignore` bare `test.exs` pattern blocked demo's `config/test.exs`. Resolved via `git add -f`.

## User Setup Required

None - no external service configuration required. Demo app requires a local Postgres instance when running `mix ecto.create && mix ecto.migrate` (which Plan 02 verifies end-to-end).

## Next Phase Readiness

- Plan 02 builds on this skeleton: router, generated LiveView UI files, asset tooling, and end-to-end `mix compile` + `mix ecto.migrate` verification
- Plan 03 uses the registered DemoApp.Repo and Evidence API to seed incidents
- Plan 04 adds smoke test and CI gate

---
*Phase: 21-runnable-demo-app*
*Completed: 2026-05-25*
