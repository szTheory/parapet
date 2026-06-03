---
phase: 02-rulestead-flag-correlation
plan: 01
subsystem: spine
tags:
  - ecto
  - genserver
  - telemetry
  - rulestead
dependency_graph:
  requires: []
  provides:
    - parapet_system_events_table
    - Parapet.Spine.SystemEvent
    - Parapet.Spine.SystemEventPruner
    - Parapet.Integrations.Rulestead
  affects:
    - lib/mix/tasks/parapet.gen.spine.ex
tech_stack:
  added: []
  patterns:
    - Ecto schemas for system events
    - GenServer for periodic garbage collection
    - Telemetry handlers with defensive error rescuing
key_files:
  created:
    - lib/parapet/spine/system_event.ex
    - lib/parapet/spine/system_event_pruner.ex
    - lib/parapet/integrations/rulestead.ex
    - test/parapet/integrations/rulestead_test.exs
    - priv/repo/migrations/20260517000000_add_parapet_system_events.exs
  modified:
    - lib/mix/tasks/parapet.gen.spine.ex
decisions:
  - "Used Application.get_env(:parapet, :repo) instead of Evidence.repo() in telemetry adapters and the pruner to avoid raising when not configured."
  - "Converted all atom keys to strings in telemetry metadata payloads before saving to SystemEvent.payload to ensure standard JSON representations in the DB."
metrics:
  duration: 10m
  completed_date: 2026-05-24
---

# Phase 02 Plan 01: Core SystemEvent subsystem and Rulestead adapter Summary

Implemented the foundational generic `SystemEvent` schema and its accompanying GC Pruner, alongside a telemetry adapter to capture Rulestead feature flag changes natively without deep Ecto coupling.

## Overview

1. Created `Parapet.Spine.SystemEvent` schema and migration.
2. Added `Parapet.Spine.SystemEventPruner` GenServer for pure OTP-based garbage collection of stale system events (older than 7 days).
3. Developed `Parapet.Integrations.Rulestead` in TDD fashion to listen to `[:rulestead, :admin, :ruleset, :published]` events and persist them safely as system events.

## Deviations from Plan

None - plan executed exactly as written, following TDD.

## Threat Flags

None - `SystemEventPruner` operates purely based on `inserted_at` index, mitigating storage bloat, and `Rulestead` handles payload serialization securely.

## Self-Check: PASSED

All tests pass and the database migrations have been structured correctly.
