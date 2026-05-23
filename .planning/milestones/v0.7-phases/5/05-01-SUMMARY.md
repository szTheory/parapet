---
phase: 5
plan: 05-01
subsystem: "metrics-and-slo-foundation"
tags:
  - metrics
  - async-delivery
  - slice-spec
  - provider-seam
dependency_graph:
  requires:
    - "04-01-SUMMARY.md"
    - "04-02-SUMMARY.md"
    - "04-03-SUMMARY.md"
  provides:
    - "Shared async/delivery metric catalog for Phase 5"
    - "Bounded provider-owned slice spec"
    - "Compatibility resolution from slice specs into legacy SLO structs"
  affects:
    - "lib/parapet/metrics/async_delivery.ex"
    - "lib/parapet/slo/slice_spec.ex"
    - "lib/parapet/slo/resolvable.ex"
    - "lib/parapet/slo.ex"
tech_stack:
  added: []
  patterns:
    - "Shared metric families over normalized telemetry"
    - "Bounded provider slice spec"
    - "Legacy compatibility seam"
key_files:
  created:
    - "lib/parapet/metrics/async_delivery.ex"
    - "lib/parapet/slo/slice_spec.ex"
  modified:
    - "lib/parapet/slo/resolvable.ex"
    - "lib/parapet/slo.ex"
    - "test/parapet/metrics/async_delivery_test.exs"
    - "test/parapet/metrics/mailglass_test.exs"
    - "test/parapet/metrics/chimeway_test.exs"
    - "test/parapet/metrics/rindle_test.exs"
    - "test/parapet/slo/resolvable_test.exs"
requirements_completed:
  - DELV-02
  - DELV-03
  - ASYNC-01
metrics:
  duration: 44
  tasks_completed: 2
  files_modified: 11
completed: 2026-05-17
---

# Phase 5 Plan 05-01: Shared Metrics And Slice Spec Summary

Phase 5 now has one shared async and delivery metric catalog plus a bounded provider-owned slice-spec seam, so later provider modules and generators can build on normalized telemetry instead of embedding raw ad hoc PromQL everywhere.

## Accomplishments

- Added `Parapet.Metrics.AsyncDelivery` with shared `_total` and `_seconds` metric families for all six Phase 4 event families, plus deterministic selector helpers for provider-owned slices.
- Added `Parapet.SLO.SliceSpec` as the bounded data model for provider catalogs, including alert class, grouping labels, matcher fields, and diagnostic-vs-budgeted validation rules.
- Extended `Parapet.SLO.Resolvable` and `Parapet.SLO` so provider slice specs can coexist with legacy `%Parapet.SLO{}` callers while Phase 5 shifts the blessed path toward explicit providers.

## Verification

- `mix test test/parapet/metrics/async_delivery_test.exs test/parapet/metrics/mailglass_test.exs test/parapet/metrics/chimeway_test.exs test/parapet/metrics/rindle_test.exs test/parapet/slo/resolvable_test.exs`

## Decisions Made

- Kept one coherent shared metric namespace instead of per-provider metric families.
- Modeled diagnostic slices in the same bounded struct as budgeted slices so the generator can downgrade severity without a second provider API.
- Preserved the existing legacy SLO seam rather than forcing an immediate cutover.

## Deviations from Plan

- The generator-facing selector helper landed in the shared metrics module rather than in a separate query-builder module because the metric-name and matcher contract need to stay coupled.

## Issues Encountered

- The local `gsd-sdk` binary in this workspace does not expose the `query` subcommands assumed by the workflow, so execution tracking and summaries were written manually after inline execution.

## Next Phase Readiness

Wave 2 provider catalogs can now declare bounded slices against one shared metric surface, and Wave 3 can render host-owned Prometheus artifacts from those slice specs.
