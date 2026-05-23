---
phase: 4
plan: 04-04
subsystem: "docs"
tags:
  - telemetry
  - docs
  - public-api
  - compile-out
dependency_graph:
  requires:
    - "04-01-SUMMARY.md"
    - "04-02-SUMMARY.md"
    - "04-03-SUMMARY.md"
  provides:
    - "Documented Phase 4 public telemetry contract"
    - "Public API proof for AsyncDelivery module"
    - "Activation and compile-out verification for optional integrations"
  affects:
    - "docs/telemetry.md"
    - "README.md"
    - "test/mix/tasks/verify.public_api_test.exs"
    - "test/parapet_test.exs"
tech_stack:
  added: []
  patterns:
    - "Public contract documentation"
    - "Compile-out proof by warnings-as-errors"
key_files:
  created:
    - "docs/telemetry.md"
  modified:
    - "README.md"
    - "lib/parapet/metrics/prometheus_formatter.ex"
    - "test/parapet_test.exs"
    - "test/mix/tasks/verify.public_api_test.exs"
requirements_completed:
  - DELV-01
  - TRIAGE-01
metrics:
  duration: 22
  tasks_completed: 3
  files_modified: 5
completed: 2026-05-17
---

# Phase 4 Plan 04-04: Contract Documentation And Proof Summary

The Phase 4 async and delivery namespace is now documented as public API, covered by the public API manifest, and backed by explicit activation and compile-out verification for the optional integrations in scope.

## Accomplishments

- Replaced `docs/telemetry.md` with a Phase 4 contract reference that documents the six event families, safe metadata rules, `refs` semantics, and the key outcome/fault-plane distinctions.
- Updated `README.md` with the blessed activation path for `Mailglass`, `Chimeway`, and `Rindle` through `Parapet.attach(adapters: [...])`.
- Extended proof coverage so `Parapet.Telemetry.AsyncDelivery` is asserted in the public API manifest and explicit adapter activation is tested directly in `test/parapet_test.exs`.
- Removed the existing optional dependency compile warning from `Parapet.Metrics.PrometheusFormatter`, making `mix compile --warnings-as-errors` a usable compile-out gate again.

## Verification

- `mix test test/parapet_test.exs test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs test/mix/tasks/verify.public_api_test.exs`
- `mix run -e 'Mix.Task.run("verify.public_api")'`
- `mix compile --warnings-as-errors`

## Decisions Made

- Kept the README concise and pointed detailed contract semantics to `docs/telemetry.md` instead of turning the top-level README into a reference manual.
- Treated `Parapet.Telemetry.AsyncDelivery` as a public module that must participate in the repo's documentation proof surface.
- Used repeated adapter activation in tests as the proof that explicit host-owned setup remains safe after the Phase 4 handler changes.

## Deviations from Plan

- Expanded the implementation slightly into `lib/parapet/metrics/prometheus_formatter.ex` because the existing optional dependency callsite prevented the required `mix compile --warnings-as-errors` verification from succeeding. This was a verification-enabling fix, not a scope expansion into new product behavior.

## Issues Encountered

- `mix compile --warnings-as-errors` initially failed on an existing warning from the optional `:telemetry_metrics_prometheus_core` dependency. Switching the formatter to `apply/3` behind `Code.ensure_loaded?/1` restored compile-out safety without tightening runtime coupling.

## Next Phase Readiness

Phase 4 now leaves later SLO, incident, and runbook phases a documented and verified public telemetry contract rather than an implicit adapter implementation detail.
