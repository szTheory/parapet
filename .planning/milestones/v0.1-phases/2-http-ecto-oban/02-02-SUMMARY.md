# Phase 2 Plan 2: Ecto and Oban Metrics Summary

---
phase: 02-http-ecto-oban
plan: 02
subsystem: metrics
tags: [ecto, oban, telemetry, metrics]
requires: ["02-01"]
provides: [Parapet.Metrics.Ecto, Parapet.Metrics.Oban]
affects: [telemetry_pipeline]
tech-stack: [Telemetry, Telemetry.Metrics, ExUnit]
key-files:
  - lib/parapet/metrics/ecto.ex
  - lib/parapet/metrics/oban.ex
  - test/parapet/metrics/ecto_test.exs
  - test/parapet/metrics/oban_test.exs
decisions:
  - Ecto timing converts native duration metrics to milliseconds for proper bucketing.
  - Oban explicitly tracks and aliases `worker`, `queue`, and `state` on both counter and distribution to support `rate()`-based metric reporting correctly.
  - Added Oban module conditionally mapped against `Code.ensure_loaded?(Oban)` enabling optional library deployment.
metrics:
  duration: 3m
  tasks-completed: 3/3
---

## Summary
Added exception-safe Ecto database metrics and conditionally loaded Oban worker metrics to provide granular monitoring of job status (`worker`, `queue`, `state`) and latency measurements without crashing the host Node.

## Key Outcomes
- Both Ecto and Oban modules register metrics within an isolated `try/rescue ArgumentError` block.
- Both components emit standardized runtime labels filtered through `Parapet.Internal.LabelPolicy.assert_safe!/1` validations.

## Deviations from Plan
None - plan executed exactly as written.

## Threat Flags
None.

## Known Stubs
None.

## Self-Check: PASSED
- FOUND: lib/parapet/metrics/ecto.ex
- FOUND: lib/parapet/metrics/oban.ex
- FOUND: test/parapet/metrics/ecto_test.exs
- FOUND: test/parapet/metrics/oban_test.exs
