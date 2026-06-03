---
phase: 04
plan: 01
subsystem: operator-ui-surfacing
tags: [operator, escalation, evidence, worker]
requires: []
provides:
  - durable operator escalation commands
  - suppression-aware escalation worker chronology
affects:
  - lib/parapet/operator.ex
  - lib/parapet/escalation/worker.ex
tech_stack:
  added: []
  patterns:
    - bounded escalation command state in incident runbook_data
    - atomic operator command writes through Parapet.Evidence.run_operator_command/1
    - worker-side truth gating for suppression and manual trigger chronology
key_files:
  created:
    - .planning/milestones/v0.8-phases/4/04-01-SUMMARY.md
  modified:
    - lib/parapet/operator.ex
    - lib/parapet/escalation/worker.ex
    - test/parapet/operator_test.exs
    - test/parapet/escalation/worker_test.exs
decisions:
  - Keep manual trigger and suppression as bounded incident-owned escalation state plus typed timeline evidence instead of job mutation.
  - Keep the escalation worker as the final truth gate for suppression and execution mode semantics.
metrics:
  completed_at: 2026-05-19
  task_commits: 2
---

# Phase 4 Plan 01: Durable Escalation Control Seam Summary

Manual trigger and suppression now exist as durable, audited operator commands, and the escalation worker consumes that bounded state as the execution truth source.

## Tasks Completed

1. **Task 1: Add audited manual escalation and suppression commands**
   - Added `trigger_next_escalation/2` to persist manual trigger intent in bounded escalation state and append `escalation_trigger_requested`.
   - Added `suppress_pending_escalation/3` to validate a bounded window, persist suppression state, and append `escalation_suppressed`.
   - Verification: `mix test test/parapet/operator_test.exs`
   - Commit: `2edd1c4`

2. **Task 2: Teach the escalation worker to honor durable suppression and emit typed evidence**
   - Extended the worker to short-circuit on active suppression before policy execution and append typed suppression chronology.
   - Extended execution evidence to distinguish scheduled vs manual mode and include manual trigger provenance when present.
   - Verification: `mix test test/parapet/escalation/worker_test.exs`
   - Commit: `7744b34`

## Verification

- `mix test test/parapet/operator_test.exs`
- `mix test test/parapet/escalation/worker_test.exs`
- `mix test test/parapet/operator_test.exs test/parapet/escalation/worker_test.exs`

All commands passed.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Found: `lib/parapet/operator.ex`
- Found: `lib/parapet/escalation/worker.ex`
- Found: `test/parapet/operator_test.exs`
- Found: `test/parapet/escalation/worker_test.exs`
- Found commit: `2edd1c4`
- Found commit: `7744b34`
