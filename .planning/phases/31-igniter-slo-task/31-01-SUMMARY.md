---
phase: 31-igniter-slo-task
plan: 01
subsystem: mix_tasks
tags:
  - igniter
  - generator
  - slo
  - tdd
dependency_graph:
  requires: []
  provides:
    - parapet.gen.slo generator
  affects:
    - config/config.exs (for adopter applications using the task)
tech_stack:
  added: []
  patterns:
    - Igniter.Mix.Task
    - TDD
key_files:
  created:
    - lib/mix/tasks/parapet.gen.slo.ex
    - test/mix/tasks/parapet.gen.slo_test.exs
  modified: []
metrics:
  duration: 4
  completed_date: 2026-06-03
requirements-completed: [DX-01]
---

# Phase 31 Plan 01: Igniter SLO Task Summary

Implemented a flag-based generator `mix parapet.gen.slo` for Parapet SLO providers.

## Key Decisions

- **Float parsing:** Used `Igniter.Mix.Task.Info` schema (`:float`) to automatically parse `--objective` and `--threshold` flags, ensuring type safety.
- **Config appending:** Replicated the configuration list string-evaluation logic from `Parapet.Install` to append the generated module to `config :parapet, providers: [...]`.
- **Metrics insertion:** Dynamically included `good_source_metric` and `total_source_metric` strings only if they are passed as flags, replacing missing lines cleanly to format the AST well without Sourceror.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.

## TDD Gate Compliance

- `test(31-igniter-slo-task-01): add failing test for parapet.gen.slo generator` (RED gate) exists.
- `feat(31-igniter-slo-task-01): implement parapet.gen.slo generator` (GREEN gate) exists.

## Self-Check: PASSED

- `lib/mix/tasks/parapet.gen.slo.ex` found.
- `test/mix/tasks/parapet.gen.slo_test.exs` found.
- Commit 79bb532 and aa7db8d verified.
