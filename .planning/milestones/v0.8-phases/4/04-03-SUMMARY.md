---
phase: 04
plan: 03
subsystem: operator-ui-surfacing
tags: [operator, escalation, liveview, generated-ui]
requires: ["04-01", "04-02"]
provides:
  - escalation-aware generated operator detail surface
  - typed canonical timeline rendering for generated UI
  - bounded LiveView escalation controls and updated operator doctrine
affects:
  - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
  - priv/templates/parapet.gen.ui/operator_components.ex.eex
  - docs/operator-ui.md
tech_stack:
  added: []
  patterns:
    - summary-first escalation projection over durable operator detail payload
    - typed timeline rendering with explicit actor classes
    - public operator API routing for risky escalation controls
key_files:
  created:
    - .planning/milestones/v0.8-phases/4/04-03-SUMMARY.md
  modified:
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - docs/operator-ui.md
    - test/parapet/operator_ui_integration_test.exs
    - test/parapet/operator_ui_compile_out_test.exs
decisions:
  - Keep escalation truth as a compact summary projection above the canonical timeline instead of creating a second automation history surface.
  - Route manual escalation trigger and suppression through Parapet.Operator and refresh incident detail from the derived payload after each action.
metrics:
  completed_at: 2026-05-19
  task_commits: 2
---

# Phase 4 Plan 03: Operator UI Surfacing Summary

The generated operator detail UI now surfaces current escalation truth first, preserves one typed canonical chronology for system and operator evidence, and exposes only bounded escalation controls through the public operator API.

## Tasks Completed

1. **Task 1: Render escalation status and typed system-action chronology in generated components**
   - Added an escalation summary panel to the generated detail components with current status, next derived step, suppression context, and latest system-action evidence.
   - Replaced generic payload dumping in the timeline with typed rendering driven by `timeline_entries` and explicit actor classes.
   - Replaced generic mitigation placeholders with bounded escalation controls positioned after summary context and chronology.
   - Verification: `mix test test/parapet/operator_ui_integration_test.exs`
   - Commit: `a334115`

2. **Task 2: Wire bounded escalation interactions in the generated LiveView and update operator doctrine**
   - Added `trigger_next_escalation` and `suppress_pending_escalation` event handlers that build `Parapet.Operator.ActionPayload`s and call the public operator seam.
   - Refreshed `incident_detail/1` after escalation actions instead of introducing local escalation UI state.
   - Updated the operator UI guide to document the summary-first, canonical-timeline, durable-suppression, and host-owned posture.
   - Verification: `mix test test/parapet/operator_ui_compile_out_test.exs && mix compile --warnings-as-errors`
   - Commit: `c8355c3`

## Verification

- `mix test test/parapet/operator_ui_integration_test.exs`
- `mix test test/parapet/operator_ui_compile_out_test.exs`
- `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs && mix compile --warnings-as-errors`

All commands passed.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Found: `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`
- Found: `priv/templates/parapet.gen.ui/operator_components.ex.eex`
- Found: `docs/operator-ui.md`
- Found: `test/parapet/operator_ui_integration_test.exs`
- Found: `test/parapet/operator_ui_compile_out_test.exs`
- Found commit: `a334115`
- Found commit: `c8355c3`
