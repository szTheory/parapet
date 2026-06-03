---
phase: 3
plan: 01
subsystem: "SLO"
tags: ["dsl", "prometheus", "generator"]
dependency_graph:
  requires: []
  provides: ["Parapet.SLO", "Parapet.SLO.Generator"]
  affects: ["PromQL generation"]
tech_stack:
  added: []
  patterns: ["Embedded EEx YAML generation", "Multi-window burn-rate PromQL"]
key_files:
  created: 
    - "lib/parapet/slo.ex"
    - "lib/parapet/slo/generator.ex"
    - "test/parapet/slo_test.exs"
  modified: []
decisions:
  - "Use EEx templates for Prometheus YAML generation to avoid string concatenation and YAML indentation issues."
  - "Require strict presence of runbook URL in SLO definitions."
  - "Generate multi-window burn rates strictly as `sum(rate(good[w])) / sum(rate(total[w]))` to avoid reset bugs."
  - "Refactored test to accept PromQL selectors to facilitate `[w]` window injection by the generator."
metrics:
  duration: 15m
  completed_date: "2026-05-10"
---

# Phase 3 Plan 01: SLO DSL and PromQL Generator Summary

Implemented the core Service-Level Objective (SLO) definition module and the generator that converts these definitions into correct Prometheus multi-window burn-rate YAML rules.

## Deviations from Plan

**1. [Rule 4 - Changed test DSL input format for correct generation]**
- **Found during:** Task 2 (Generator)
- **Issue:** The original test passed a full `sum(rate(metric[5m]))` expression, which made it impossible for the generator to inject multiple different rolling windows (e.g., `5m`, `30m`).
- **Fix:** Changed the test and DSL expectation so users provide the selector (e.g., `http_requests_total{status=~"5.."}`), allowing the generator to wrap it correctly in `sum(rate(...[w]))` for each multi-window burn-rate window.
- **Files modified:** `test/parapet/slo_test.exs`
- **Commit:** 47892e4

## Threat Flags

None discovered outside the original threat model (T-03-01 mitigated via newline sanitization in `Parapet.SLO.Generator`).
## Self-Check: PASSED
