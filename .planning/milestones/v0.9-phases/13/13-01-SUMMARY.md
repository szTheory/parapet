---
phase: 13-repair-generated-operator-resolve-flow
plan: 01
subsystem: testing
tags: [operator-ui, generated-ui, liveview, resolve, regression]
requires: []
provides:
  - generated queue resolve wired to the public operator seam
  - targeted runtime proof that queue resolve leaves the active lane and appears in resolved history
affects: [phase-3-proof-lane, phase-7-proof-chain, generated-operator-ui]
tech-stack:
  added: []
  patterns: [generated-ui seam assertion, fake repo multi execution, bounded liveview regression lane]
key-files:
  created:
    - .planning/phases/13-repair-generated-operator-resolve-flow/13-01-SUMMARY.md
  modified:
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - test/parapet/operator_ui_integration_test.exs
    - test/mix/tasks/parapet.gen.ui_test.exs
    - test/parapet/generated_operator_live_paging_test.exs
key-decisions:
  - "Kept queue-side resolve on `Parapet.Operator.resolve_incident/2` with the same `ActionPayload` shape already used by the generated detail LiveView."
  - "Extended the existing generated runtime lane instead of adding a heavier browser harness, using a richer fake repo transaction path to exercise `Parapet.Evidence.run_operator_command/1`."
patterns-established:
  - "Generated queue actions should prove the public operator seam with both source-contract assertions and a narrow runtime lifecycle test."
requirements-completed: [SCALE-01.c]
duration: 13min
completed: 2026-05-23
---

# Phase 13 Plan 01: Generated Resolve Repair Summary

**The generated operator queue now resolves incidents through the real operator command seam, and the targeted proof lane catches regressions where queue-side resolve stops moving incidents from active scope into resolved history.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-05-23T12:00:05Z
- **Completed:** 2026-05-23T12:13:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Rewired the generated queue `handle_event("resolve", ...)` path to call `Parapet.Operator.resolve_incident/2` with the real `%Parapet.Operator.ActionPayload{}` contract.
- Tightened the generator/source-contract tests so they assert `resolve_incident` is present and the old `record_note` seam is absent.
- Extended the generated runtime lane with fake-repo `Ecto.Multi` support and a lifecycle assertion proving queue-side resolve removes an incident from the active page and surfaces it in resolved history.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewire generated queue resolve to the public operator seam** - `871c1e9` (fix)
2. **Task 2: Extend the generated runtime lane to prove queue resolve changes rendered lifecycle state** - `a570c70` (test)

## Files Created/Modified

- `priv/templates/parapet.gen.ui/operator_live.ex.eex` - Queue resolve now uses `Parapet.Operator.resolve_incident/2`.
- `test/parapet/operator_ui_integration_test.exs` - Source-contract guard for the queue resolve seam.
- `test/mix/tasks/parapet.gen.ui_test.exs` - Generator-output assertion for the emitted resolve seam.
- `test/parapet/generated_operator_live_paging_test.exs` - Runtime lifecycle proof plus richer fake-repo transaction support.
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-01-SUMMARY.md` - Execution record for this plan.

## Verification

```bash
mix test test/parapet/generated_operator_live_paging_test.exs test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs
```

Result: passed (`14 tests, 0 failures`).

## Decisions Made

- Reused the existing generated-runtime proof lane instead of introducing a new UI harness.
- Simulated the audited mutation path in the fake repo closely enough to exercise `Ecto.Multi.update`, `Ecto.Multi.insert`, and `Ecto.Multi.run` during queue-side resolve.

## Deviations from Plan

None - plan executed as written. The only workflow deviation was that the executor agent stalled after Task 1, so the orchestrator completed Task 2 directly without changing plan scope.

## Issues Encountered

- The first executor agent did not return after its initial commit. The remaining task was completed inline after confirming the tree state and re-running the targeted proof lane.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 13 Plan 02 can now reconcile the canonical proof surfaces against the repaired runtime lane.
- The existing `docs/operator-ui.md` user edits must be preserved while adding the narrow Phase 3 proof note.

## Self-Check: PASSED

- Confirmed both task commits exist in git history.
- Confirmed `.planning/phases/13-repair-generated-operator-resolve-flow/13-01-SUMMARY.md` exists.
- Confirmed the targeted resolve proof lane passes on the current tree.

---
*Phase: 13-repair-generated-operator-resolve-flow*
*Completed: 2026-05-23*
