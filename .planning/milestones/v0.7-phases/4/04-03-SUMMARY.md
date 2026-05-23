---
phase: 4
plan: 04-03
subsystem: "integrations"
tags:
  - telemetry
  - rindle
  - async
  - backlog
dependency_graph:
  requires:
    - "04-01-SUMMARY.md"
  provides:
    - "Rindle translation onto normalized async families"
  affects:
    - "lib/parapet/integrations/rindle.ex"
    - "Phase 5 async metrics and SLO work"
tech_stack:
  added: []
  patterns:
    - "Grouped async telemetry attachment"
    - "Retryable versus discarded normalization"
key_files:
  created: []
  modified:
    - "lib/parapet/integrations/rindle.ex"
    - "test/parapet/integrations/rindle_test.exs"
requirements_completed:
  - TRIAGE-01
metrics:
  duration: 24
  tasks_completed: 1
  files_modified: 2
completed: 2026-05-17
---

# Phase 4 Plan 04-03: Async Adapter Contract Summary

Rindle now emits bounded Phase 4 async telemetry families that keep stage progress, backlog pressure, callback delay, retryable failure, and discarded work distinct for downstream consumers.

## Accomplishments

- Reworked `Parapet.Integrations.Rindle` to emit `[:parapet, :async, :stage]`, `:backlog`, and `:callback` through one grouped handler set.
- Normalized async outcomes onto the Phase 4 vocabulary so `:retryable_failed` remains distinct from `:discarded`, and callback delay does not collapse into backlog.
- Added focused tests covering stage progress, retryable failure, discard, backlog, callback delay, succeeded output, and exact-identifier ref scrubbing.

## Verification

- `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs`

## Decisions Made

- Used explicit event families for stage, backlog, and callback concerns instead of encoding all semantics into one generic async event.
- Preserved queue and stage metadata as bounded top-level fields while routing `job_id` and `webhook_id` into `refs`.
- Kept the adapter focused on the contract seam only rather than introducing any new durable evidence or recovery behavior.

## Deviations from Plan

None on scope. The final implementation stayed inside the adapter and focused test surface.

## Issues Encountered

- The delegated implementation stopped before verification and summary creation, so the final verification and wrap-up were completed in the main thread.
- The first pass dropped ref candidates before contract shaping, which removed `job_ref` and `webhook_ref` from the emitted metadata until the adapter preserved those inputs explicitly.

## Next Phase Readiness

Later async metrics, SLOs, and incident classification work can now rely on a stable async contract that already distinguishes retry noise, terminal discard, backlog pressure, and callback delay.
