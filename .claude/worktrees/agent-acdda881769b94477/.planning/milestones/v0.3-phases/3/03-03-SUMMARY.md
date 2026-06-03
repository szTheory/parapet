---
phase: 03-notifications
plan: 03
subsystem: Notifications
tags: [teams, notifications, adapter, adaptive-cards]
dependency_graph:
  requires: ["03-01"]
  provides: ["Parapet.Notifier.Teams"]
  affects: ["Parapet.Notifier"]
tech_stack:
  added: []
  patterns: ["adapter", "webhook"]
key_files:
  created:
    - lib/parapet/notifier/teams.ex
    - test/parapet/notifier/teams_test.exs
  modified: []
decisions:
  - Used `Req` to send MS Teams webhooks, adhering to `Parapet.Notifier` behaviour.
  - Formatted MS Teams messages using Adaptive Cards JSON schema.
metrics:
  duration_minutes: 5
  completed_date: "2026-05-12"
---

# Phase 03 Plan 03: MS Teams Adapter Summary

MS Teams adapter implemented with rich Adaptive Cards formatting and Operator UI deep links.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED
FOUND: lib/parapet/notifier/teams.ex
FOUND: test/parapet/notifier/teams_test.exs
FOUND: d8e7b9d
FOUND: 720b03c
