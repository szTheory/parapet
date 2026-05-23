---
phase: "01"
plan: "01"
subsystem: "telemetry"
tags: ["opentelemetry", "metrics", "tracing", "exemplars"]
dependencies:
  requires: []
  provides: ["trace_id_metadata"]
  affects: ["http_metrics", "oban_metrics"]
tech_stack:
  added: ["opentelemetry_api"]
  patterns: ["Safe Optional Dependency Check", "Metadata Extraction"]
key_files:
  created: []
  modified: ["mix.exs", "lib/parapet/plug/metrics.ex", "lib/parapet/metrics/oban.ex", "test/parapet/plug/metrics_test.exs"]
decisions:
  - "Wrapped OpenTelemetry calls in safe `Code.ensure_loaded?` and `rescue` blocks to prevent crashes when OTel is not present."
  - "Ensured `trace_id` is only appended to `metadata` and never `tags` to prevent cardinality explosion in Prometheus."
metrics:
  duration_minutes: 3
  tasks_completed: 3
  files_modified: 4
---

# Phase 01 Plan 01: Extract OpenTelemetry trace_id Summary

**One-liner:** Safely extract OpenTelemetry `trace_id` into Telemetry event metadata to support trace exemplars.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check

- [x] All tasks executed
- [x] Each task committed individually
- [x] Summary created

**Commits:**
- `48ac7bb`: feat(01-01): extract trace_id in Oban metrics
- `a29f5d6`: feat(01-01): extract trace_id in metrics plug
- `085f912`: test(01-01): add failing test for trace_id extraction
- `1243329`: chore(01-01): add opentelemetry_api optional dependency
