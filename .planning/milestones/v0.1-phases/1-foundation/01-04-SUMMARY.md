---
phase: "01"
plan: "04"
subsystem: "Install Generator"
tags: ["igniter", "generator", "dx"]
dependencies:
  requires: ["01-01", "01-03"]
  provides: ["Mix.Tasks.Parapet.Install"]
  affects: ["host app configuration", "host app endpoint"]
tech_stack:
  added: ["Igniter"]
  patterns: ["AST patching", "idempotent generation"]
key_files:
  created: ["lib/mix/tasks/parapet.install.ex"]
  modified: []
decisions:
  - "Used `Sourceror.to_string(zipper.node) =~ \"Parapet.Plug.Metrics\"` instead of verbose Igniter context-aware function matching to determine if the Endpoint was already patched, prioritizing simplicity and speed in the generator."
metrics:
  duration: 15m
  completed_date: 2026-05-09
---

# Phase 01 Plan 04: Build `mix parapet.install` Igniter-based code generator Summary

Implemented the `mix parapet.install` Igniter task to provide a frictionless, idempotent setup experience that places host-owned instrumentation hooks into the user's application cleanly.

## Overview

- **Mix.Tasks.Parapet.Install**: An Igniter-powered Mix task that orchestrates code generation and config modification.
- **Idempotency**: The task uses Igniter's native AST patching capabilities to ensure repeated invocations are safe and `dry-run` operations accurately reflect pending changes.
- **Host App Scaffolding**: It generates `MyApp.ParapetInstrumenter` in the host application's `lib` directory so developers can own and extend the telemetry callbacks.
- **Endpoint Patching**: The installer modifies the host application's Phoenix Endpoint to inject `plug Parapet.Plug.Metrics` securely.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing `Igniter.Code.Common.within?` function**
- **Found during:** Task 1
- **Issue:** Attempted to use a non-existent or private function `within?/2` in the zipper traversal.
- **Fix:** Switched to stringizing the AST node via `Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"` to check for existing plugs, which successfully compiled and performs the same safety check.
- **Files modified:** `lib/mix/tasks/parapet.install.ex`
- **Commit:** 9bf7c10

## Threat Flags

None found.

## Self-Check: PASSED

- `lib/mix/tasks/parapet.install.ex` exists
- Commit `9bf7c10` exists
