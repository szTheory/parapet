# Phase 48 — Deferred Items

Out-of-scope discoveries logged during execution (NOT fixed; tracked for a future pass).

## Pre-existing demo-app compile warnings (`<%#` deprecation)

- **Found during:** 48-02 Task 1 (`mix compile --warnings-as-errors` in `examples/demo_app`)
- **Files:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex:1384, :1398`
- **Issue:** Two `<%# ... %>` EEx comments (Phase-47 risk-chip / audit-outcome annotations)
  trip Elixir 1.19's `<%# is deprecated, use <%!-- or add a space` warning. Under
  `mix compile --warnings-as-errors` the demo app fails to compile.
- **Why deferred:** Pre-existing (present in HEAD, 2 occurrences; none introduced by 48-02).
  Lives in a Phase-47 comment region outside this plan's named edit sites. The demo app
  compiles cleanly in normal mode (`mix compile` → exit 0, `Generated demo_app app`). The
  48-02 `<verify>` gate (`mix compile --warnings-as-errors` in the lib root + lib
  integration test) is unaffected.
- **Scope rule:** SCOPE BOUNDARY (do not auto-fix pre-existing warnings unrelated to the
  current task). The fix is a 2-line `<%#` → `<%!--` swap in both the `.eex` template and
  its demo mirror; appropriate for a dedicated lint-hygiene pass or folded into 48-03 when
  that wave already edits these files.

## Pre-existing full-suite failures unrelated to 48-02

- **Found during:** 48-02 Task 2 (full `mix test` run, 570 tests / 7 failures)
- **Tests:** `Parapet.DocsPhase33Test` ("demo app docs describe the reproducible Compose
  smoke path...") and `Parapet.Automation.ExecutorClusterSmokeTest` ("shared claim
  semantics survive one local-plus-peer race canary").
- **Issue:** Both fail on clean HEAD with 48-02 work stashed; neither references
  `operator_components` / `incident_not_found` / `list_skeleton` or any file 48-02 edits.
  The cluster smoke test is a known local-plus-peer race canary (timing-sensitive); the
  docs test is a Phase-33 Compose-doc assertion.
- **Why deferred:** Pre-existing and out of this plan's scope (SCOPE BOUNDARY — only
  auto-fix issues directly caused by the current task's changes). The other 5 full-suite
  failures are the intended 48-01 RED gates that 48-03 flips green.
