# Phase 21: Runnable Demo App - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Build `examples/demo_app/` — a child Phoenix app (path dep on parapet) that starts
with `mix setup && mix phx.server` and serves a populated Operator UI at `/parapet`.
Wire a required `demo` CI gate (smoke test only — no security or performance audit).
Exclude the demo from the published Hex package. Link it from the getting-started guide.

Scope is **building and wiring** the demo app and CI gate — NOT adding new parapet
runtime features, new integrations, or production auth scaffolding.

Covers requirements: DEMO-01, DEMO-02, DEMO-03, DEMO-04.
</domain>

<decisions>
## Implementation Decisions

### Demo App Structure (DEMO-01)
- **D-01:** The demo is a **standalone committed Phoenix app** at `examples/demo_app/`
  — not an umbrella child, not a generated scaffold via `mix phx.new`. It must be a
  real, named Phoenix app so that `mix parapet.gen.ui` can introspect its `web_module`
  and `repo_module` — the demo proves actual generated LiveView output, not a mock.
- **D-02:** `mix setup` runs the standard Phoenix alias sequence:
  `deps.get → ecto.create → ecto.migrate → run priv/repo/seeds.exs`.
  The demo app supplies its own `Repo` module (e.g. `DemoApp.Repo`) and configures
  it as `:parapet` repo via `Application.put_env(:parapet, :repo, DemoApp.Repo)`.
- **D-03:** Phoenix version constraint: `~> 1.7` (minimum required for
  `use MyAppWeb, :live_view` with verified routes and the LiveView component
  system used in `mix parapet.gen.ui` generated templates). Research during planning
  to confirm exact latest stable version.

### Seeding Strategy (DEMO-02)
- **D-04:** Seeds call the **Stable** `Parapet.Evidence.*` API exclusively:
  `Parapet.Evidence.create_incident/1`, `Parapet.Evidence.append_timeline/2`,
  `Parapet.Evidence.log_tool_audit/1`. Direct `Repo.insert(%Incident{})` calls to
  Experimental/internal Spine schemas are **not used** — the demo is a CI contract
  test of the frozen stable surface.
- **D-05:** The `warning:` runbook step required by DEMO-02 is seeded as a **static
  JSON map** written to `Incident.runbook_data` — matching the shape produced by
  `Parapet.Runbook.__runbook_schema__/0`. Seed code writes something like:
  ```elixir
  runbook_data: %{
    "name" => "DemoRunbook",
    "steps" => [
      %{"name" => "Check metrics", "warning" => "High cardinality risk", "mitigation" => nil},
      %{"name" => "Acknowledge", "warning" => nil, "mitigation" => nil}
    ]
  }
  ```
  This matches how the Operator UI LiveView consumes `incident.runbook_data`.
- **D-06:** Seed coverage — incidents in all three states (open, investigating, resolved)
  with varied `title`, `source`, and `alert_name` fields; at least 2 timeline entries per
  incident (alert trigger + operator note); at least 1 tool audit entry; 1 incident with
  `runbook_data` containing a `warning:` step; WebSaaS SLO state registered via
  `Application.put_env` or config (no Prometheus dependency needed — SLO state is
  in-memory for demo purposes).

### CI Gate Design (DEMO-03)
- **D-07:** The `demo` CI job lives inside the **existing `.github/workflows/ci.yml`**
  as a new job alongside `test`. A new `release_gate` job is added with
  `needs: [test, demo]`. `continue-on-error` is **never set** on the `demo` job.
- **D-08:** Smoke test mechanism: **`Phoenix.ConnTest`** (no running server).
  The demo app has its own ExUnit test suite with a smoke test module tagged
  `@tag :smoke`. The `demo` CI job runs: `cd examples/demo_app && mix test --only smoke`.
  The smoke test asserts:
  1. `GET /parapet` returns 200 (using `Phoenix.ConnTest`)
  2. At least one `Incident` record exists in the seeded DB (direct Repo query is
     acceptable here since this is a test, not production code)
- **D-09:** The `demo` CI job uses the same Elixir/OTP versions as the `test` job
  (1.19.0 / OTP 27.2) and needs a PostgreSQL service. Use the `services:` block
  pattern if PostgreSQL is needed for smoke tests, matching the test job's approach.

### Hex Exclusion & Docs Link (DEMO-04)
- **D-10:** `examples/demo_app/` is **already excluded** from the Hex package — no
  change to `mix.exs` `files:` whitelist is needed. The whitelist is an allowlist;
  `examples/` is absent. Verify via `mix hex.build --dry-run` during planning/execution.
- **D-11:** A "Next steps" bullet linking the demo app is added to the existing
  "Next steps" section at the end of `docs/getting-started.md`. Text approximately:
  `- [Runnable Demo App](https://github.com/szTheory/parapet/tree/main/examples/demo_app) — explore a live, seeded Parapet setup end-to-end`

### Demo App Auth (Operator UI Security)
- **D-12:** Demo routes are mounted **open (no authentication)** with an explicit
  `# WARNING: demo only — do not copy to production` comment in the router.
  Parapet does not provide its own auth; adding auth scaffolding is outside phase scope
  and would break the DEMO-03 smoke test (`GET /parapet` must return 200, not 302/401).

### Claude's Discretion
- Exact Phoenix version (within `~> 1.7`) to use — confirm latest stable during research.
- Demo app module naming convention (e.g. `DemoApp` vs `ParapetDemo`).
- Exact set of seed incidents beyond the minimum (open/investigating/resolved with
  timeline + tool audit + runbook-with-warning).
- Whether the demo app uses `sqlite3_ecto` (lighter, no PG in CI) or PostgreSQL (more
  realistic) — default to PostgreSQL for realism; research if SQLite is better for CI.
- Exact `release_gate` job structure (whether it's a real job with steps or just a
  fan-in gate with `if: always()` pattern).

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — DEMO-01, DEMO-02, DEMO-03, DEMO-04 with exact acceptance criteria
- `.planning/ROADMAP.md` Phase 21 success criteria — the four binding conditions this phase must satisfy
- `lib/parapet/evidence.ex` — Stable API for creating incidents, timeline entries, and tool audits (seed source of truth)
- `lib/parapet/runbook.ex` — `Parapet.Runbook` DSL; `__runbook_schema__/0` output shape used for `runbook_data` seeding
- `lib/parapet/spine/incident.ex` — `Incident` schema fields (esp. `runbook_data: :map`, `state`, `source`, `alert_name`)
- `lib/parapet/slo/starter_pack/web_saas.ex` — WebSaaS SLO registration pattern
- `lib/mix/tasks/parapet.gen.ui.ex` — generator that creates the LiveView files + router snippet for the demo app
- `priv/templates/parapet.gen.ui/` — LiveView templates actually generated into the demo app
- `.github/workflows/ci.yml` — existing CI structure; `demo` job and `release_gate` job must be added here
- `docs/getting-started.md` — "Next steps" section at end (lines ~94-99) — DEMO-04 link target

No external specs — requirements fully captured in decisions above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Evidence` (Stable) — `create_incident/1`, `append_timeline/2`, `log_tool_audit/1` are the seeding API. No need for direct schema manipulation.
- `Parapet.Runbook.__runbook_schema__/0` — produces the exact map shape that seeds must write into `incident.runbook_data` for the Operator UI to render correctly.
- `lib/mix/tasks/parapet.gen.ui.ex` — generates `operator_live.ex` and `operator_detail_live.ex` into `lib/<app>_web/live/parapet/`; the demo runs this generator to produce its LiveView files.
- `priv/templates/parapet.gen.ui/router_snippet.ex.eex` — provides the exact router snippet to wire into the demo's `router.ex`.
- `test/parapet/telemetry/async_delivery_test.exs` — `ExUnit.Case` pattern to follow for the smoke test module.
- `mix.exs:42` — files whitelist (allowlist); `examples/` absent → Hex exclusion is automatic.

### Established Patterns
- `Application.get_env(:parapet, :repo)` — all Evidence/Operator queries go through this dynamic repo lookup; demo configures it in `config/config.exs` or `config/dev.exs`.
- "No auth provided by Parapet" — `mix parapet.gen.ui` generates commented-out auth guidance; demo skips auth, documents the `# WARNING: demo only` caveat.
- Code surfaces before docs: demo app ships before the getting-started link is added (enforce task ordering in plan).
- `files:` allowlist (not denylist) — adding `examples/` to the repo never pollutes the Hex package.
- `Phoenix.ConnTest` for smoke tests — no running server needed; matches existing test infra philosophy.

### Integration Points
- **`examples/demo_app/mix.exs`** — needs `{:parapet, path: "../.."}` path dep + `{:phoenix, "~> 1.7"}` + `{:phoenix_live_view, ...}` + `{:postgrex, ...}`.
- **`.github/workflows/ci.yml`** — two additions: `demo:` job (runs `cd examples/demo_app && mix test --only smoke`) and `release_gate:` job (`needs: [test, demo]`).
- **`docs/getting-started.md`** — one bullet added to "Next steps" section.
- **`mix parapet.gen.ui`** — run inside `examples/demo_app/` during setup to generate the LiveView files (or commit generated files directly to avoid generator runtime dep).
</code_context>

<specifics>
## Specific Ideas

- **`runbook_data` shape** — seed must match `Parapet.Runbook.__runbook_schema__/0` output exactly. The Operator UI LiveView reads this map to render steps with `warning:` callouts. The warning key must be non-nil on at least one step.
- **No auth on demo routes** — the DEMO-03 smoke test (`GET /parapet` → 200) is the hard dependency. Any auth layer breaks this unless the test handles credentials. Keep it open with a prominent warning.
- **`release_gate` as a required check** — must be configured in GitHub branch protection settings (not just added to the workflow) to actually gate merges. Note this as a planning task.
- **Database for smoke tests** — if using PostgreSQL, the `demo` CI job needs a `services: postgres:` block. If the CI complexity is unacceptable, SQLite via `ecto_sqlite3` is an alternative that eliminates the PG service dep (and is legitimate for a demo/example app). This is left to Claude's discretion unless the user has a preference.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>

---

*Phase: 21-runnable-demo-app*
*Context gathered: 2026-05-25*
