---
phase: "03-threadline-compliance"
plan: "02"
subsystem: "Evidence"
tags: ["compliance", "audit", "telemetry", "ecto"]
requires: ["03-01"]
provides: ["Configured transaction logic in run_operator_command/1"]
affects: ["lib/parapet/evidence.ex"]
tech-stack:
  added: []
  patterns: ["Configuration-driven injection", "Ecto.Multi", "Telemetry dispatch"]
key-files:
  created: []
  modified:
    - "lib/parapet/evidence.ex"
metrics:
  duration_minutes: 2
  completed_date: "2024-05-18"
---

# Phase 03 Plan 02: Evidence API Conditional Audit Mode Summary

Evidence API was successfully updated to support `audit_mode` configuration, enabling compliance parity by either dual-writing or deferring audit storage via telemetry events.

## Key Changes
- Modified `Parapet.Evidence.run_operator_command/1` to read `audit_mode` from application config. It dynamically skips `ToolAudit` inserts and broadcasts telemetry when deferred, while maintaining traditional Ecto insertions alongside telemetry broadcasts when dual-writing.
- Modified `Parapet.Evidence.log_tool_audit/1` in exactly the same manner, returning either the inserted struct or `:deferred` after issuing a telemetry event.
- Leveraged `Ecto.Multi.run` to emit telemetry seamlessly as part of transaction boundaries.

## Deviations from Plan
None - plan executed exactly as written. (Note: A pre-existing compilation warning in `lib/parapet/metrics/prometheus_formatter.ex` was observed but ignored as out-of-scope).

## Self-Check: PASSED
- [x] FOUND: lib/parapet/evidence.ex
- [x] FOUND: 2550ffc

## Commits
- 2550ffc: feat(03-02): update Evidence API to support audit_mode conditional and telemetry dispatch