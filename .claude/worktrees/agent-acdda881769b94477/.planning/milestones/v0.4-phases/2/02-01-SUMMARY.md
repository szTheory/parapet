---
phase: "02"
plan: "01"
subsystem: "SLO"
tags:
  - refactor
  - providers
  - prometheus
dependency_graph:
  requires:
    - none
  provides:
    - Parapet.SLO.Provider
    - Parapet.SLO.Resolvable
  affects:
    - Mix.Tasks.Parapet.Gen.Prometheus
tech_stack:
  added:
    - Behaviour
    - Protocol
  patterns:
    - Data-first registry
key_files:
  created:
    - lib/parapet/slo/provider.ex
    - lib/parapet/slo/resolvable.ex
    - test/parapet/slo/resolvable_test.exs
  modified:
    - lib/parapet/slo.ex
    - lib/mix/tasks/parapet.gen.prometheus.ex
    - test/parapet/slo_test.exs
metrics:
  duration: 5
  completed_date: "2026-05-13"
---

# Phase 02 Plan 01: Data-First SLO Providers Summary

Migrated the Parapet SLO architecture to a declarative `Provider` behaviour, eliminating reliance on runtime mutation for SLO registration.

## Key Changes
- Created `Parapet.SLO.Provider` behaviour with `slos/0` callback.
- Created `Parapet.SLO.Resolvable` protocol to map custom provider structs to canonical `Parapet.SLO.t()`.
- Refactored `Parapet.SLO.all/0` to dynamically merge configured providers with legacy environment variables.
- Removed hardcoded registration calls from `mix parapet.gen.prometheus` task, making it reliant strictly on the updated registry.
- Deprecated `Parapet.SLO.define/2`.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## Self-Check: PASSED
FOUND: lib/parapet/slo/provider.ex
FOUND: lib/parapet/slo/resolvable.ex
FOUND: aabe465
FOUND: a1f8e45
FOUND: 3fd42de