---
phase: "03-threadline-compliance"
plan: "01"
subsystem: "integrations"
tags: ["telemetry", "audit", "threadline"]
requires: []
provides: ["Parapet.Integrations.Threadline.handle_event/4"]
affects: ["lib/parapet/integrations/threadline.ex"]
tech-stack:
  added: []
  patterns: ["telemetry_handler"]
key-files:
  created: []
  modified:
    - "lib/parapet/integrations/threadline.ex"
decisions:
  - "Used `Code.ensure_loaded?(Threadline)` to check for Threadline dependency safely before routing."
  - "Adapted `to_threadline_shape` to support maps to accommodate telemetry payloads."
  - "Added telemetry event handler for `[:parapet, :audit, :created]` events."
metrics:
  duration: "4 mins"
  completed-date: "2026-05-24"
---

# Phase 03 Plan 01: Threadline audit telemetry handler Summary

Implement telemetry event handling in `Parapet.Integrations.Threadline` to sync audit records to Threadline without a hard dependency.

## Key Changes

- Implemented `Parapet.Integrations.Threadline.handle_event/4` and attached it to `[:parapet, :audit, :created]`.
- Mapped metadata payload seamlessly utilizing `to_threadline_shape/1` adjusted to process Maps.
- Maintained crash safety by wrapping telemetry processes in a `rescue` block, ensuring Parapet's integrity even if Threadline operations fail.

## Deviations from Plan

None - plan executed exactly as written. (Logged a pre-existing unrelated compiler warning to deferred-items.md).

## Threat Flags

None found. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

## Self-Check: PASSED