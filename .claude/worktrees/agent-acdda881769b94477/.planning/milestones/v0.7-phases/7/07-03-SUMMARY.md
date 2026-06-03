---
phase: 07
plan: 03
subsystem: operator
tags:
  - workbench
  - recovery
  - runbooks
  - preview-first
dependency_graph:
  requires:
    - 07-01
    - 07-02
  provides:
    - Preview-first operator recovery UI
    - Bounded runbook attachment for incidents
  affects:
    - Generated operator workbench
tech_stack:
  added: []
  patterns:
    - Preview-Confirm-Execute flow
    - View model derivation for safe recovery
key_files:
  created: []
  modified:
    - lib/parapet/operator/workbench_contract.ex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - docs/operator-ui.md
decisions:
  - Derived runbook steps into four states (executed, guidance, previewable, executable) to guide the operator safely.
  - Introduced a dedicated preview panel in the generated UI to show exact scope, warnings, and idempotency caveats.
metrics:
  duration: 45m
  completed_date: "2026-05-18"
---

# Phase 07 Plan 03: Safe Recovery UI and Doctrine Summary

Phase 7 concludes by wiring bounded runbook attachment, preview-first operator rendering, and safe investigation doctrine into the generated workbench.

## Key Achievements

- **Preview-First Recovery Flow:** Replaced one-click mutations with an explicit Preview -> Confirm -> Execute flow in the generated LiveView. This ensures operators see the exact scope and warnings before any destructive action.
- **Enhanced Workbench Contract:** Extended `Parapet.Operator.WorkbenchContract` to derive a rich recovery view model from durable evidence, including step states, targeting hints for `ActionItem`s, and active preview detection.
- **Guidance vs Execution:** The UI now distinguishes between steps that provide guidance (informational only) and those that are executable via host capabilities.
- **Updated Doctrine:** Updated `docs/operator-ui.md` with "Phase 7 Preview-First Recovery" principles, emphasizing that chronology and triage come first, and recovery is a bounded follow-up layer.

## Deviations from Plan

None - plan executed as written. Existing unstaged changes were reviewed and found to align perfectly with the plan's objectives.

## Verification Results

- `mix test test/parapet/operator/workbench_contract_test.exs test/parapet/spine/alert_processor_test.exs`: Passed (15 tests).
- `mix compile --warnings-as-errors`: Passed.
- Manual inspection of generated templates confirms the removal of direct `execute_runbook_step` calls in favor of the preview/confirm lifecycle.

## Self-Check: PASSED
