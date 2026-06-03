---
phase: 04
plan: 02
subsystem: operator-ui-surfacing
tags: [operator, escalation, evidence, ui-contract]
requires: ["04-01"]
provides:
  - escalation-aware workbench contract
  - escalation-aware incident detail payload
affects:
  - lib/parapet/operator/workbench_contract.ex
  - lib/parapet/operator.ex
tech_stack:
  added: []
  patterns:
    - escalation summary derived from incident-owned state plus typed chronology
    - explicit actor classification for timeline presentation helpers
    - evidence-first incident detail payload with canonical chronology preserved
key_files:
  created:
    - .planning/milestones/v0.8-phases/4/04-02-SUMMARY.md
  modified:
    - lib/parapet/operator/workbench_contract.ex
    - lib/parapet/operator.ex
    - test/parapet/operator/workbench_contract_test.exs
    - test/parapet/operator_test.exs
decisions:
  - Keep escalation status as a read-only projection over incident-owned state and typed chronology rather than a second UI state machine.
  - Expose actor distinction as explicit timeline presentation semantics so generated UI code does not infer system versus human actions ad hoc.
metrics:
  completed_at: 2026-05-19
  task_commits: 2
---

# Phase 4 Plan 02: Escalation-Aware Workbench Contract Summary

The operator detail contract now projects escalation status, suppression state, recent system action, and explicit actor classes directly from durable incident evidence.

## Tasks Completed

1. **Task 1: Derive escalation summary and actor classes from durable evidence**
   - Extended `Parapet.Operator.WorkbenchContract` with `escalation_summary` and `timeline_presentations`.
   - Derived suppression, pending-trigger, latest-event, next-step, and recent system-action facts from bounded incident state plus typed chronology.
   - Added explicit timeline actor classes for system, operator, copilot, external, and neutral evidence entries.
   - Verification: `mix test test/parapet/operator/workbench_contract_test.exs`
   - Commit: `a1f464f`

2. **Task 2: Return an escalation-aware incident detail payload for generated UI**
   - Extended `Parapet.Operator.incident_detail/1` to expose `escalation_summary` and zipped `timeline_entries` helpers while preserving canonical `entries`.
   - Kept runbook, action-item, and external-link surfaces intact beside the new derived escalation fields.
   - Verification: `mix test test/parapet/operator_test.exs`
   - Commit: `421a6ea`

## Verification

- `mix test test/parapet/operator/workbench_contract_test.exs`
- `mix test test/parapet/operator_test.exs`
- `mix test test/parapet/operator/workbench_contract_test.exs test/parapet/operator_test.exs`

All commands passed.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Found: `lib/parapet/operator/workbench_contract.ex`
- Found: `lib/parapet/operator.ex`
- Found: `test/parapet/operator/workbench_contract_test.exs`
- Found: `test/parapet/operator_test.exs`
- Found commit: `a1f464f`
- Found commit: `421a6ea`
