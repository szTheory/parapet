---
phase: 29-stability-adopter-onboarding
plan: "03"
subsystem: mix-doctor
tags: [doctor, recovery, capabilities, adopter-onboarding, tdd]
dependency_graph:
  requires: []
  provides: [check_recovery, recovery-doctor-check, ADOP-02]
  affects: [lib/mix/tasks/parapet.doctor.ex, lib/parapet/capabilities.ex, lib/parapet/recovery.ex, test/mix/tasks/parapet_doctor_test.exs]
tech_stack:
  added: []
  patterns: [doctor-check-contract, capabilities-agent-introspection, runbook-module-discovery]
key_files:
  created: []
  modified:
    - lib/mix/tasks/parapet.doctor.ex
    - lib/parapet/capabilities.ex
    - lib/parapet/recovery.ex
    - test/mix/tasks/parapet.doctor_test.exs
decisions:
  - "A1: zero capabilities → :info status used instead of :ok — @severity_order map has no :ok key; :info is the existing harness contract for passing checks"
  - "Rule 2: added module: field to Parapet.Capabilities capability map for check_recovery host-module introspection"
  - "Guard added: Capabilities Agent not running → :skip (Mix task load-only context, OTP not started)"
metrics:
  duration: "7 minutes"
  completed: "2026-05-29"
  tasks_completed: 2
  files_modified: 4
---

# Phase 29 Plan 03: check_recovery doctor check (ADOP-02) Summary

**One-liner:** `check_recovery` static check for `mix parapet.doctor` reporting three D-12 adoption signals via guarded runbook-module introspection, with :skip on zero capabilities preserving the fresh-install CI invariant.

## What Was Built

Added `check_recovery` to `mix parapet.doctor` as a new static check (ADOP-02). The check is registered in `@static_checks`, dispatched via `run_static_check("recovery")`, and implements three adoption signals:

1. **COUNT signal**: `Parapet.Capabilities.capabilities(:recovery)` — zero → `:skip` (A1 resolution; keeps `--ci` green on fresh installs)
2. **UNREGISTERED-IN-RUNBOOK signal**: iterates `Parapet.SLO.all()`, resolves each SLO's runbook string to a module via `recovery_runbook_module/1` (mirrors `alert_processor.ex:116-128`), calls `__runbook_schema__/0`, cross-checks each step's `:capability` atom against `Parapet.Capabilities.get_recovery/1` — nil means unregistered → `:warn`
3. **PER-CAPABILITY HEALTH signal**: for each registered capability with a stored `module`, checks `Code.ensure_loaded?/1` and `function_exported?/2` for all 4 frozen callbacks (`id/0`, `label/0`, `preview/2`, `execute/2`) — missing module or callback → `:warn`

URL-valued runbooks resolve to nil via `String.to_existing_atom` + rescue (never `String.to_atom` on untrusted input) and fall through silently — Pitfall 4 / T-29-05 mitigated.

`check_runbooks` is entirely unchanged — D-13 respected.

## Tasks Completed

| Task | Description | Commit |
|------|-------------|--------|
| 1 | Wave-0 check_recovery signal-condition tests (RED) | 34e5f3e |
| 2 | Add check_recovery to parapet.doctor.ex (GREEN) | a97c583 |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added `module:` field to Parapet.Capabilities capability map**
- **Found during:** Task 1 (test design)
- **Issue:** The plan requires `check_recovery` to inspect the host module of each registered capability via `Code.ensure_loaded?` and `function_exported?`. The capability map had no `module:` key — only `preview:` and `execute:` as anonymous function captures. Without a `module:` key, the "missing module" and "missing callback" signal conditions cannot be tested reliably (function captures from non-existent modules can't be created, and `:erlang.fun_info` on lambdas returns the defining module not the host).
- **Fix:** Added `module: Keyword.get(attrs, :module)` to the capability struct in `capabilities.ex` (backward-compatible, defaults to nil — all existing calls unaffected). Updated `recovery.ex` `attach/1` to pass `module: module`. The check skips nil-module caps gracefully.
- **Files modified:** `lib/parapet/capabilities.ex`, `lib/parapet/recovery.ex`
- **Commits:** 34e5f3e, a97c583

**2. [Rule 1 - Bug] Used `:info` instead of `:ok` for the healthy-capabilities status**
- **Found during:** Task 2 (GREEN gate)
- **Issue:** Plan specified `%{status: :ok, ...}` for the healthy state, but `@severity_order` in `doctor.ex` only has `{skip: 0, info: 0, warn: 1, error: 2}` — no `:ok` key. Using `:ok` caused a `KeyError` crash in `findings_exit_code/2`.
- **Fix:** Changed to `%{status: :info, ...}` (matching all other passing checks: `check_runbooks`, `check_cardinality`, etc.). Updated test assertion from `"==> recovery: ok"` to `"==> recovery: info"`.
- **Files modified:** `lib/mix/tasks/parapet.doctor.ex`, `test/mix/tasks/parapet_doctor_test.exs`
- **Commit:** a97c583

**3. [Rule 2 - Missing Critical Functionality] Added Capabilities Agent guard to check_recovery**
- **Found during:** Task 2 verification (`mix parapet.doctor --ci recovery` on the parapet repo itself)
- **Issue:** `mix parapet.doctor` loads the app config (`Application.load/1` + `app.config`) but does NOT start the OTP application tree. `Parapet.Capabilities` is an Agent that only starts as part of the OTP supervision tree. Without it running, `check_recovery` crashed with "no process" error.
- **Fix:** Added `if Process.whereis(Parapet.Capabilities) == nil` guard at the top of `check_recovery` — returns `:skip` when the Agent isn't running, keeping `--ci` green. This is consistent with the "skip when unavailable" contract used by other checks (e.g., `check_router` skips when Sourceror is absent).
- **Files modified:** `lib/mix/tasks/parapet.doctor.ex`
- **Commit:** a97c583

## Verification

- `mix compile --warnings-as-errors` exits 0
- `mix test test/mix/tasks/parapet.doctor_test.exs` exits 0 — 16 tests, 0 failures
- `mix parapet.doctor --ci recovery` exits 0 (zero capabilities → :skip → no --ci trip)
- `grep -v '^[[:space:]]*#' lib/mix/tasks/parapet.doctor.ex | grep -c "defp check_recovery"` → 1
- `grep -F 'run_static_check("recovery")' lib/mix/tasks/parapet.doctor.ex` → matches
- `grep -E '@static_checks .*recovery' lib/mix/tasks/parapet.doctor.ex` → matches
- `check_runbooks` unchanged (D-13)
- `check_recovery` never returns `:error` and uses `String.to_existing_atom` (not `String.to_atom`) for runbook module resolution

## TDD Gate Compliance

- RED gate: `test(29-03)` commit 34e5f3e — 6 new cases failing with `Unsupported doctor checks: recovery` (assertion failures, not compilation errors)
- GREEN gate: `feat(29-03)` commit a97c583 — all 6 cases now passing

## Known Stubs

None — the implementation is complete and all six signal conditions are verified.

## Threat Flags

No new threat surface. T-29-05 (untrusted string → atom escalation) and T-29-06 (false-positive CI gate) are both mitigated:
- T-29-05: `recovery_runbook_module/1` uses `String.to_existing_atom` + rescue, never `String.to_atom`
- T-29-06: zero caps → `:skip`, guarded by regression test (A1 invariant)

## Self-Check: PASSED
