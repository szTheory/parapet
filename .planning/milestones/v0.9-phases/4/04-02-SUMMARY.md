---
phase: 04-unified-install-path-dx
plan: 02
subsystem: testing
tags: [doctor, oban, cluster, telemetry]
requires:
  - phase: 04-unified-install-path-dx
    provides: Installer contract for the Day-1 verification step
provides:
  - Severity-aware doctor thresholds
  - Static cluster posture checks
  - Runtime `mix parapet.doctor cluster` mode
affects: [docs, install, operator-ui]
tech-stack:
  added: []
  patterns: [severity-thresholds, honest-static-checks]
key-files:
  created: []
  modified:
    - lib/mix/tasks/parapet.doctor.ex
    - test/mix/tasks/parapet.doctor_test.exs
key-decisions:
  - "Exit code `2` is reserved for doctor/probe execution failure, not ordinary findings."
  - "Static cluster checks must explicitly say they cannot prove distributed correctness."
patterns-established:
  - "Local doctor runs fail only on `error`; CI can opt into `warn` as the failure threshold."
  - "Runtime cluster mode reports live facts separately from static posture analysis."
requirements-completed: [DX-01]
duration: 20m
completed: 2026-05-20
---

# Phase 04: Unified Install Path Summary

**`mix parapet.doctor` now distinguishes warnings from hard errors, reserves exit code `2` for probe failures, and exposes an honest runtime cluster mode.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-05-20T21:20:00Z
- **Completed:** 2026-05-20T21:45:17Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Reworked doctor status handling around `info`, `warn`, `error`, and `skip`, with `--ci` and `--threshold warn|error`.
- Added cluster-static checks for escalation uniqueness and policy posture, with explicit uncertainty wording.
- Added `mix parapet.doctor cluster` and tests covering skip-mode live facts plus probe-failure exit code `2`.

## Task Commits

Each task was completed in the working tree:

1. **Task 1: Introduce severity, threshold, and exit-code semantics without breaking machine-readable output** - not committed in this run (dirty worktree preserved)
2. **Task 2: Add honest multi-node checks and a runtime-oriented doctor mode** - not committed in this run (dirty worktree preserved)

**Plan metadata:** not committed in this run

## Files Created/Modified

- `lib/mix/tasks/parapet.doctor.ex` - threshold parsing, static/runtime check routing, and execution-failure semantics
- `test/mix/tasks/parapet.doctor_test.exs` - regression coverage for threshold overrides, operator UI warnings, cluster posture, and probe failures

## Decisions Made

- Preserved the existing cardinality check and folded it into the new severity model instead of dropping the earlier safety work.
- Kept cluster probe injection test-only through app env so the public CLI stays minimal.

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** None.

## Issues Encountered

- The prior doctor implementation used `fatal` for ordinary findings. The rewrite normalized those cases to `error` so exit code `2` could be reserved for actual doctor/probe execution failures.
- Phase commits were intentionally not created because the repo already contained unrelated in-progress changes and this run preserved that dirty worktree.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Public docs can now describe local vs CI thresholds and the runtime `cluster` mode accurately.
- The installer summary can safely point maintainers at `mix parapet.doctor` as the next step.

---
*Phase: 04-unified-install-path-dx*
*Completed: 2026-05-20*
