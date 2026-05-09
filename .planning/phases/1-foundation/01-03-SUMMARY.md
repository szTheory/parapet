---
phase: "01"
plan: "03"
subsystem: "Telemetry Foundation"
tags: ["telemetry", "safety", "error-handling"]
dependencies:
  requires: ["01-01", "01-02"]
  provides: ["Parapet.attach/1", "Parapet.Internal.SafeHandler", "Parapet.Internal.LabelPolicy"]
  affects: ["telemetry integration surface"]
tech_stack:
  added: []
  patterns: ["try/rescue wrap", "telemetry attach", "argument validation"]
key_files:
  created: ["lib/parapet/internal/safe_handler.ex", "lib/parapet/internal/label_policy.ex"]
  modified: ["lib/parapet.ex", "test/parapet_test.exs"]
decisions:
  - "Implemented a hardcoded label policy regex to prevent high cardinality explosions rather than making it configurable, ensuring strict safety rails out of the box."
metrics:
  duration: 10m
  completed_date: 2026-05-09
---

# Phase 01 Plan 03: Implement Core Telemetry Safety Boundaries Summary

Implemented exception-safe handler wrappers and a label policy assertion library to prevent metric collection bugs from crashing the host process and avoid Prometheus cardinality explosions.

## Overview

- **Parapet.Internal.LabelPolicy**: A module that asserts safety rules for labels. It rejects labels ending in `id`, starting with `raw_`, or containing `token` or `path` to prevent cardinality explosion in metric series.
- **Parapet.Internal.SafeHandler**: Wraps the `:telemetry.attach` execution callback in a `try/rescue` block, ensuring that if user-defined telemetry handlers crash, the host process remains unaffected, and exceptions (along with their stacktraces) are logged.
- **Parapet**: Provided the top-level `Parapet.attach/1` macro-free API surface that uses `SafeHandler` to secure telemetry attachment.
- **Testing**: Added `test/parapet_test.exs` tests asserting the constraints and logic for the label policy and safe handler wrapper.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed broken generated tests**
- **Found during:** Task 2 validation
- **Issue:** `ParapetTest` still had the default `test "greets the world"` calling `Parapet.hello()`, which was removed in a previous plan.
- **Fix:** Rewrote `test/parapet_test.exs` to cover `Parapet.Internal.LabelPolicy.assert_safe!/1` and `Parapet.attach/1`.
- **Files modified:** `test/parapet_test.exs`
- **Commit:** 6f002d9 and b864ce6

## Threat Flags

None found. The surface implemented is strictly for telemetry internal wrapping within the host process memory limit and conforms to the mitigations outlined in the plan's threat register.

## Self-Check: PASSED

- `lib/parapet/internal/safe_handler.ex` exists
- `lib/parapet/internal/label_policy.ex` exists
- Commits `6f002d9` and `b864ce6` exist
