---
phase: "03-slo-login-deploy"
plan: "04"
subsystem: "mix_tasks_docs"
tags: ["cli", "docs", "slo", "runbook"]
requires: ["03-01"]
provides: ["mix parapet.doctor", "docs/slo-reference.md"]
affects: ["lib/mix/tasks/parapet.doctor.ex", "test/mix/tasks/parapet.doctor_test.exs", "docs/slo-reference.md"]
tech-stack:
  added: []
  patterns: ["Mix Task", "Static Analysis", "System.halt"]
key-files:
  created:
    - "lib/mix/tasks/parapet.doctor.ex"
    - "test/mix/tasks/parapet.doctor_test.exs"
    - "docs/slo-reference.md"
  modified: []
key-decisions:
  - "The doctor task uses System.halt/1 to exit when errors are found to ensure pipelines reliably fail."
  - "The tests intercept System.halt to prevent the test suite from shutting down."
metrics:
  duration: 5
  completed_date: 2024-05-10
---

# Phase 3 Plan 04: Doctor Task and SLO Docs Summary

Implemented the `mix parapet.doctor` mix task to validate Parapet configurations and enforce runbook URLs.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED
- `lib/mix/tasks/parapet.doctor.ex` created
- `test/mix/tasks/parapet.doctor_test.exs` created
- `docs/slo-reference.md` created
- Commits recorded
