---
phase: 21-runnable-demo-app
plan: 02
subsystem: demo
tags: [phoenix, liveview, tailwind, elixir, demo-app, parapet, operator-ui]

# Dependency graph
requires:
  - "21-01 (Phoenix skeleton, DemoApp.Repo, spine migration)"
provides:
  - "DemoAppWeb.Parapet.OperatorLive — open /parapet queue + detail split view"
  - "DemoAppWeb.Parapet.OperatorDetailLive — mobile detail view"
  - "DemoAppWeb.Parapet.OperatorComponents — full Tailwind component library"
  - "DemoAppWeb.Router with open /parapet routes and verbatim demo-only WARNING comment"
  - "DemoAppWeb.Layouts in lib/demo_app_web/components/layouts.ex with Tailwind CSS link"
  - "DemoAppWeb.ErrorHTML in lib/demo_app_web/controllers/error_html.ex"
  - "Tailwind 3.4.3 configured with content globs covering live/parapet and template sources"
  - "examples/demo_app/README.md with mix setup CTA and demo-only warning"
  - "mix compile exits 0 for whole demo app"
  - "MIX_ENV=test mix ecto.migrate exits 0"
affects:
  - "21-03 (seeds use DemoApp.Repo and live view modules confirmed compilable)"
  - "21-04 (smoke test exercises GET /parapet which now routes to OperatorLive)"

# Tech tracking
tech-stack:
  added:
    - "tailwind ~> 0.2 (Hex package, runtime: Mix.env() == :dev)"
    - "heroicons v2.1.1 (GitHub tag-pinned, compile:false, app:false)"
  patterns:
    - "scope '/' (no alias) for fully qualified module names in live routes (avoids double-namespace)"
    - "EEx template hand-resolution: <%%= %> → <%= %> (HEEx output), <%= %> → resolved value"
    - "Tailwind content glob includes priv/templates for purge-safety"

key-files:
  created:
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex"
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex"
    - "examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex"
    - "examples/demo_app/lib/demo_app_web/components/layouts.ex"
    - "examples/demo_app/lib/demo_app_web/controllers/error_html.ex"
    - "examples/demo_app/lib/demo_app_web/router.ex"
    - "examples/demo_app/assets/css/app.css"
    - "examples/demo_app/assets/tailwind.config.js"
    - "examples/demo_app/README.md"
  modified:
    - "examples/demo_app/mix.exs (added tailwind + heroicons deps + assets.build/deploy aliases)"
    - "examples/demo_app/config/config.exs (added config :tailwind block)"
    - "examples/demo_app/lib/demo_app_web.ex (fixed use Phoenix.HTML → import; moved inline modules out)"
    - "examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs (fixed duplicate index names)"

key-decisions:
  - "scope '/' without alias: using fully qualified DemoAppWeb.Parapet.OperatorLive in scope with DemoAppWeb alias caused double-namespace (DemoAppWeb.DemoAppWeb.*). Removed scope alias; fully qualified names resolve correctly."
  - "Hand-resolved EEx templates: mix parapet.gen.ui could not run during plan execution due to the blocking phoenix_html compile error; resolved templates manually with web_module=DemoAppWeb, repo_module=DemoApp.Repo"
  - "Migration index names: gave distinct names (queue_cursor_index / history_cursor_index) to the two partial indexes on [:updated_at, :id]"

patterns-established:
  - "Router uses scope '/' (no alias) + fully qualified module names for Parapet LiveView routes"
  - "DemoAppWeb.Layouts moved to dedicated file with live_title + Tailwind CSS link"
  - "DemoAppWeb.ErrorHTML in controllers/ as standalone module"

requirements-completed: [DEMO-01]

# Metrics
duration: 35min
completed: 2026-05-25
---

# Phase 21 Plan 02: Operator UI Wire-up Summary

**Generated (hand-resolved) Parapet Operator LiveView files committed into the demo app with open /parapet routes, Tailwind configured, and full mix compile + ecto.migrate verified**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-05-25T18:00:00Z
- **Completed:** 2026-05-25T18:35:00Z
- **Tasks:** 2
- **Files modified:** 9 created, 4 modified

## Accomplishments

- Created three Parapet Operator LiveView modules with all EEx assigns resolved (DemoAppWeb, DemoApp.Repo): `OperatorLive`, `OperatorDetailLive`, `OperatorComponents`
- Created `DemoAppWeb.Layouts` (standalone file with `<.live_title>` and Tailwind CSS link) and `DemoAppWeb.ErrorHTML`
- Created `DemoAppWeb.Router` with open `/parapet` routes, verbatim `# WARNING: demo only — do not copy to production.` comment, and `:browser` pipeline with CSRF + secure headers
- Added `tailwind ~> 0.2` and `heroicons v2.1.1` (tag-pinned GitHub dep) to `mix.exs` with `assets.build` and `assets.deploy` aliases
- Configured Tailwind 3.4.3 with content globs covering `live/parapet/**/*.ex` and `priv/templates/parapet.gen.ui/*.eex`
- Created `README.md` with `mix setup` CTA, localhost:5432 seed-failure guidance, and demo-only warning
- `mix compile` exits 0 (full app including generated LiveViews)
- `MIX_ENV=test mix ecto.create && mix ecto.migrate` exits 0

## Task Commits

1. **Task 1: Generate and commit Operator LiveView files; add layouts and error view** - `9b83e4d` (feat)
2. **Task 2: Add open /parapet router, Tailwind assets, README; verify compile + migrate** - `7636c0e` (feat)

## Files Created/Modified

**Created:**
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` — `DemoAppWeb.Parapet.OperatorLive` with queue, pagination, detail split view
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — `DemoAppWeb.Parapet.OperatorDetailLive` for mobile
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — `DemoAppWeb.Parapet.OperatorComponents` full Tailwind library
- `examples/demo_app/lib/demo_app_web/components/layouts.ex` — `DemoAppWeb.Layouts` with root/app defs
- `examples/demo_app/lib/demo_app_web/controllers/error_html.ex` — `DemoAppWeb.ErrorHTML`
- `examples/demo_app/lib/demo_app_web/router.ex` — Router with open /parapet scope
- `examples/demo_app/assets/css/app.css` — Tailwind @import layers
- `examples/demo_app/assets/tailwind.config.js` — Content globs covering generated + template files
- `examples/demo_app/README.md` — Quick start guide with required warning strings

**Modified:**
- `examples/demo_app/mix.exs` — Added tailwind + heroicons deps; assets.build/deploy aliases
- `examples/demo_app/config/config.exs` — Added config :tailwind block
- `examples/demo_app/lib/demo_app_web.ex` — Fixed `use Phoenix.HTML` → `import Phoenix.HTML`; moved inline Layouts/ErrorHTML modules out
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` — Renamed duplicate index names

## Decisions Made

- **scope '/' without alias:** Using `scope "/", DemoAppWeb do` with fully qualified `DemoAppWeb.Parapet.OperatorLive` caused Phoenix Router to concatenate the scope alias, producing `DemoAppWeb.DemoAppWeb.Parapet.OperatorLive`. Switched to `scope "/"` (no alias) so fully qualified names resolve directly.
- **Hand-resolved EEx templates:** The generator could not run due to `use Phoenix.HTML` compile error in demo_app_web.ex. Resolved all three templates manually with correct substitutions (no unresolved `<%= @web_module %>` etc. in generated files).
- **Migration index names:** Original migration had two identical auto-named indexes `parapet_incidents_updated_at_id_index`. Added explicit names `parapet_incidents_queue_cursor_index` and `parapet_incidents_history_cursor_index`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `use Phoenix.HTML` incompatible with phoenix_html 4.x**
- **Found during:** Task 1 (mix parapet.gen.ui attempt; also blocks mix compile)
- **Issue:** `demo_app_web.ex` used `use Phoenix.HTML` in `html_helpers/0` which is removed in phoenix_html 4.0
- **Fix:** Changed `use Phoenix.HTML` to `import Phoenix.HTML` in the html_helpers quote block
- **Files modified:** `examples/demo_app/lib/demo_app_web.ex`
- **Commit:** `9b83e4d`

**2. [Rule 3 - Blocking] Generator could not run; hand-resolved templates**
- **Found during:** Task 1 (`mix parapet.gen.ui --yes`)
- **Issue:** Generator failed due to the phoenix_html 4.x compile error above
- **Fix:** Resolved the three EEx templates manually with correct assigns (DemoAppWeb, DemoApp.Repo, :demo_app). No unresolved template variables in output.
- **Files modified:** Three operator LiveView files
- **Commit:** `9b83e4d`

**3. [Rule 1 - Bug] Double scope alias caused DemoAppWeb.DemoAppWeb.Parapet module namespace**
- **Found during:** Task 2 (mix compile warnings `DemoAppWeb.DemoAppWeb.Parapet.OperatorLive undefined`)
- **Issue:** Phoenix Router `scope "/", DemoAppWeb do` concatenates the alias with module names passed to `live/3`, so `DemoAppWeb.Parapet.OperatorLive` became `DemoAppWeb.DemoAppWeb.Parapet.OperatorLive`
- **Fix:** Changed `scope "/", DemoAppWeb do` to `scope "/" do` and kept fully qualified module names
- **Files modified:** `examples/demo_app/lib/demo_app_web/router.ex`
- **Commit:** `7636c0e`

**4. [Rule 1 - Bug] Duplicate index name in spine migration**
- **Found during:** Task 2 (`MIX_ENV=test mix ecto.migrate`)
- **Issue:** Migration created `parapet_incidents_updated_at_id_index` twice — two partial indexes on `[:updated_at, :id]` with different `where:` conditions but same auto-generated name
- **Fix:** Added `name:` options to disambiguate: `parapet_incidents_queue_cursor_index` and `parapet_incidents_history_cursor_index`
- **Files modified:** `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs`
- **Commit:** `7636c0e`

---

**Total deviations:** 4 auto-fixed (2 blocking, 2 bugs)
**Impact on plan:** All deviations resolved inline. Plan goals achieved: compile passes, migrate passes, /parapet route resolves to generated OperatorLive, Tailwind configured.

## Known Stubs

None — all modules have correct implementations. The Operator UI displays real data from `DemoApp.Repo` / `Parapet.Operator.*` APIs.

## Threat Surface Scan

Verified against threat model:
- T-21-04: Open `/parapet` route — intentional per D-12, mitigated by verbatim router warning comment + README warning. Present as required.
- T-21-05: CSRF + secure headers in `:browser` pipeline — `plug :protect_from_forgery` and `plug :put_secure_browser_headers` confirmed present in router.
- T-21-06: heroicons pinned to `tag: "v2.1.1"` from `tailwindlabs/heroicons` (official repo), `compile: false, app: false`.

No new threat surface beyond what was planned.

## Self-Check

Files confirmed:
- examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex: FOUND
- examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex: FOUND
- examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex: FOUND
- examples/demo_app/lib/demo_app_web/components/layouts.ex: FOUND
- examples/demo_app/lib/demo_app_web/controllers/error_html.ex: FOUND
- examples/demo_app/lib/demo_app_web/router.ex: FOUND
- examples/demo_app/assets/tailwind.config.js: FOUND
- examples/demo_app/README.md: FOUND

Commits confirmed:
- 9b83e4d: FOUND (Task 1)
- 7636c0e: FOUND (Task 2)

## Self-Check: PASSED
