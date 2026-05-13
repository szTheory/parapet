---
phase: "01"
plan: "02"
subsystem: "Scoria Telemetry"
tags: ["ai", "telemetry", "generator", "igniter"]
requires: ["01-01"]
provides: ["parapet.gen.scoria"]
affects: ["mix parapet.install"]
tech-stack:
  added: []
  patterns: ["Igniter.Mix.Task", "EEx.eval_file", "Igniter.compose_task"]
key-files:
  created:
    - lib/mix/tasks/parapet.gen.scoria.ex
    - test/mix/tasks/parapet.gen.scoria_test.exs
    - priv/templates/parapet.gen.scoria/scoria_dashboard.json.eex
    - priv/templates/parapet.gen.scoria/rules.yml.eex
  modified:
    - lib/mix/tasks/parapet.install.ex
key-decisions:
  - "Updated Igniter implementation to use modern arity 1 `igniter/1` callbacks for tasks"
metrics:
  duration: 10m
  completed_at: 2026-05-12T00:00:00Z
---

# Phase 01 Plan 02: Scoria Generator and Installer Summary

Creates the `mix parapet.gen.scoria` generator to scaffold Grafana dashboards and Prometheus rules, and wires it into the main Parapet installer.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed deprecated Igniter.Mix.Task callback arity**
- **Found during:** Task 1
- **Issue:** The test was trying to use `Scoria.igniter(igniter)` but the implemented code used `def igniter(igniter, _argv)` which failed since `igniter/2` is deprecated.
- **Fix:** Refactored `igniter/2` to `igniter/1` in the generator module.
- **Files modified:** `lib/mix/tasks/parapet.gen.scoria.ex`
- **Commit:** 256d1cb

## Known Stubs

| File | Location | Reason |
|------|----------|--------|
| `priv/templates/parapet.gen.scoria/scoria_dashboard.json.eex` | Line 1 | Contains empty `{}` as instructed by the plan. A real Grafana dashboard JSON will be populated in a future plan. |

## Self-Check: PASSED
