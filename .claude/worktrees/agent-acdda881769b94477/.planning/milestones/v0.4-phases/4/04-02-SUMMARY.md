---
phase: 4
plan: 04-02
subsystem: "Scoria Integration"
tags:
  - telemetry
  - dual-track
  - action-item
  - scoria
dependency_graph:
  requires:
    - "04-01-SUMMARY.md"
  provides:
    - "Telemetry handlers for Scoria staleness and expiration"
  affects:
    - "lib/parapet/integrations/scoria.ex"
    - "lib/parapet/evidence.ex"
tech_stack:
  added: []
  patterns:
    - "Dual-Track Telemetry"
    - "Telemetry for UX, Adapter for Truth"
key_files:
  created: []
  modified:
    - "lib/parapet/integrations/scoria.ex"
    - "lib/parapet/evidence.ex"
    - "test/parapet/integrations/scoria_test.exs"
decisions:
  - "Updated `resolve_action_item` in Parapet.Evidence to support keyword list filters to resolve items using `external_id` without knowing the internal DB primary key."
  - "Conditionally called `Scoria.Workflow.get_state/1` behind `Code.ensure_loaded?` to avoid tight coupling or missing module errors if Scoria isn't installed."
metrics:
  duration: 120
  tasks_completed: 2
  files_modified: 3
---

# Phase 4 Plan 04-02: Scoria AI Dual-Track Telemetry Summary

Implemented Scoria dual-track telemetry integration to support low-cardinality Prometheus metrics and durable Ecto `ActionItem` entries for Operator UI rendering.

## Key Changes

1. **Track 1 & 2 for Staleness & Expiration:** Handled `[:scoria, :workflow, :stale]` and `[:scoria, :workflow, :expired]`, emitting low-cardinality metrics while synchronously creating durable `ActionItem`s via `Parapet.Evidence.create_action_item/1`.
2. **Resumed Validation:** Intercepted `[:scoria, :workflow, :resumed]` to check external Scoria state. Validated the status locally instead of blindly closing action items to combat dropped telemetry, applying the "Telemetry for UX, Adapter for Truth" pattern.
3. **Keyword List Resolution:** Adapted `Parapet.Evidence.resolve_action_item/1` to process keyword criteria like `[external_id: id]` to bridge external string IDs with internal UUID management.

## Deviations from Plan

**1. [Rule 2 - Missing feature] Updated Evidence.resolve_action_item**
- **Found during:** Task 2
- **Issue:** Task requires closing `ActionItem`s using `workflow_id` from external systems. However, the existing `Evidence.resolve_action_item/1` API only accepted an internal database ID.
- **Fix:** Added overloaded `resolve_action_item/1` that accepts keyword criteria, using `update_all(where: ^criteria)`.
- **Files modified:** `lib/parapet/evidence.ex`
- **Commit:** 2dd8a75

## Threat Flags
None.

## Known Stubs
None.
