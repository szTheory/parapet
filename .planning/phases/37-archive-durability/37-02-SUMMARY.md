---
phase: 37-archive-durability
plan: 02
subsystem: evidence
tags: [archive, mix-task, oban, cli, failure-context]

requires:
  - phase: 37-archive-durability
    provides: structured archive Summary and Failure result contract
provides:
  - result-sensitive archive Mix task output
  - optional Oban worker pass-through tests for structured archive tuples
affects: [archive, docs, operations]

tech-stack:
  added: []
  patterns:
    - machine-readable Mix task success JSON
    - Mix.raise failure boundary for maintenance commands
    - optional worker tuple pass-through

key-files:
  created:
    - .planning/phases/37-archive-durability/37-02-SUMMARY.md
  modified:
    - lib/mix/tasks/parapet.archive.ex
    - test/mix/tasks/parapet.archive_test.exs
    - test/parapet/evidence/archive_worker_test.exs

key-decisions:
  - "mix parapet.archive emits only Summary-derived JSON on success and raises on Failure."
  - "ArchiveWorker source remained minimal because it already returns Parapet.Evidence.Archiver.archive/3 unchanged."

patterns-established:
  - "Maintenance command failures include stage, path, run id, manifest path, selected count, archived count, and deleted count."
  - "Optional Oban worker tests assert pass-through semantics without expanding dependency ownership."

requirements-completed: [ARCH-02, ARCH-04]

duration: 0h 08m
completed: 2026-06-04
---

# Phase 37 Plan 02: Archive Caller Surfaces Summary

**Archive CLI and optional Oban worker now preserve structured archive success and failure truth**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-04T19:15:00Z
- **Completed:** 2026-06-04T19:23:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Updated `mix parapet.archive` to print Summary-derived JSON on success.
- Updated `mix parapet.archive` to `Mix.raise/1` on Failure with stage, path, run id, manifest path, and selected/archived/deleted counts.
- Rewrote CLI tests to prove machine-readable success output and failure output that does not emit static success JSON.
- Updated worker tests to prove `%Summary{}` and `%Failure{}` tuples are returned unchanged while preserving default args and optional Oban compile-out behavior.

## Task Commits

1. **Tasks 1-2: structured caller result surfaces** - `1c76e2e` (feat)

## Files Created/Modified

- `lib/mix/tasks/parapet.archive.ex` - Pattern matches archive result tuples and emits honest CLI success/failure output.
- `test/mix/tasks/parapet.archive_test.exs` - Covers Summary JSON output, defaults, and Mix.Error failure context.
- `test/parapet/evidence/archive_worker_test.exs` - Covers worker Summary and Failure pass-through.

## Decisions Made

- Kept `Parapet.Evidence.ArchiveWorker` source unchanged because it already delegates directly to the archiver and therefore preserves the structured tuple contract after Plan 01.
- Used a compact CLI failure string with key/value context so cron logs and operator output remain easy to scan.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/mix/tasks/parapet.archive_test.exs` - passed
- `mix test test/parapet/evidence/archive_worker_test.exs` - passed
- `mix test test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` - passed
- `mix format --check-formatted` - passed
- `mix compile --warnings-as-errors` - passed

## Next Phase Readiness

Plan 03 can document the Experimental API change, retention limitation, and run the broad verification loop.

---
*Phase: 37-archive-durability*
*Completed: 2026-06-04*
