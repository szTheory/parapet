---
phase: 38-scoped-ui-routes
plan: 02
subsystem: ui
tags: [phoenix-liveview, demo-app, route-scoping, operator-ui]

requires:
  - phase: 38-scoped-ui-routes
    provides: Generated scoped Operator UI helper shape from Plan 01
provides:
  - Checked-in demo Operator UI copies synchronized with generated scoped route helpers
  - Demo host-owned `/ops/parapet` route map alongside the default `/parapet` mount
  - Root and demo smoke tests proving default and scoped demo Operator UI routes
affects: [demo-operator-ui, host-route-scopes, UIROUTE-01, UIROUTE-02, UIROUTE-03]

tech-stack:
  added: []
  patterns:
    - Demo generated copies mirror template `operator_base_path` helpers and scoped local link construction
    - Demo router proves nested host scopes with a second host-owned `live_session`
    - Route-scope proof stays in tests/router only; live UI copy does not explain demo mount variants

key-files:
  created:
    - .planning/phases/38-scoped-ui-routes/38-02-SUMMARY.md
  modified:
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - examples/demo_app/lib/demo_app_web/router.ex
    - examples/demo_app/test/demo_app/operator_smoke_test.exs
    - test/parapet/operator_ui_demo_contract_test.exs
    - test/parapet/operator_ui_integration_test.exs

key-decisions:
  - "Keep the nested `/ops` route proof in the demo host router, preserving Parapet's no-auth-ownership boundary."
  - "Pin scoped demo behavior with static root contracts and runnable demo smoke tests instead of adding visible route-scope explanation copy."

patterns-established:
  - "Demo generated-copy drift guard: root integration tests assert the same scoped helper identifiers in templates and checked-in demo copies."
  - "Scoped demo route proof: `scope \"/ops\"` wraps the existing `/parapet` route map in a separate `:parapet_operator_scoped` live session."

requirements-completed: [UIROUTE-01, UIROUTE-02, UIROUTE-03]

duration: 36min
completed: 2026-06-04
---

# Phase 38 Plan 02: Demo Scoped Operator UI Route Proof Summary

**Checked-in demo Operator UI copies now mirror the generated scoped-route helpers, and the runnable demo proves both `/parapet` and `/ops/parapet` host mounts.**

## Performance

- **Duration:** 36 min including recovery from the prior disconnected executor
- **Started:** 2026-06-04T19:48:03Z
- **Completed:** 2026-06-04T20:23:45Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Synced the demo copied `OperatorLive`, `OperatorDetailLive`, and `OperatorComponents` files to the generated `operator_base_path` helper shape from Plan 01.
- Added a demo-only nested host scope at `/ops` with a separate `:parapet_operator_scoped` live session while preserving the existing `/parapet` route map and auth warning.
- Added root contract and demo app smoke coverage for `/ops/parapet`, `/ops/parapet/actions`, `/ops/parapet/history`, `/ops/parapet/incidents/:id`, and `/ops/parapet/:id`.
- Strengthened static demo-copy assertions so scoped route helpers are required while active workbench copy and layout markers stay unchanged.

## Task Commits

1. **Task 1: Copy scoped route helper shape into demo LiveView files and drift tests** - `0176ac8` (feat)
2. **Task 2 RED: Add failing scoped demo route proof** - `f5e1d5a` (test)
3. **Task 2 GREEN: Add nested demo route map and scoped smoke proof** - `2fd4219` (feat)
4. **Task 3: Verify demo copy scoped route behavior without UI redesign** - `ddd9c0f` (test)

## Files Created/Modified

- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` - Uses `operator_base_path` for queue, history, refresh, pagination, and child component route construction.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` - Derives `operator_base_path` from the current URI and uses it for detail refresh and back navigation.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` - Accepts `operator_base_path` and builds nav, queue item, action rail, and detail links from helper functions.
- `examples/demo_app/lib/demo_app_web/router.ex` - Adds the host-owned `/ops` nested proof scope and `:parapet_operator_scoped` live session.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` - Adds runnable scoped smoke tests for response, actions, history, preferred detail, and compatibility detail routes.
- `test/parapet/operator_ui_demo_contract_test.exs` - Pins the default and scoped demo route maps and scoped smoke proof strings.
- `test/parapet/operator_ui_integration_test.exs` - Pins demo/template helper drift plus no-redesign presentation markers.

## Decisions Made

- Kept route-scope proof in the demo host app rather than adding any Parapet-owned router or auth abstraction.
- Used the existing `/parapet` route declarations inside a host-owned `/ops` scope to prove nested mounting without changing production guidance.
- Kept scoped-route explanation out of visible LiveView copy; the `/ops/parapet` strings are limited to router/tests.

## Deviations from Plan

None - plan scope and threat mitigations were executed as written. Recovery resumed from the prior executor's committed Task 1 and Task 2 RED work without amending or duplicating those commits.

## Issues Encountered

- Prior executor stream disconnected after committing `0176ac8` and `f5e1d5a`, leaving the scoped router map uncommitted. Recovery preserved those commits, committed the router as Task 2 GREEN, then completed Task 3.

## TDD Gate Compliance

- RED gate present: `f5e1d5a test(38-02): add failing scoped demo route proof`
- GREEN gate present after RED: `2fd4219 feat(38-02): add scoped demo operator route map`

## Verification

- `mix test test/parapet/operator_ui_integration_test.exs` - 16 tests, 0 failures
- `mix test test/parapet/operator_ui_demo_contract_test.exs` - 5 tests, 0 failures
- `cd examples/demo_app && MIX_ENV=test mix test test/demo_app/operator_smoke_test.exs` - 10 tests, 0 failures
- `mix test test/parapet/operator_ui_demo_contract_test.exs test/parapet/operator_ui_integration_test.exs` - 21 tests, 0 failures
- `rg -n 'Default mount:|Scoped mount:|/ops/parapet' examples/demo_app/lib/demo_app_web/live/parapet` - no matches

## Known Stubs

None found in files created or modified by this plan.

## Threat Flags

None. The demo nested route map and scoped local-link behavior were already covered by the plan threat model, no auth ownership moved into Parapet, and no dependency files changed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 03 can document the scoped UI mounting pattern with runnable demo proof in place. The default `/parapet` route map remains available, and `/ops/parapet` is now pinned by root contracts plus demo smoke tests.

## Self-Check: PASSED

- Found summary file and all seven plan-modified files.
- Found task commits `0176ac8`, `f5e1d5a`, `2fd4219`, and `ddd9c0f`.
- Stub scan found no tracked placeholder patterns in files created or modified by this plan.

---
*Phase: 38-scoped-ui-routes*
*Completed: 2026-06-04*
