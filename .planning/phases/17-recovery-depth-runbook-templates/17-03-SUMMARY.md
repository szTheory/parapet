---
phase: 17-recovery-depth-runbook-templates
plan: "03"
subsystem: runbook-templates
tags: [runbooks, templates, generator, regression-test, RCV-02]
dependency_graph:
  requires: ["17-01", "17-02"]
  provides: ["retry_storm template", "suppression_drift template", "partial_backlog_drain template", "D-11 layer 3 complete"]
  affects: ["lib/mix/tasks/parapet.gen.runbooks.ex", "test/mix/tasks/parapet.gen.runbooks_test.exs"]
tech_stack:
  added: []
  patterns: ["guidance-only mitigation (type: :mitigation, kind: :guidance, preview_only: true)", "capability-backed mitigation (:retry_async_item, requires_preview: true)", "on_exists: :skip host-ownership contract"]
key_files:
  created:
    - priv/templates/parapet.gen.runbooks/retry_storm.ex.eex
    - priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex
    - priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex
  modified:
    - lib/mix/tasks/parapet.gen.runbooks.ex
    - test/mix/tasks/parapet.gen.runbooks_test.exs
decisions:
  - "retry_storm is guidance-only (no :retry_async_item capability) — RESEARCH D-07 correction applied: retrying storming items worsens worker exhaustion"
  - "suppression_drift is guidance-only — no allowlisted capability fits escalation suppression state management"
  - "partial_backlog_drain uses :retry_async_item with target_kind: :async_item, requires_preview: true — exact semantic fit for stuck-subset retry"
  - "All three new copy_template calls use on_exists: :skip preserving the 4+3=7 host-ownership contract"
metrics:
  duration: "3 minutes"
  completed: "2026-05-24T15:37:24Z"
  tasks_completed: 3
  files_created: 3
  files_modified: 2
---

# Phase 17 Plan 03: Three New Runbook Templates (retry_storm, suppression_drift, partial_backlog_drain) Summary

**One-liner:** Three new full-depth runbook templates with guidance-only and :retry_async_item mitigations, wired into the generator with on_exists: :skip, completing the D-11 three-layer regression test contract.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author retry_storm and suppression_drift (guidance-only) | 7339774 | priv/templates/parapet.gen.runbooks/retry_storm.ex.eex, suppression_drift.ex.eex |
| 2 | Author partial_backlog_drain, wire all three into generator | af2d3f9 | priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex, lib/mix/tasks/parapet.gen.runbooks.ex |
| 3 | Extend generator-content regression test (D-11 layer 3) | 9c193dd | test/mix/tasks/parapet.gen.runbooks_test.exs |

## What Was Built

### retry_storm.ex.eex (guidance-only)
Three-step template at full RCV-02 depth:
1. `:assess_storm` — precondition (type: :manual, kind: :guidance, preview_only: true) with warning about retry-accelerating mitigations worsening the storm
2. `:reduce_retry_pressure` — GUIDANCE-ONLY mitigation (type: :mitigation, kind: :guidance, preview_only: true) instructing operators to increase backoff / reduce concurrency / pause queue via host tooling; warning about delaying legitimate work
3. `:verify_storm_cleared` — verification (type: :manual, kind: :guidance, preview_only: true)

No `capability:` dispatch. Per RESEARCH.md D-07 correction: executing `:retry_async_item` on storming items worsens the storm — overrides CONTEXT.md D-07.

### suppression_drift.ex.eex (guidance-only)
Three-step template at full RCV-02 depth:
1. `:identify_drifted_suppressions` — precondition with warning that stale suppressions silently block escalations
2. `:clear_stale_suppressions` — GUIDANCE-ONLY mitigation; warning that clearing may immediately trigger escalation
3. `:verify_escalation_restored` — verification

No `capability:` dispatch. None of the three allowlisted capabilities address escalation suppression state.

### partial_backlog_drain.ex.eex (capability-backed)
Three-step template at full RCV-02 depth:
1. `:identify_stuck_items` — precondition with warning about retrying non-idempotent healthy items
2. `:retry_stuck_items` — capability mitigation (`capability: :retry_async_item`, `target_kind: :async_item`, `requires_preview: true`); warning to review preview count before confirming
3. `:verify_drain` — verification

Exact semantic fit: `:retry_async_item` retries a bounded stuck subset, scoped by the operator via preview.

### Generator (lib/mix/tasks/parapet.gen.runbooks.ex)
Three new `Igniter.copy_template` calls added after line 56 (before `Igniter.add_notice`), one per new template, each with `on_exists: :skip`. Total `on_exists: :skip` count: **7** (4 existing + 3 new). T-17-08 mitigated.

### Test extension (test/mix/tasks/parapet.gen.runbooks_test.exs)
D-11 Layer 3 (generator-content) now complete:
- 3 new file-path assertions (retry_storm.ex, suppression_drift.ex, partial_backlog_drain.ex)
- 3 new content-assertion blocks (each asserts `warning:`; partial_backlog_drain also asserts `capability: :retry_async_item`)
- 4 existing template blocks extended to assert `warning:` (proves 17-02 deepening landed at generated-content layer)
- All 7 templates assert `warning:` in the generated content

## Verification

```
grep -c 'on_exists: :skip' lib/mix/tasks/parapet.gen.runbooks.ex
# => 7

mix test test/mix/tasks/parapet.gen.runbooks_test.exs
# => 1 test, 0 failures
```

## Threat Mitigations Applied

| Threat | Disposition | Outcome |
|--------|-------------|---------|
| T-17-08: copy_template without on_exists: :skip | mitigated | All 3 new calls use on_exists: :skip (7 total asserted) |
| T-17-09: unwired capability in new template | mitigated | retry_storm/suppression_drift have 0 capability: refs (grep verified); partial_backlog_drain reuses only :retry_async_item |
| T-17-10: retry_storm wired to :retry_async_item (safety) | mitigated | retry_storm is GUIDANCE-ONLY per RESEARCH D-07 correction; capability: count == 0 asserted |
| T-17-11: destructive mitigation without scoped preview | mitigated | partial_backlog_drain uses requires_preview: true; guidance-only mitigations dispatch no capability |

## Deviations from Plan

None — plan executed exactly as written. All RESEARCH.md corrections (D-07: retry_storm guidance-only; D-10: distinct precondition/verification steps) were followed as specified in the plan.

## Known Stubs

None. All three templates are fully wired into the generator and generate correctly. The generator-content test asserts all required content patterns.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

Created files exist:
- priv/templates/parapet.gen.runbooks/retry_storm.ex.eex: FOUND
- priv/templates/parapet.gen.runbooks/suppression_drift.ex.eex: FOUND
- priv/templates/parapet.gen.runbooks/partial_backlog_drain.ex.eex: FOUND

Commits exist:
- 7339774: feat(17-03): author retry_storm and suppression_drift guidance-only templates
- af2d3f9: feat(17-03): author partial_backlog_drain template and wire all three into generator
- 9c193dd: test(17-03): extend generator-content regression test (D-11 layer 3)
