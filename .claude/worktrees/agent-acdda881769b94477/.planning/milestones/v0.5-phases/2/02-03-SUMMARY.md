---
phase: 2
plan: 03
subsystem: ui
tags:
  - operator-ui
  - critical-journeys
requires: ["02-01", "02-02"]
provides:
  - critical journeys visual component
affects:
  - priv/templates/parapet.gen.ui/operator_components.ex.eex
  - priv/templates/parapet.gen.ui/operator_live.ex.eex
tech-stack:
  added: []
  patterns:
    - dashboard composition
key-files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
decisions:
  - Surface Critical Journeys explicitly above the Incident Queue.
metrics:
  duration: 2m
  completed_date: 2026-05-14
---

# Phase 2 Plan 03: Critical Journeys UI Summary

Surface the "Critical Journeys" (Login, Signup, Checkout, Webhooks) explicitly in the Parapet Operator UI.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

- `priv/templates/parapet.gen.ui/operator_live.ex.eex`: Hardcoded `@journeys` mock data in `mount/3` for Login, Signup, Checkout, Webhooks. This is explicitly requested by the plan.

## Self-Check: PASSED
