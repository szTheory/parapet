---
phase: 19-api-telemetry-freeze
plan: "02"
subsystem: telemetry-contract
tags: [telemetry, contract-testing, deprecation, stab-05, stab-06]
dependency_graph:
  requires: []
  provides: [telemetry-contract-test, slo-deprecation-verification]
  affects: [ci-gate, drift-detection]
tech_stack:
  added: []
  patterns: [module-attribute-as-compile-time-fixture, capture_io-stderr-deprecation-check]
key_files:
  created:
    - test/telemetry_contract_test.exs
  modified:
    - test/parapet/slo_test.exs
decisions:
  - "Added 6 delivery/async metadata key fixtures to @documented_metadata_keys (not just relying on module lookup) so the map serves as the drift-detection snapshot"
  - "Task 2 added to existing test/parapet/slo_test.exs (file already existed) rather than creating a new file"
  - "Scoria safe_labels confirmed as [:model, :provider, :tool_name] from lib/parapet/integrations/scoria.ex:12"
metrics:
  duration_minutes: 5
  completed_date: "2026-05-25"
  tasks_completed: 2
  files_created: 1
  files_modified: 1
---

# Phase 19 Plan 02: Telemetry Contract Test + SLO Deprecation Verification Summary

**One-liner:** ExUnit contract test freezing all 27 `[:parapet, …]` telemetry family fixtures (STAB-05) plus a `Code.compile_string` + `capture_io(:stderr)` test proving `Parapet.SLO.define/2` emits its compile-time deprecation warning (STAB-06).

## What Was Built

### Task 1: Telemetry Contract Test (STAB-05)

Created `test/telemetry_contract_test.exs` as `Parapet.TelemetryContractTest` with 33 tests covering:

- **Event family contract:** 6 delivery/async families derived from `AsyncDelivery.event_families/0` at compile time (D-07), 21 hardcoded families, total count asserted == 27.
- **Metadata key contract (delivery/async):** For each of the 6 delivery/async families, `AsyncDelivery.allowed_public_keys(family)` is sorted-compared against the fixture — drift in the module's vocab fails CI.
- **Metadata key contract (other families):** Journey, scoria, operator, probe, ecto, http, oban families each have metadata fixtures. Open-metadata families (`deploy:mark`, `audit:created`, `rulestead:flag_change`) are enumerated but NOT over-constrained.
- **Scoria safe_labels:** Confirmed `[:model, :provider, :tool_name]` from `lib/parapet/integrations/scoria.ex:12` — included in scoria metrics/stale/expired/resumed fixtures.
- **Outcome vocabulary:** Delivery (`:attempted`, `:provider_accepted`, `:delivered`, `:failed`, `:bounced`, `:complained`, `:suppressed`) and async (`:started`, `:succeeded`, `:retryable_failed`, `:discarded`, `:delayed`) vocabularies round-trip tested via `normalize_*_outcome/1`.
- All test failure messages instruct "Update docs/telemetry.md and this fixture together."

### Task 2: SLO Deprecation Warning Verification (STAB-06)

Added a `describe "Parapet.SLO.define/2 compile-time deprecation warning (STAB-06)"` block to the existing `test/parapet/slo_test.exs`:

- Uses `Code.compile_string` + `capture_io(:stderr)` to compile a throwaway module that calls `Parapet.SLO.define/2`.
- Asserts captured output `=~ "deprecated"` AND `=~ "Parapet.SLO.Provider"`.
- The `Code.compile_string` approach was confirmed to work (RESEARCH assumption A3 verified).
- No change was made to `lib/parapet/slo.ex` — `@deprecated` already in place at line 29 (D-14).

## Test Results

```
mix test test/telemetry_contract_test.exs test/parapet/slo_test.exs
39 tests, 0 failures
```

## Commits

| Task | Commit | Files |
|------|--------|-------|
| Task 1: Telemetry contract test | 93818a9 | test/telemetry_contract_test.exs (created) |
| Task 2: SLO deprecation assertion | 9cddb3a | test/parapet/slo_test.exs (modified) |

## Deviations from Plan

### Auto-handled: Existing slo_test.exs file

**Rule 3 - Blocking issue:** `test/parapet/slo_test.exs` already existed with functional SLO tests. The plan described creating it as a new file.

**Fix:** Added the STAB-06 `describe` block to the existing file rather than replacing it. All existing tests retained; `import ExUnit.CaptureIO` added at module level.

**Impact:** None — the plan's acceptance criteria are fully met. The file contains `capture_io(:stderr`, and the test asserts both "deprecated" and "Parapet.SLO.Provider".

### Fixture addition: Delivery/async metadata keys in @documented_metadata_keys

The RESEARCH.md pattern showed the delivery/async families' metadata keys being checked via `AsyncDelivery.allowed_public_keys/1` in the test loop, but no fixture map entries were provided for those 6 families. The test raises an error if `@documented_metadata_keys[family]` is nil.

**Fix:** Added explicit fixture entries for all 6 delivery/async families to `@documented_metadata_keys`, using the exact keys returned by `allowed_public_keys/1`. This ensures the map serves as a standalone drift snapshot — a developer who reads the test can see the full expected contract without running the code.

## Known Stubs

None.

## Threat Flags

None — test-only files, no new runtime surface.

## Self-Check: PASSED

Files exist:
- `test/telemetry_contract_test.exs`: FOUND
- `test/parapet/slo_test.exs`: FOUND (modified)

Commits exist:
- `93818a9`: FOUND
- `9cddb3a`: FOUND
