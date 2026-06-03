---
phase: 2
plan: "03"
subsystem: operator-ui
tags:
  - liveview
  - security
  - docs
  - doctor
dependencies:
  requires:
    - "02-02"
  provides:
    - operator ui security verification
    - operator ui documentation
  affects:
    - parapet.doctor
    - README.md
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - docs/operator-ui.md
  modified:
    - lib/mix/tasks/parapet.doctor.ex
    - test/mix/tasks/parapet.doctor_test.exs
    - README.md
key-decisions:
  - Keep operator UI static analysis separate from generic router checks in doctor to ensure distinct findings.
  - Rely on host app's router.ex AST to verify secure routing scopes for the generated operator LiveViews.
metrics:
  duration-minutes: 15
  completed-date: 2026-05-11
---

# Phase 2 Plan 03: Add Operator UI security verification and documentation

Adds static analysis for secure LiveView routes to `mix parapet.doctor` and publishes the end-to-end Operator UI guide.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None

## Threat Flags

None
