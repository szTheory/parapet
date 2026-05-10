---
phase: "3-slo-login-deploy"
plan: "02"
subsystem: "Integrations/SLO"
tags:
  - "sigra"
  - "slo"
  - "login-journey"
  - "generator"
dependency_graph:
  requires: ["03-01"]
  provides: ["Parapet.Integrations.Sigra", "Parapet.SLO.LoginJourney"]
  affects: ["mix parapet.install"]
tech_stack:
  added: []
  patterns:
    - "Safe Telemetry Handlers"
    - "Optional Compilation Pattern"
key_files:
  created:
    - "lib/parapet/integrations/sigra.ex"
    - "test/parapet/integrations/sigra_test.exs"
    - "lib/parapet/slo/login_journey.ex"
  modified:
    - "lib/mix/tasks/parapet.install.ex"
key_decisions:
  - "LoginJourney SLO defaults to standard prometheus _count suffix for distribution metrics."
  - "PII is strictly omitted from the Sigra integration outcome payload."
metrics:
  duration_minutes: 15
  completed_date: "2026-05-10"
---

# Phase 3 Plan 02: Login Journey and Sigra Integration Summary

Implemented optional Sigra integration, established the LoginJourney SLO definition, and added generator support for the `--with-sigra` flag.

## Key Changes

1. **Parapet.Integrations.Sigra**: Added an optional integration that hooks into `[:sigra, :auth, :login, :stop]` and `[:sigra, :auth, :login, :exception]` telemetry events, translating them to standard `[:parapet, :journey, :login]` events with a stripped metadata payload avoiding PII.
2. **Parapet.SLO.LoginJourney**: Implemented an out-of-the-box SLO mapping to the `parapet_journey_login_duration_milliseconds_count` Prometheus metric.
3. **Parapet Install Task**: Updated `mix parapet.install` with a `--with-sigra` flag. When true, the generator appends `Parapet.Integrations.Sigra.setup()` to the host application's instrumentation setup function.

## Deviations from Plan

None - plan executed exactly as written.

## Threat Flags

None found.

## Known Stubs

None found.

## Self-Check: PASSED
- All tracked files exist and tests pass.
