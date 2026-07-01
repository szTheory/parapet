---
phase: 54-upgrade-path-doctor
plan: "01"
subsystem: testing
tags: [elixir, mix-task, doctor, schema-prefix, ecto, postgres]

requires:
  - phase: 51-prefix-core-test-seam
    provides: Parapet.Spine.Schema.__prefix__/0 and normalize/1 (compile-time prefix API used by check_schema/0)

provides:
  - schema static check in mix parapet.doctor (DOCTOR-01) — drift detection + schema existence probe
  - test/parapet/doctor_schema_check_test.exs — drift/missing/skip/exit-code unit coverage

affects:
  - 54-02 (gen.schema.move task — uses same doctor framework)
  - 55-demo-app-upgrade-docs (operator docs will reference mix parapet.doctor --ci)
  - 56-contract-release-hardening (frozen-contract verification includes doctor check list)

tech-stack:
  added: []
  patterns:
    - "Doctor static check drop-in: %{status:, messages:} map returned by a named defp, dispatched from run_static_check/1, added to @static_checks"
    - "Double-normalize drift guard: both runtime and compiled prefix run through normalize/1 before comparison to prevent nil-vs-public false positive (D-02)"
    - "Repo-not-running skip guard: is_nil(repo) or Process.whereis(repo) == nil + try/rescue degrades to :skip, never :error (D-03)"
    - "Parameterized catalog probe: SELECT to_regnamespace($1) IS NOT NULL — bound param, not string-interpolated (D-02/T-54-01)"

key-files:
  created:
    - test/parapet/doctor_schema_check_test.exs
  modified:
    - lib/mix/tasks/parapet.doctor.ex

key-decisions:
  - "check_schema/0 made @doc false public (not private) to support direct unit-test invocation — mirrors the __prefix__/0 pattern"
  - "Existence probe degrades to :skip on nil repo OR absent repo process — nil guard handles unconfigured repos, Process.whereis handles configured but stopped repos (D-03)"
  - "cond rollup orders drift first, then existence:absent, then existence:skip — drift catches stale-compile footgun before a DB is even consulted (D-02/D-05)"

patterns-established:
  - "Pattern: Doctor static check drop-in (new checks follow @static_checks + run_static_check clause + defp returning %{status:, messages:})"
  - "Pattern: Drift-before-existence cond rollup — always check compile-time vs runtime config disagreement FIRST so DB-less CI catches drift"

requirements-completed: [DOCTOR-01]

coverage:
  - id: D1
    description: "schema static check added to @static_checks in mix parapet.doctor with drift + existence signals folded into one cond-rollup finding"
    requirement: DOCTOR-01
    verification:
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-02 drift detection returns :error with recompile remediation when runtime prefix disagrees with compiled"
        status: pass
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-02 drift detection does NOT return :error from drift when runtime prefix normalizes equal to compiled"
        status: pass
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-03 skip when repo not running returns :skip (never raises) when no repo is configured"
        status: pass
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-03 skip when repo not running returns :skip (never raises) when repo process is not running"
        status: pass
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-05 --ci exit-code contract :error severity is at or above :warn threshold"
        status: pass
      - kind: unit
        ref: "test/parapet/doctor_schema_check_test.exs#D-05 --ci exit-code contract drift finding status :error is recognized as a CI failure severity"
        status: pass
    human_judgment: false

duration: 4min
completed: "2026-07-01"
status: complete
---

# Phase 54 Plan 01: Schema Doctor Check Summary

**schema static check added to mix parapet.doctor: compile-time drift detection via double-normalize + parameterized to_regnamespace existence probe with repo-not-running skip guard (DOCTOR-01)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-01T18:05:37Z
- **Completed:** 2026-07-01T18:10:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Added `"schema"` to `@static_checks` in `lib/mix/tasks/parapet.doctor.ex` (stays in default static suite — no `--cluster` flag needed, D-01)
- Implemented `check_schema/0` with dual-signal cond rollup: drift (compile vs runtime, double-normalize) → `:error`; schema absent → `:error`; repo not running → `:skip`; in-sync → `:info`
- Existence probe uses `SELECT to_regnamespace($1) IS NOT NULL` with bound parameter — never string-interpolated (D-02, T-54-01)
- D-04 verbatim remediation microcopy: drift → `mix deps.compile parapet --force`; missing → `mix parapet.gen.spine + mix ecto.migrate`; skip → `mix parapet.doctor cluster`
- Unit tests cover all four states (drift/no-false-positive/skip-nil-repo/skip-absent-process) + exit-code severity contract; green on both CI legs (`PARAPET_SCHEMA_PREFIX=parapet` and `PARAPET_SCHEMA_PREFIX=''`)

## Task Commits

1. **Task 1: Add the schema static check to parapet.doctor.ex** - `9557b6f` (feat)
2. **Task 2: Unit-test the schema check** - `da7bd40` (test)

## Files Created/Modified

- `lib/mix/tasks/parapet.doctor.ex` - Added `"schema"` to @static_checks, `run_static_check("schema")` clause, `check_schema/0` public (@doc false) with drift+existence cond rollup, three D-04 message helpers
- `test/parapet/doctor_schema_check_test.exs` - New: async: false, 6 tests covering D-02/D-03/D-05 decision IDs

## Decisions Made

- `check_schema/0` is `@doc false` public rather than private — enables direct unit-test invocation without coupling to `run/1` halting behavior; mirrors `__prefix__/0` pattern in the codebase
- Drift cond branch is ordered FIRST (before existence) so a DB-less `mix parapet.doctor --ci` always catches compile/runtime mismatch without needing a live repo (D-01/D-05)
- Existence probe degrades to `:skip` on nil repo AND absent process — two distinct guard conditions cover both unconfigured (nil) and configured-but-stopped repos

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] check_schema/0 made @doc false public for testability**
- **Found during:** Task 2 (unit test creation)
- **Issue:** Plan says to "assert on the returned check_schema/0 map status" but `:erlang.apply` cannot bypass private function visibility in Elixir — tests produced `UndefinedFunctionError`
- **Fix:** Changed `defp check_schema do` to `@doc false\ndef check_schema do` so the test can call `Mix.Tasks.Parapet.Doctor.check_schema()` directly
- **Files modified:** lib/mix/tasks/parapet.doctor.ex
- **Verification:** All 6 tests pass; the function is still dispatched via `run_static_check("schema")` in the public `run/1` path unchanged
- **Committed in:** da7bd40 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing testability hook)
**Impact on plan:** Minimal visibility change (private → @doc false public); semantically equivalent for callers of the Mix task public interface. Necessary for the unit-test contract the plan mandated.

## Issues Encountered

- Stale `_build` compile_env mismatch when switching between `PARAPET_SCHEMA_PREFIX` values during verification: resolved by `mix compile --force` on each leg before running tests. This is a pre-existing CI dual-prefix requirement (Phase 52) — both legs were confirmed green after force-recompile.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries were introduced. The `to_regnamespace($1)` parameterized probe (T-54-01) and `Process.whereis` skip guard (T-54-02) are the two threat mitigations from the plan's threat register — both implemented as designed.

## Next Phase Readiness

- DOCTOR-01 satisfied: `mix parapet.doctor --ci` in a repo with schema_prefix drift exits 1 with the recompile remediation
- Plan 54-02 (`mix parapet.gen.schema.move` Igniter task) can proceed independently — no doctor changes needed
- The `check_schema/0` @doc false public pattern is available for future doctor check testing

---
*Phase: 54-upgrade-path-doctor*
*Completed: 2026-07-01*
