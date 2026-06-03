---
phase: 21-runnable-demo-app
plan: "03"
subsystem: demo-app-seeds-smoke
tags: [seeds, evidence-api, smoke-test, phoenix-conn-test, ecto-sandbox]
dependency_graph:
  requires: ["21-02"]
  provides: ["21-04"]
  affects: ["examples/demo_app/priv/repo/seeds.exs", "examples/demo_app/test/"]
tech_stack:
  added: []
  patterns:
    - "Evidence Stable API as the exclusive incident creation surface in seeds"
    - "Self-contained Ecto sandbox inserts in smoke test (no cross-connection seed dependency)"
    - "Phoenix.ConnTest without running server (@endpoint DemoAppWeb.Endpoint)"
key_files:
  created:
    - examples/demo_app/priv/repo/seeds.exs
    - examples/demo_app/test/test_helper.exs
    - examples/demo_app/test/support/conn_case.ex
    - examples/demo_app/test/demo_app/operator_smoke_test.exs
    - examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs
  modified: []
decisions:
  - "Smoke test creates its own incident inside the sandbox transaction (not dependent on seeds)"
  - "Migration 20260525000001 added to fix missing kind + incident_id on parapet_action_items"
metrics:
  duration_minutes: 4
  completed: "2026-05-25T16:10:16Z"
  tasks_completed: 2
  files_created: 5
---

# Phase 21 Plan 03: Seeds + Smoke Test Summary

**One-liner:** Evidence-API-only seeds with open/investigating/resolved incidents + runbook warning step, backed by a self-contained Phoenix.ConnTest smoke test verifying 200 and count > 0.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | seeds.exs via Evidence Stable API | 3a85f20 | examples/demo_app/priv/repo/seeds.exs |
| 2 | test_helper + conn_case + smoke test | 2344da8 | test/test_helper.exs, test/support/conn_case.ex, test/demo_app/operator_smoke_test.exs, migrations/20260525000001 |

## Verification Results

- `MIX_ENV=dev mix run priv/repo/seeds.exs` exits 0: inserts 3 incidents (open/investigating/resolved), 6 timeline entries, 1 tool audit via Evidence API
- `mix test --only smoke` reports `2 tests, 0 failures`
- GET /parapet returns 200 (OperatorLive mounts cleanly)
- Incident count > 0 assertion holds (self-contained sandbox insert)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing `kind` and `incident_id` columns on `parapet_action_items` table**
- **Found during:** Task 2 - first smoke test run
- **Issue:** Migration from Plan 01 (`20260525000000`) created `parapet_action_items` without the `kind` column (default: `"exact_follow_up"`) and `incident_id` FK reference. `Parapet.Operator.action_items_query()` in `OperatorLive.mount/3` selected these columns, producing `ERROR 42703 (undefined_column) column p0.kind does not exist` on every GET /parapet request.
- **Fix:** Added migration `20260525000001_add_action_item_kind_and_incident_id.exs` to `alter table(:parapet_action_items)` and add both columns + index.
- **Files modified:** `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` (new)
- **Commit:** 2344da8

**2. [Rule 1 - Bug] Phoenix.ConnTest deprecation in conn_case.ex**
- **Found during:** Task 2 - smoke test run
- **Issue:** `use Phoenix.ConnTest` is deprecated in Phoenix 1.8; warning advised using `import Plug.Conn; import Phoenix.ConnTest` instead.
- **Fix:** Changed `use Phoenix.ConnTest` to the two-import form in `DemoAppWeb.ConnCase`.
- **Files modified:** `examples/demo_app/test/support/conn_case.ex`
- **Commit:** 2344da8

## Known Stubs

None. Seeds produce real data; smoke test uses a self-contained insert.

## Threat Surface Scan

No new network endpoints, auth paths, or trust boundaries introduced. Seeds are static demo data through the changeset-validated Evidence API (T-21-07 mitigated). Smoke test runs in the Ecto sandbox with no external calls (T-21-09 accepted).

## Self-Check: PASSED

- [x] `examples/demo_app/priv/repo/seeds.exs` exists
- [x] `examples/demo_app/test/test_helper.exs` exists
- [x] `examples/demo_app/test/support/conn_case.ex` exists
- [x] `examples/demo_app/test/demo_app/operator_smoke_test.exs` exists
- [x] `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` exists
- [x] Task 1 commit 3a85f20 exists in git log
- [x] Task 2 commit 2344da8 exists in git log
- [x] `mix test --only smoke` reports 0 failures
