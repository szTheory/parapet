---
phase: 35-design-system-consolidation
plan: "01"
subsystem: ui
tags: [phoenix-liveview, generated-ui, tailwind, design-system, operator-ui]
requires:
  - phase: 34-operator-ia-navigation-foundation
    provides: active-response Operator UI route and IA foundation
provides:
  - Generated Operator UI local helper families for surfaces, controls, and chips
  - Audit/risk copy pinned around recovery, escalation, action item, acknowledge, and resolve controls
  - Source-contract tests for generated and demo design-system alignment
affects: [phase-36-demo-state-coverage-browser-verification, operator-ui, mix-parapet-gen-ui]
tech-stack:
  added: []
  patterns: [private generated LiveView helper functions, source-contract UI tests]
key-files:
  created:
    - .planning/phases/35-design-system-consolidation/35-01-SUMMARY.md
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - test/mix/tasks/parapet.gen.ui_test.exs
    - test/parapet/operator_ui_integration_test.exs
key-decisions:
  - "Kept design-system consolidation local to the generated component module; no runtime package, public module, dependency, router, or auth ownership change."
  - "Mirrored generated component helper/copy changes into the demo component copy in the same implementation commit to avoid generated/demo drift."
  - "Used source-contract assertions as the phase proof; browser screenshot verification remains Phase 36."
patterns-established:
  - "Generated UI class consolidation uses private helper functions such as surface_class/1, control_class/1, control_class/2, and chip_class/2."
  - "Mutating operator controls carry pre-click audit/risk copy pinned by source tests."
requirements-completed:
  - UI-DS-01
  - UI-DS-02
  - UI-DS-03
  - UI-DS-04
  - UI-DS-05
duration: 7 min
completed: 2026-06-03
---

# Phase 35 Plan 01: Design-System Consolidation Summary

**Generated Operator UI component helpers for shared surfaces, controls, chips, and audit-safe action copy**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-03T22:32:36Z
- **Completed:** 2026-06-03T22:39:34Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added local generated helper families for repeated card surfaces, controls, and chips in `operator_components`.
- Replaced drift-prone repeated action/card/control class strings in the generated template and demo mirror.
- Added exact pre-click audit/risk copy for Preview, Confirm, escalation trigger, escalation suppression, action item review, acknowledge, and resolve controls.
- Extended generator and integration source-contract tests to pin helper names, required copy, focus-ring/motion constraints, demo alignment, and absence of `transition-all`.

## Task Commits

1. **Tasks 1-3: Consolidate generated component helpers, pin safety copy, and sync demo mirror** - `6e52508` (feat)

**Plan metadata:** pending in final metadata commit.

## Files Created/Modified

- `.planning/phases/35-design-system-consolidation/35-01-SUMMARY.md` - Plan completion summary.
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` - Generated helper families and required audit/risk copy.
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` - Demo mirror of generated helper/copy changes.
- `test/mix/tasks/parapet.gen.ui_test.exs` - Generator source assertions for helper names, copy, and motion.
- `test/parapet/operator_ui_integration_test.exs` - Generated/demo source-contract assertions.

## Decisions Made

- Kept helper consolidation private to generated component modules, matching the Phase 35 context and UI spec.
- Used existing string/source assertions rather than adding browser verification, preserving Phase 36 ownership of screenshot automation.
- Removed an unused `surface_class(:quiet)` helper after demo compilation warned that the clause was unused.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed unused helper clauses after demo compile warning**
- **Found during:** Task 3 (demo smoke verification)
- **Issue:** `surface_class(:quiet)` compiled with an unused-clause warning in the demo component module.
- **Fix:** Removed unused `surface_class(:quiet)` and `control_class(:quiet, _)` clauses from generated and demo component modules.
- **Files modified:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`, `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`
- **Verification:** `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` passed with 5 tests, 0 failures and no new unused helper warning.
- **Committed in:** `6e52508`

**2. [Execution Shape] Combined overlapping plan tasks into one implementation commit**
- **Found during:** Task execution
- **Issue:** The three plan tasks intentionally touched the same component/test files, so separate commits would have required artificial partial states.
- **Fix:** Implemented the coherent generated-template/demo/test change together and verified all task acceptance criteria before committing.
- **Files modified:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`, `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`, `test/mix/tasks/parapet.gen.ui_test.exs`, `test/parapet/operator_ui_integration_test.exs`
- **Verification:** Targeted generated UI tests, demo smoke test, and touched-file format check passed.
- **Committed in:** `6e52508`

---

**Total deviations:** 2 handled (1 blocking compile-warning fix, 1 commit-shape deviation)
**Impact on plan:** No scope expansion. The implementation still satisfied all planned task acceptance criteria and preserved Phase 35 boundaries.

## Issues Encountered

- Full `mix format --check-formatted` fails on pre-existing unrelated files outside the Phase 35 change set, including `lib/parapet/automation/claim_service.ex`, `lib/parapet/capabilities.ex`, `lib/parapet/slo/registry.ex`, and several tests. Touched files pass `mix format --check-formatted test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`.
- Demo smoke test still emits the pre-existing warning that `Parapet.Escalation.Worker.new/1` is undefined while compiling `lib/parapet/evidence.ex`; tests pass.

## Verification

- `mix test test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs` - 22 tests, 0 failures.
- `cd examples/demo_app && mix test test/demo_app/operator_smoke_test.exs` - 5 tests, 0 failures.
- `mix format --check-formatted test/mix/tasks/parapet.gen.ui_test.exs test/parapet/operator_ui_integration_test.exs examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` - passed.
- Full `mix format --check-formatted` - failed on unrelated pre-existing files listed above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 36 can build on the generated/demo component helper surface and browser-verify the response, actions, history, and detail routes with richer demo states. No Phase 36 blocker from this plan.

---
*Phase: 35-design-system-consolidation*
*Completed: 2026-06-03*
