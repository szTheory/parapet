---
phase: "02"
plan: "02"
subsystem: "Scoria Integrations"
tags: ["AI", "Telemetry", "Metrics", "SLO", "Prometheus"]
dependency_graph:
  requires:
    - 02-01-PLAN.md
  provides:
    - Scoria Metrics Pipeline
    - ScoriaEval SLO Struct
  affects:
    - lib/parapet/integrations/scoria.ex
tech_stack:
  added: ["Telemetry.Metrics", "PromQL"]
  patterns: ["Scoria Telemetry Metrics", "SLO Resolvable Structs"]
key_files:
  created:
    - lib/parapet/metrics/scoria.ex
    - test/parapet/metrics/scoria_test.exs
    - lib/parapet/slo/scoria_eval.ex
    - test/parapet/slo/scoria_eval_test.exs
  modified:
    - lib/parapet/integrations/scoria.ex
key_decisions:
  - "Used Map.take/2 to strictly enforce cardinality of Scoria telemetry events, only retaining `guardrail`, `passed`, and `model_name` for Prometheus metrics to prevent TSDB bloat."
metrics:
  duration: "5m"
  completed_date: "2026-05-13"
---

# Phase 2 Plan 02: Scoria Eval-Driven SLOs Summary

Implemented Scoria-specific SLO definition struct (`Parapet.SLO.ScoriaEval`) and the telemetry-to-metrics pipeline (`Parapet.Metrics.Scoria`) to safely emit and track AI evaluation pass rates.

## Tasks Completed

1. **Implement Scoria Metrics Pipeline:** Created `Parapet.Metrics.Scoria` to translate Scoria AI evaluation telemetry to safe, low-cardinality `scoria_evaluation_total` Prometheus metrics.
2. **Implement ScoriaEval SLO Struct:** Created `Parapet.SLO.ScoriaEval` with validation logic, and implemented the `Parapet.SLO.Resolvable` protocol to map the structs to accurate `scoria_evaluation_total` PromQL events.
3. **Wire Scoria Metrics in Integration Setup:** Updated `Parapet.Integrations.Scoria.setup/0` to initialize both SRE error telemetry and the new Scoria evaluation metrics.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None found.

## TDD Gate Compliance

Both TDD tasks followed RED/GREEN commits:
- `test(02-02): add failing test for Scoria metrics pipeline`
- `feat(02-02): implement Scoria metrics pipeline`
- `test(02-02): add failing test for ScoriaEval SLO Struct`
- `feat(02-02): implement ScoriaEval SLO Struct`

## Self-Check: PASSED
- `lib/parapet/metrics/scoria.ex` (FOUND)
- `test/parapet/metrics/scoria_test.exs` (FOUND)
- `lib/parapet/slo/scoria_eval.ex` (FOUND)
- `test/parapet/slo/scoria_eval_test.exs` (FOUND)
