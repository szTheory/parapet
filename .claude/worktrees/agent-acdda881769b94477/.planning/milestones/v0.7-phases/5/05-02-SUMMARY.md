---
phase: 5
plan: 05-02
subsystem: "provider-catalogs"
tags:
  - mailglass
  - chimeway
  - rindle
  - provider-catalogs
dependency_graph:
  requires:
    - "05-01-SUMMARY.md"
  provides:
    - "Mailglass delivery provider catalog"
    - "Chimeway delivery provider catalog"
    - "Rindle async provider catalog"
  affects:
    - "lib/parapet/slo/mailglass_delivery.ex"
    - "lib/parapet/slo/chimeway_delivery.ex"
    - "lib/parapet/slo/rindle_async.ex"
    - "test/parapet/slo/mailglass_delivery_test.exs"
    - "test/parapet/slo/chimeway_delivery_test.exs"
    - "test/parapet/slo/rindle_async_test.exs"
    - "test/parapet/slo_test.exs"
tech_stack:
  added: []
  patterns:
    - "Explicit provider modules"
    - "Bounded slice catalogs"
    - "Fault-plane-aware alert metadata"
key_files:
  created:
    - "lib/parapet/slo/mailglass_delivery.ex"
    - "lib/parapet/slo/chimeway_delivery.ex"
    - "lib/parapet/slo/rindle_async.ex"
  modified:
    - "test/parapet/slo/mailglass_delivery_test.exs"
    - "test/parapet/slo/chimeway_delivery_test.exs"
    - "test/parapet/slo/rindle_async_test.exs"
    - "test/parapet/slo_test.exs"
requirements_completed:
  - DELV-02
  - DELV-03
  - ASYNC-01
  - ASYNC-02
  - ASYNC-03
metrics:
  duration: 39
  tasks_completed: 2
  files_modified: 7
completed: 2026-05-17
---

# Phase 5 Plan 05-02: Provider Catalog Summary

Mailglass, Chimeway, and Rindle now each expose explicit Phase 5 provider modules with a small, opinionated slice catalog over the shared async/delivery metric families.

## Accomplishments

- Added `Parapet.SLO.MailglassDelivery` with separate submit acceptance, confirmed delivery, webhook freshness, and suppression drift slices so provider acceptance never collapses into confirmed delivery.
- Added `Parapet.SLO.ChimewayDelivery` aligned to the currently proven Chimeway failure/callback surface, keeping provider-plane failure distinct from callback-plane confirmation and freshness.
- Added `Parapet.SLO.RindleAsync` with terminal success, queue freshness, callback freshness, long-running-stage, and funnel-regression slices that keep retry noise distinct from discarded work and backlog distinct from callback delay.
- Added focused tests proving the exact provider module names, the locked slice catalogs, and the fact that `Parapet.attach/1` still does not silently activate SLO providers.

## Verification

- `mix test test/parapet/slo/mailglass_delivery_test.exs test/parapet/slo/chimeway_delivery_test.exs test/parapet/slo/rindle_async_test.exs test/parapet/slo_test.exs`

## Decisions Made

- Kept the Chimeway catalog bounded to the proven repo surface instead of inventing richer acceptance telemetry that the adapter does not currently emit.
- Treated suppression drift and retry-heavy stages as downgraded diagnostic/warning slices rather than default paging SLOs.
- Preserved explicit `config :parapet, providers: [...]` activation as the only provider-registration seam.

## Deviations from Plan

- The Rindle diagnostic slices currently encode retry-heavy and funnel-regression behavior through bounded stage-outcome ratios rather than a separate long-running-duration DSL, keeping the provider API smaller for this phase.

## Issues Encountered

- None after the Wave 1 slice-spec seam stabilized; the provider modules compiled and verified against the focused tests without needing runtime adapter changes.

## Next Phase Readiness

Wave 3 can now render generated recording rules and alerts directly from the active provider catalog instead of from legacy environment-mutated SLO state.
