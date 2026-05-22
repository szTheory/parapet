# Phase 01: Cardinality Protection - Execution Summary

**Date:** 2026-05-19
**Phase:** 01-cardinality-protection
**Wave:** 1
**Plan:** 01

## Objective
Proactively prevent observability's most common failure mode (TSDB Cardinality Protection) by enforcing limits at compile-time for metrics and providing static analysis tooling for dynamic configurations.

## Tasks Completed

### Task 1: Compile-Time Metrics Validator
- Created `Parapet.Metrics.Validator` macro that enforces a maximum of 10 labels per metric at compile-time.
- Integrated `Parapet.Internal.LabelPolicy.assert_safe!` to reject known high-cardinality label patterns (e.g., labels ending in `_id`, `token`, `path`).
- Tests written in `test/parapet/metrics/validator_test.exs` using dynamic module compilation.

### Task 2: Enforce limits on built-in metrics
- Added `use Parapet.Metrics.Validator` to all built-in metrics definitions (`accrue.ex`, `async_delivery.ex`, `ecto.ex`, `http.ex`, `oban.ex`, `probe.ex`, `rulestead.ex`, `scoria.ex`, `sigra.ex`).
- Modified `lib/parapet/metrics/rulestead.ex` to use `ruleset` instead of `ruleset_id` as a tag, to pass the label policy. Also updated the telemetry emission from `lib/parapet/integrations/rulestead.ex` and related tests to match.

### Task 3: Doctor Cardinality Check
- Extended `Mix.Tasks.Parapet.Doctor` to run static analysis on PromQL queries used in SLOs.
- `mix parapet.doctor cardinality` parses `good_events` and `total_events` PromQL expressions, extracts labels from `by (...)` and `{...}` blocks, and applies `Parapet.Internal.LabelPolicy.assert_safe!`.
- Validated via `test/mix/tasks/parapet.doctor_test.exs`.

## Threat Mitigation
- **T-01-01**: Mitigated via `@after_compile` hooks preventing unbounded labels.
- **T-01-02**: Mitigated via `parapet.doctor cardinality` static checks.

## Verification
- `mix compile --force --warnings-as-errors` passes.
- `mix test` passes.
- `mix parapet.doctor cardinality` exists and can be run directly, but in the current workspace it may return `skip` when no SLOs are configured. Closure proof for the doctor surface therefore comes from the targeted doctor tests rather than that live invocation alone.
