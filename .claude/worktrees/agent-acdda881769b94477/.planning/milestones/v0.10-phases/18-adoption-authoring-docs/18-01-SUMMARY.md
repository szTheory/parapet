---
phase: 18-adoption-authoring-docs
plan: "01"
subsystem: integration-activation
tags: [behaviour, elixir, telemetry, rulestead, crash-fix]
dependency_graph:
  requires: []
  provides: [Parapet.Integration behaviour, uniform Parapet.attach/1 activation]
  affects: [lib/parapet/integration.ex, lib/parapet/integrations/*.ex, lib/parapet.ex, CHANGELOG.md]
tech_stack:
  added: [Parapet.Integration behaviour]
  patterns: [Elixir @behaviour/@callback/@impl idiom]
key_files:
  created:
    - lib/parapet/integration.ex
    - test/parapet/integrations/integration_behaviour_test.exs
  modified:
    - lib/parapet/integrations/sigra.ex
    - lib/parapet/integrations/accrue.ex
    - lib/parapet/integrations/threadline.ex
    - lib/parapet/integrations/chimeway.ex
    - lib/parapet/integrations/mailglass.ex
    - lib/parapet/integrations/rindle.ex
    - lib/parapet/integrations/scoria.ex
    - lib/parapet/integrations/rulestead.ex
    - lib/parapet.ex
    - test/parapet/integrations/rulestead_test.exs
    - CHANGELOG.md
decisions:
  - "Add Code.ensure_loaded! before function_exported? in conformance test — integration modules are lazy-loaded by the BEAM and function_exported? returns false until the module is loaded"
  - "setup/0 added to Rulestead in Task 1 commit rather than Task 2 — required for mix compile --warnings-as-errors to pass as part of the behaviour declaration task"
metrics:
  duration: "12 minutes"
  completed: "2026-05-24"
  tasks_completed: 3
  files_changed: 11
---

# Phase 18 Plan 01: Parapet.Integration Behaviour and Rulestead Activation Fix Summary

Introduced the `Parapet.Integration` behaviour (`@callback setup() :: any()`) and declared it across all eight integration adapters, turning a missing `setup/0` into a compile-time warning. Added a `setup/0` delegate to Rulestead (the sole outlier that only exposed `attach/0`), fixing the live `UndefinedFunctionError` crash in `Parapet.attach(adapters: [:rulestead])`.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Define Parapet.Integration behaviour and declare on all eight adapters | 734d820 | lib/parapet/integration.ex, all eight integrations/*.ex, test/parapet/integrations/integration_behaviour_test.exs |
| 2 | Fix Parapet.attach/1 @doc and add Rulestead uniform-line test | 1ef08d4 | lib/parapet.ex, test/parapet/integrations/rulestead_test.exs |
| 3 | Add CHANGELOG 0.10.0 entry | 6e9578d | CHANGELOG.md |

## Verification Results

- `mix compile --warnings-as-errors`: PASS (0 warnings — missing setup/0 would now emit a warning)
- `mix test`: PASS (311 tests, 0 failures)
- `mix verify.public_api` (mix docs --warnings-as-errors): PASS
- `grep -L "@behaviour Parapet.Integration"` over all eight integration modules: no output (all declare it)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Code.ensure_loaded! required before function_exported? in conformance test**
- **Found during:** Task 1 — GREEN phase
- **Issue:** `function_exported?(Parapet.Integrations.Sigra, :setup, 0)` returned `false` in the test even after the module compiled with `setup/0` exported. The integration modules are lazily loaded by the BEAM and `function_exported?` returns false for unloaded modules.
- **Fix:** Added `Code.ensure_loaded!(mod)` before `function_exported?(mod, :setup, 0)` in the conformance test loop.
- **Files modified:** test/parapet/integrations/integration_behaviour_test.exs
- **Commit:** 734d820

**2. [Coordination] Rulestead setup/0 added in Task 1 commit rather than Task 2**
- **Found during:** Task 1 — compile with `--warnings-as-errors`
- **Issue:** Adding `@behaviour Parapet.Integration` to Rulestead without `setup/0` caused `mix compile --warnings-as-errors` to fail with "function setup/0 required by behaviour is not implemented". The plan explicitly noted to "coordinate" Tasks 1 and 2 for Rulestead.
- **Fix:** Added `setup/0` delegate to Rulestead in the Task 1 GREEN commit so the compile gate passed cleanly. Task 2 then focused on the `@doc` fix and rulestead_test.exs addition.
- **Files modified:** lib/parapet/integrations/rulestead.ex

## Known Stubs

None — all eight integration modules have live `setup/0` implementations wired to their existing telemetry attach logic.

## Threat Flags

No new network endpoints, auth paths, or trust-boundary file access patterns were introduced. All changes are additive behaviour declarations and a one-line delegate. Consistent with the plan's threat model (T-18-01, T-18-02 both accepted).

## Self-Check: PASSED

- lib/parapet/integration.ex: FOUND
- lib/parapet/integrations/rulestead.ex (def setup): FOUND
- test/parapet/integrations/integration_behaviour_test.exs: FOUND
- Commits 14f1037, 734d820, 1ef08d4, 6e9578d: verified in git log
