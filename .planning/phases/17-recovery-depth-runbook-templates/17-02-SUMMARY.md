---
phase: 17-recovery-depth-runbook-templates
plan: "02"
subsystem: runbook-templates
tags: [runbooks, templates, warning-dsl, recovery-depth, RCV-01]
dependency_graph:
  requires: ["17-01"]
  provides: ["four-deepened-templates"]
  affects: ["priv/templates/parapet.gen.runbooks/", "operator-ui-warning-rendering"]
tech_stack:
  added: []
  patterns:
    - "warning: string field on runbook steps (consumed by 17-01 DSL surface)"
    - "type: :manual, kind: :guidance, preview_only: true for precondition + verification steps"
    - "type: :mitigation, kind: :guidance, preview_only: true for guidance-only mitigations (no capability)"
key_files:
  created: []
  modified:
    - priv/templates/parapet.gen.runbooks/dead_letter.ex.eex
    - priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex
    - priv/templates/parapet.gen.runbooks/provider_outage.ex.eex
    - priv/templates/parapet.gen.runbooks/callback_delay.ex.eex
decisions:
  - "callback_delay mitigation is guidance-only (type: :mitigation, kind: :guidance) — no allowlisted capability fits callback-delay remediation (D-06)"
  - "warning: annotations placed on precondition and mitigation steps per Pitfall 4 guidance — verification steps carry no warning: (operator reads warnings before acting)"
  - "All wired mitigations retain requires_preview: true — preview-first, bounded (T-17-06 mitigated)"
  - "No new capability: ids introduced — only :requeue_dead_letter, :retry_async_item, :request_manual_provider_check reused (T-17-05 mitigated)"
metrics:
  duration: "~8 minutes"
  completed: "2026-05-24"
  tasks_completed: 2
  files_modified: 4
---

# Phase 17 Plan 02: Deepen Four Runbook Templates Summary

Four existing 1-2 step runbook template stubs deepened to RCV-01 full depth: added `warning:` annotations to precondition and mitigation steps, added distinct `:verify_recovery` guidance steps, and brought `callback_delay` from a single-step stub to a three-step guidance-only flow.

## What Was Built

### Task 1: dead_letter and stalled_executor (commit 4936ff8)

**dead_letter.ex.eex** — went from 2 steps to 3 steps:
- `:investigate_error` (existing) — added `warning:` about not requeuing structural failures
- `:requeue_item` (existing, `capability: :requeue_dead_letter`) — added `warning:` about idempotency requirement
- `:verify_recovery` (new) — `type: :manual, kind: :guidance, preview_only: true` confirming item transitions out of dead letter queue

**stalled_executor.ex.eex** — went from 2 steps to 3 steps:
- `:investigate_logs` (existing) — added `warning:` about active execution race guard
- `:retry_item` (existing, `capability: :retry_async_item`) — added `warning:` about deadlock root cause first
- `:verify_recovery` (new) — `type: :manual, kind: :guidance, preview_only: true` confirming item completes

### Task 2: provider_outage and callback_delay (commit ec9f8f5)

**provider_outage.ex.eex** — went from 2 steps to 3 steps:
- `:check_status` (existing) — added `warning:` about status page unreachability during full outage
- `:request_manual_check` (existing, `capability: :request_manual_provider_check`) — added `warning:` about duplicate flags
- `:verify_recovery` (new) — `type: :manual, kind: :guidance, preview_only: true` confirming provider recovery

**callback_delay.ex.eex** — went from 1 step to 3 steps (most work, thinnest template):
- `:verify_receipt` (existing) — added `warning:` about receipt vs processing distinction
- `:mitigate_delay` (new) — `type: :mitigation, kind: :guidance, preview_only: true`, NO `capability:` (none of the three allowlisted capabilities fits callback delay); `warning:` about duplicate delivery risk
- `:verify_recovery` (new) — `type: :manual, kind: :guidance, preview_only: true` confirming callback processed

## RCV-01 Depth Checklist Satisfaction

| Template | Precondition | Scoped Preview | warning: | Mitigation | Verification |
|----------|-------------|----------------|----------|------------|--------------|
| dead_letter | ✓ (:investigate_error) | ✓ (requires_preview on :requeue_item) | ✓ (2x) | ✓ (:requeue_dead_letter) | ✓ (:verify_recovery) |
| stalled_executor | ✓ (:investigate_logs) | ✓ (requires_preview on :retry_item) | ✓ (2x) | ✓ (:retry_async_item) | ✓ (:verify_recovery) |
| provider_outage | ✓ (:check_status) | ✓ (requires_preview on :request_manual_check) | ✓ (2x) | ✓ (:request_manual_provider_check) | ✓ (:verify_recovery) |
| callback_delay | ✓ (:verify_receipt) | ✓ (guidance flow — no capability) | ✓ (2x) | ✓ (:mitigate_delay, guidance-only) | ✓ (:verify_recovery) |

## Acceptance Criteria Results

- `grep -c 'warning:' dead_letter.ex.eex` = 2 (>= 1) ✓
- `grep -c 'warning:' stalled_executor.ex.eex` = 2 (>= 1) ✓
- `grep -c 'warning:' provider_outage.ex.eex` = 2 (>= 1) ✓
- `grep -c 'warning:' callback_delay.ex.eex` = 2 (>= 1) ✓
- All four files contain `:verify_recovery` with `type: :manual` and `kind: :guidance` ✓
- dead_letter retains `capability: :requeue_dead_letter` and `requires_preview: true` ✓
- stalled_executor retains `capability: :retry_async_item` and `requires_preview: true` ✓
- provider_outage retains `capability: :request_manual_provider_check` and `requires_preview: true` ✓
- `grep -c 'capability:' callback_delay.ex.eex` = 0 ✓
- No non-allowlisted capability references in any file ✓

## Deviations from Plan

None — plan executed exactly as written. All template modifications followed PATTERNS.md skeletons with text authored at Claude's discretion per plan instructions.

## Known Stubs

None — all templates are fully wired. The `callback_delay` guidance-only mitigation (`:mitigate_delay`) intentionally has no capability because none of the three allowlisted capabilities fits callback-delay remediation (D-06). This is a design constraint, not a stub.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All changes are static compile-time template content. T-17-05 and T-17-06 mitigated per threat register:
- T-17-05: Only allowlisted capabilities used (`:requeue_dead_letter`, `:retry_async_item`, `:request_manual_provider_check`); callback_delay has zero capability references
- T-17-06: All wired mitigations retain `requires_preview: true`; guidance-only mitigations are inherently safe

## Self-Check: PASSED

Files verified:
- `priv/templates/parapet.gen.runbooks/dead_letter.ex.eex` — FOUND, contains 2x warning:, :verify_recovery, :requeue_dead_letter
- `priv/templates/parapet.gen.runbooks/stalled_executor.ex.eex` — FOUND, contains 2x warning:, :verify_recovery, :retry_async_item
- `priv/templates/parapet.gen.runbooks/provider_outage.ex.eex` — FOUND, contains 2x warning:, :verify_recovery, :request_manual_provider_check
- `priv/templates/parapet.gen.runbooks/callback_delay.ex.eex` — FOUND, contains 2x warning:, :mitigate_delay, :verify_recovery, 0 capability refs

Commits verified:
- 4936ff8 — feat(17-02): deepen dead_letter and stalled_executor templates ✓
- ec9f8f5 — feat(17-02): deepen provider_outage and callback_delay templates ✓

Generator test: `mix test test/mix/tasks/parapet.gen.runbooks_test.exs` — 1 test, 0 failures ✓
