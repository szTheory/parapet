---
phase: 57-test-suite-baseline
plan: "02"
subsystem: test-suite
tags: [test-cleanup, concurrency, sleep-vocabulary, assert-eventually, readiness-barrier]
dependency_graph:
  requires: [57-01]
  provides: [TEST-04, TEST-05]
  affects:
    - test/support/concurrency_case.ex
    - test/parapet/automation/executor_cluster_smoke_test.exs
    - test/parapet/escalation/worker_concurrency_test.exs
    - test/parapet/automation/executor_concurrency_test.exs
    - test/parapet/automation/claim_service_test.exs
    - test/parapet/operator/confirm_concurrency_test.exs
    - scripts/check_intentional_hold.sh
tech_stack:
  added: []
  patterns:
    - assert-eventually-plain-def
    - bounded-readiness-barrier
    - intentional-hold-annotation
    - grep-guard-script
key_files:
  created:
    - scripts/check_intentional_hold.sh
  modified:
    - test/support/concurrency_case.ex
    - test/parapet/automation/executor_cluster_smoke_test.exs
    - test/parapet/escalation/worker_concurrency_test.exs
    - test/parapet/automation/executor_concurrency_test.exs
    - test/parapet/automation/claim_service_test.exs
    - test/parapet/operator/confirm_concurrency_test.exs
decisions:
  - "D-12: assert_eventually/2 implemented as plain def (not macro, no hex dep) on ConcurrencyCase — matches the allow/2 + unboxed_run/1 idiom exactly"
  - "D-13: opts: :timeout (1_000ms), :interval (25ms constant, no backoff), :message (optional prefix)"
  - "D-14: catches ONLY ExUnit.AssertionError; re-raises last error verbatim on timeout; falsy-only timeout shows last value + elapsed ms"
  - "D-07/D-08: SELECT 1 barrier uses self-referential ready?.(ready?) anon fn (heredoc can't define named fns); 5_000ms deadline, 25ms backoff, raises DX message naming repo/node/env-vars on expiry"
  - "D-09/D-10: per-file @concurrency_hold_ms (75x4, 50x1); two-line INTENTIONAL HOLD: comment with NOT-a-lazy-wait line 2 signal"
  - "D-11: heredoc twin at line ~154 keeps literal Process.sleep(75) — @concurrency_hold_ms does not exist on fresh peer node"
  - "D-17: check_intentional_hold.sh standalone grep guard (not wired to CI); exempts executor_cluster_smoke_test.exs SELECT-1 barrier"
metrics:
  duration: "5 minutes"
  completed: "2026-07-02"
  tasks_completed: 4
  files_modified: 6
  files_created: 1
status: complete
---

# Phase 57 Plan 02: Test Suite Baseline (Sleep Vocabulary and assert_eventually) Summary

**One-liner:** Three-primitive sleep vocabulary established — `assert_eventually/2` helper (re-raises real assertion diffs), a bounded `SELECT 1` readiness barrier replacing the startup race, and `INTENTIONAL HOLD:` annotations on all six deliberate race-widening hold sites — plus a standalone grep guard enforcing the D-16 grammar going forward.

## What Was Built

### Task 1 — `assert_eventually/2` on `ConcurrencyCase` (TEST-05)

Added a plain `def assert_eventually(fun, opts \\ [])` to `Parapet.TestSupport.ConcurrencyCase` (`test/support/concurrency_case.ex`):

- **Signature:** `opts` accepts `:timeout` (default 1,000ms), `:interval` (constant 25ms, no backoff), `:message` (optional prefix on falsy-timeout failure).
- **On success:** returns the truthy value (bindable by caller).
- **On timeout with assertion errors:** `reraise`s the last captured `ExUnit.AssertionError` with its stacktrace verbatim — the operator sees the real assertion diff, never a generic "timed out" message (the #1 prior-art footgun).
- **On timeout with falsy returns:** raises `ExUnit.AssertionError` showing the last inspected value and elapsed budget in ms.
- **Catch scope:** `ExUnit.AssertionError` only — `MatchError`, `DBConnection` errors, and any other exceptions propagate immediately (real bugs fail loud, D-14).
- **Exported:** added `assert_eventually: 2` to the `import only:` list in the `using` block so every `use ConcurrencyCase` module gets the helper.

### Task 2 — `SELECT 1` readiness barrier (TEST-04, D-07/D-08)

Replaced `Process.sleep(200)` in the `repo_keeper` heredoc inside `executor_cluster_smoke_test.exs` with a bounded readiness poll:

- **Why not `Process.whereis`:** `Ecto.Repo.start_link` returns `{:ok, pid}` and `Process.whereis` is non-nil while DBConnection has zero live connections (lazy/async pool). Only a completing query is an honest readiness signal.
- **Implementation:** self-referential anonymous function `ready?.(ready?, deadline)` (heredoc strings cannot define named functions) — each attempt runs `Ecto.Adapters.SQL.Sandbox.unboxed_run(ConcurrencyRepo, fn -> Ecto.Adapters.SQL.query!(ConcurrencyRepo, "SELECT 1", []) end)`.
- **Bounds:** 5,000ms deadline, 25ms backoff between attempts, `rescue` converts any DB/connection error to a retry (distinct from `assert_eventually` which retries only on `ExUnit.AssertionError`).
- **On expiry:** raises with a DX message naming `Parapet.TestSupport.ConcurrencyRepo`, the peer `node()`, and the relevant env vars (`PARAPET_CONCURRENCY_DB_HOST/PORT/NAME/USER`).

### Task 3 — `INTENTIONAL HOLD:` annotations on all six hold sites (TEST-04, D-09/D-10/D-11)

Five per-file `@concurrency_hold_ms` module attribute sites:

| File | Module Scope | Value | Verb |
|------|-------------|-------|------|
| `worker_concurrency_test.exs` | `SuccessPolicy` nested defmodule | 75ms | escalate |
| `executor_concurrency_test.exs` | `ConcurrencyRunbook` nested defmodule | 75ms | mitigate |
| `claim_service_test.exs` | outer `ClaimServiceTest` module | **50ms** | gate |
| `confirm_concurrency_test.exs` | outer `ConfirmConcurrencyTest` module | 75ms | execute |
| `executor_cluster_smoke_test.exs` | `ClusterRunbook` nested defmodule | 75ms | mitigate |

Sixth site — heredoc twin in `executor_cluster_smoke_test.exs` (`remote_setup` ~line 154): keeps a literal `Process.sleep(75)` with its own inline `INTENTIONAL HOLD:` two-line comment. A caller-side note above the `remote_setup = """` line flags the local + twin as deliberate duplicates that must stay in sync (D-11).

Every annotated site uses the two-line comment shape:
```
# INTENTIONAL HOLD: keeps the winner mid-<verb> so the loser's claim insert races the unique constraint.
# NOT a lazy wait — do not replace with assert_eventually/the start-barrier.
```

### Task 4 — `scripts/check_intentional_hold.sh` grep guard (D-17)

A standalone POSIX shell script (`#!/usr/bin/env bash`, `set -euo pipefail`) that scans `test/**/*.exs` for any `Process.sleep(` not preceded by an `INTENTIONAL HOLD:` comment within the previous two lines. Exempts `executor_cluster_smoke_test.exs` (the SELECT 1 barrier). Exits 0 when clean, exits 1 with file:line + remediation hint when violations are found. NOT wired into `mix test`, CI, or `.credo.exs` (D-17 promotion deferred to Phase 58/59).

## Verification Results

All plan acceptance criteria passed:

- `grep -c 'def assert_eventually(fun, opts' test/support/concurrency_case.ex` — 1
- `grep -c 'assert_eventually: 2' test/support/concurrency_case.ex` — 1
- `grep -c 'Process.sleep(200)' test/parapet/automation/executor_cluster_smoke_test.exs` — 0
- `grep -c 'SELECT 1' test/parapet/automation/executor_cluster_smoke_test.exs` — 2 (barrier + downstream script)
- `grep -c 'PARAPET_CONCURRENCY_DB' test/parapet/automation/executor_cluster_smoke_test.exs` — 2
- `INTENTIONAL HOLD:` present in all 5 hold files (5/5)
- `grep -c 'INTENTIONAL HOLD:' executor_cluster_smoke_test.exs` — 2 (local copy + heredoc twin)
- `@concurrency_hold_ms 50` in `claim_service_test.exs` — 1
- `@concurrency_hold_ms 75` in other 4 files — 1 each
- No `#{@concurrency_hold_ms}` interpolation inside `remote_setup` heredoc — 0
- `bash scripts/check_intentional_hold.sh` — exits 0
- `mix compile --warnings-as-errors` — clean

Note on DB-backed tests: the concurrency test files require `parapet_concurrency_test` DB to be reachable for a full green run. Files were compile-verified (`mix compile --warnings-as-errors`) and statically verified (all greps above). The `mix test test/parapet/operator/confirm_concurrency_test.exs` run from the Task 1 verify block confirms the test module compiles and imports correctly under the widened `import only:` list.

## Deviations from Plan

None — plan executed exactly as written. All six hold sites were annotated per D-09/D-10/D-11 with the correct attribute scoping rules (nested `defmodule` attributes placed inside the nested scope, outer-module inline fns using the outer module's attribute). The caller-side note in Task 3 was adjusted to avoid using the `INTENTIONAL HOLD:` token itself (which would inflate the grep count from 2 to 3 in executor_cluster_smoke_test.exs).

## Known Stubs

None — all symbols are fully implemented with no placeholder returns or hardcoded empty values.

## Threat Flags

None — this plan edits only `test/` files and adds one shell script in `scripts/`. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Self-Check: PASSED

Files created:
- FOUND: scripts/check_intentional_hold.sh

Files modified:
- FOUND: test/support/concurrency_case.ex
- FOUND: test/parapet/automation/executor_cluster_smoke_test.exs
- FOUND: test/parapet/escalation/worker_concurrency_test.exs
- FOUND: test/parapet/automation/executor_concurrency_test.exs
- FOUND: test/parapet/automation/claim_service_test.exs
- FOUND: test/parapet/operator/confirm_concurrency_test.exs

Commits:
- FOUND: 8e0d5b3 (Task 1 — assert_eventually/2)
- FOUND: 1381f68 (Task 2 — SELECT 1 readiness barrier)
- FOUND: c332086 (Task 3 — INTENTIONAL HOLD: annotations)
- FOUND: e955413 (Task 4 — check_intentional_hold.sh grep guard)
