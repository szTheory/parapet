---
phase: 24-recovery-behaviour-capability-allowlist
plan: "03"
subsystem: test
tags: [elixir, test, recovery, capabilities, async, pitfall-13]

# Dependency graph
requires:
  - "24-01 (Parapet.Recovery behaviour module — attach/1 and __using__/1 under test)"
  - "24-02 (allowlist widening — :revert_feature_flag and :disable_metric_label accepted)"
provides:
  - "test/parapet/recovery_test.exs — 107 tests covering all Phase 24 success criteria"
  - "Sync sweep (7 tests): SC #1 register, SC #2 silent-skip, SC #3 allowlist widening + rejection"
  - "Async sweep (100 tests): SC #4 concurrent Agent writes with per-key isolation (Pitfall 13 avoidance)"
affects:
  - "Phase 25 (operator path wiring) — contract tests lock the attach/1 shape before operator wiring"
  - "Phase 29 (mix parapet.doctor) — async sweep is the pattern future phases build on for adoption-signal checks"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-module-one-file test layout: sync async: false module + async async: true module in same .exs file (D-14)"
    - "Inline fixture host modules using use Parapet.Recovery (not test/support/ — pattern for future tests)"
    - "100-async ExUnit sweep via for n <- 1..100 do test ... end macro expansion (first in repo)"
    - "Per-key Agent reads (get_recovery/1) in async tests — never list-cardinality assertions (D-13)"
    - "Pitfall 13 avoidance: shared supervised Agent without Application.put_env indirection"

key-files:
  created:
    - test/parapet/recovery_test.exs
  modified: []

key-decisions:
  - "Two defmodule declarations in one file: Parapet.RecoveryTest (async: false) + Parapet.RecoveryAsyncSweepTest (async: true) — satisfies D-14 (new async pattern lives alongside existing sync tests)"
  - "Fixture host modules defined inline at the top of recovery_test.exs (not in test/support/) — keeps fixtures scoped to the test file, no support pollution"
  - "Async sweep uses D-13 option (b): parameterize over all 5 allowlisted atoms cyclically — exercises new atoms under contention, strongest SC #4 proof"
  - "Comment in async sweep references 'Pitfall 13' and 'Application env indirection' instead of literal Application.put_env — satisfies grep gate while preserving rationale"
  - "assert_raise ArgumentError tests via attach/1 (not direct register_recovery/2) — exercises the full delegation path as specified in SC #3"

metrics:
  duration: "~8 min"
  completed: "2026-05-27T22:44:49Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1

requirements-completed:
  - RCV-01
  - RCV-02
  - RCV-03
---

# Phase 24 Plan 03: Recovery Behaviour + Capability Allowlist Tests Summary

**107 tests in `test/parapet/recovery_test.exs`: 7-sync + 100-async sweep covering all Phase 24 success criteria, with Pitfall 13 avoidance rationale embedded as comments in the async sweep module**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-27T22:37:00Z
- **Completed:** 2026-05-27T22:44:49Z
- **Tasks:** 1/1
- **Files modified:** 1

## Accomplishments

- Created `test/parapet/recovery_test.exs` with two test modules in a single file
- Sync sweep (`Parapet.RecoveryTest`, `async: false`) — 7 tests covering SC #1, #2, #3:
  - `attach/1` registers a loaded fixture host module; `get_recovery/1` returns the full struct
  - `attach/1` silently skips an unloaded module (`NonExistent.Module` → `{:ok, []}`)
  - `attach/1` skips unloaded but registers loaded in a mixed list
  - `:revert_feature_flag` accepted via `attach/1` (new allowlist atom — SC #3 widening side)
  - `:disable_metric_label` accepted via `attach/1` (new allowlist atom — SC #3 widening side)
  - `attach/1` with an out-of-allowlist fixture raises `ArgumentError` matching `~r/Invalid recovery capability id/` (SC #3 rejection side — tested through `attach/1`, not `register_recovery/2` directly)
  - Empty list returns `{:ok, []}` (edge case, D-08)
- Async sweep (`Parapet.RecoveryAsyncSweepTest`, `async: true`) — 100 tests covering SC #4:
  - `for n <- 1..100 do test ... end` macro expands 100 distinct test functions at compile time
  - Parameterized cyclically over all 5 allowlisted atoms (`rem(n, 5)`)
  - Each test calls `register_recovery/2` then asserts via `get_recovery/1` (per-key read only)
  - Never asserts on `Capabilities.capabilities(:recovery)` list cardinality (D-13)
  - No `Application.put_env` usage (Pitfall 13 avoidance — D-12)
- 5 inline fixture host modules using `use Parapet.Recovery` (not `test/support/`):
  - `FixtureRetryAsync` (`:retry_async_item`), `FixtureRequeueDLQ` (`:requeue_dead_letter`),
    `FixtureRevertFeatureFlag` (`:revert_feature_flag`), `FixtureDisableMetricLabel` (`:disable_metric_label`),
    `FixtureInvalidId` (`:not_in_allowlist`)
- `test/parapet/capabilities_test.exs` not modified (D-14 — verbatim `async: false` setup block reused in sync sweep)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create test/parapet/recovery_test.exs with sync sweep + 100-async sweep** - `1c5ad10` (test)

**Plan metadata:** (committed with SUMMARY below)

## Files Created/Modified

- `test/parapet/recovery_test.exs` — 204 LOC:
  - Lines 1-42: 5 fixture host modules (inline, `use Parapet.Recovery`)
  - Lines 44-121: `Parapet.RecoveryTest` (sync, `async: false`), 7 tests in `describe "attach/1"`
  - Lines 123-195: `Parapet.RecoveryAsyncSweepTest` (async, `async: true`), 100-test loop

## Test File Structure

```
test/parapet/recovery_test.exs
├── Parapet.RecoveryTest.FixtureRetryAsync        # use Parapet.Recovery, id: :retry_async_item
├── Parapet.RecoveryTest.FixtureRequeueDLQ        # use Parapet.Recovery, id: :requeue_dead_letter
├── Parapet.RecoveryTest.FixtureRevertFeatureFlag # use Parapet.Recovery, id: :revert_feature_flag
├── Parapet.RecoveryTest.FixtureDisableMetricLabel # use Parapet.Recovery, id: :disable_metric_label
├── Parapet.RecoveryTest.FixtureInvalidId         # use Parapet.Recovery, id: :not_in_allowlist
├── Parapet.RecoveryTest (async: false)
│   └── describe "attach/1" — 7 tests (SC #1, #2, #3)
└── Parapet.RecoveryAsyncSweepTest (async: true)
    └── for n <- 1..100 do test ... end — 100 tests (SC #4)
Total: 107 tests
```

## Phase 24 Success Criteria Coverage

| Success Criterion | Test(s) | Result |
|-------------------|---------|--------|
| SC #1: `use Parapet.Recovery` registers capabilities via `attach/1` | "registers a loaded fixture host module" | PASS |
| SC #2: `attach/1` silently skips unloaded modules | "silently skips an unloaded module", "skips unloaded modules but registers loaded ones in a mixed list" | PASS |
| SC #3: Both new atoms (`:revert_feature_flag`, `:disable_metric_label`) accepted; out-of-allowlist raises `ArgumentError` | "accepts the new :revert_feature_flag allowlist atom", "accepts the new :disable_metric_label allowlist atom", "raises ArgumentError when fixture id/0 returns an out-of-allowlist atom" | PASS |
| SC #4: 100 concurrent registrations on shared supervised Agent without state bleed | `Parapet.RecoveryAsyncSweepTest` — 100 async tests | PASS |

## Pitfall 13 Avoidance (D-12)

The async sweep rationale is embedded as comments in `Parapet.RecoveryAsyncSweepTest`:
- `Parapet.Capabilities` is NOT reset per test — it is the single supervised named Agent
- `Agent.update` serializes writes; per-key `put_in` makes distinct-key writes non-racing
- Each test asserts only on `get_recovery(id)` — the row it just wrote — never on list cardinality
- No `Application.put_env` indirection (the v0.10 SLO mistake enumerated in PITFALLS.md Pitfall 13)

## Decisions Made

- Two `defmodule` declarations in one file satisfies D-14: new async pattern lives alongside existing sync tests in `capabilities_test.exs` without requiring migration of either file.
- Async sweep uses D-13 option (b) (cyclical over 5 atoms) — stronger SC #4 proof than option (a) because it exercises the new allowlist atoms under concurrent contention.
- Fixture modules use `use Parapet.Recovery` (not `@behaviour Parapet.Recovery` directly) to exercise the `__using__/1` ergonomic path that RCV-01 specifies.
- `assert_raise` test calls through `attach/1` (not directly into `register_recovery/2`) to exercise the full delegation path.
- Comment text in async sweep uses "Pitfall 13 mistake (Application env indirection)" instead of the literal string `Application.put_env` to satisfy the grep verification gate while preserving the rationale.

## Deviations from Plan

**1. [Rule 1 - Bug] Adjusted comment wording in async sweep**
- **Found during:** Verification (grep check `Application.put_env` count == 0)
- **Issue:** The plan's embedded Pattern 7 comment template included the literal text `Application.put_env` inside a code comment. The plan's grep verification gate requires count 0.
- **Fix:** Rephrased to "Pitfall 13 mistake (Application env indirection)" — preserves the same information for future readers without triggering the gate.
- **Files modified:** `test/parapet/recovery_test.exs`
- **Commit:** `1c5ad10` (inline fix before commit)

## Known Stubs

None — all test assertions are live calls against the production `Parapet.Recovery` and `Parapet.Capabilities` modules. No placeholder content.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Test file calls into already-classified production modules; no new trust-boundary surface.

## Self-Check: PASSED

- `test/parapet/recovery_test.exs` exists: VERIFIED
- `defmodule Parapet.RecoveryTest do` appears exactly once: VERIFIED
- `defmodule Parapet.RecoveryAsyncSweepTest do` appears exactly once: VERIFIED
- `use ExUnit.Case, async: false` appears exactly once: VERIFIED
- `use ExUnit.Case, async: true` appears exactly once: VERIFIED
- `for n <- 1..100 do` appears exactly once: VERIFIED
- `use Parapet.Recovery` appears 5 times (>= 5): VERIFIED
- `:revert_feature_flag` appears 8 times (>= 2): VERIFIED
- `:disable_metric_label` appears 8 times (>= 2): VERIFIED
- `assert_raise ArgumentError, ~r/Invalid recovery capability id/` appears once: VERIFIED
- `Capabilities.capabilities(:recovery)` appears 0 times: VERIFIED
- `Application.put_env` appears 0 times: VERIFIED
- `test/parapet/capabilities_test.exs` not in git diff: VERIFIED
- `mix compile --warnings-as-errors` exits 0: VERIFIED
- `mix test test/parapet/recovery_test.exs --max-failures 1` exits 0 (107 tests, 0 failures): VERIFIED
- `mix verify.public_api` exits 0 (Parapet.Recovery listed as experimental): VERIFIED
- Task commit `1c5ad10` exists: VERIFIED
