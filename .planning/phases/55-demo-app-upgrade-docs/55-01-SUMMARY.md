---
phase: 55-demo-app-upgrade-docs
plan: 01
subsystem: testing
tags: [elixir, ecto, postgresql, phoenix, ci, smoke-test, schema-prefix]

# Dependency graph
requires:
  - phase: 53-generators-library-migrations
    provides: demo app spine migrations that reference parapet schema prefix
  - phase: 54-upgrade-path-doctor
    provides: schema_prefix/0 API and Evidence.create_incident/1 write path
provides:
  - sentinel schema migration (00000000000000_create_parapet_schema.exs) enabling demo CI to run
  - SAFE-03 smoke assertions: get_meta round-trip + six-table existence in DemoApp.OperatorSmokeTest
  - demo compile-out-clean CI step in existing demo job
affects: [55-02, 56-public-api-freeze]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ecto.Adapters.SQL.query!/3 with parameterized $1 binding for information_schema queries (T-55-01 SQL injection defense)"
    - "schema_prefix() || 'public' nil-safety pattern for leg-agnostic information_schema WHERE clause"
    - "Version-0 sentinel migration (00000000000000_...) sorts before all numbered migrations"

key-files:
  created:
    - examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs
  modified:
    - examples/demo_app/test/demo_app/operator_smoke_test.exs
    - .github/workflows/ci.yml
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex

key-decisions:
  - "Sentinel migration version 0 sorts strictly before 20260525000000 — Ecto migrator uses Integer.parse on filename prefix"
  - "down/0 non-cascading (no CASCADE): raises 2BP01 if spine tables still exist, preventing silent data deletion"
  - "Both new smoke tests are top-level (not inside describe) so @moduletag :smoke applies to both"
  - "Parameterized $1 binding in information_schema query — defense-in-depth even though schema_prefix() is compile-frozen"
  - "schema_prefix() || 'public' nil-safety handles nil-prefix leg without changing assertion semantics for demo CI"

patterns-established:
  - "Leg-agnostic prefix assertion: assert Ecto.get_meta(record, :prefix) == Parapet.Evidence.schema_prefix() (never == 'parapet' literal)"
  - "Six-table existence via MapSet.difference pattern: queries all tables in one SQL call, diffs against expected set"

requirements-completed: [SAFE-03]

coverage:
  - id: D1
    description: "Sentinel migration 00000000000000_create_parapet_schema.exs creates parapet schema before spine table migrations run"
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: "examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs | mix ecto.drop && mix ecto.create && mix ecto.migrate"
        status: pass
    human_judgment: false
  - id: D2
    description: "SAFE-03 smoke: create_incident round-trip Ecto.get_meta(incident, :prefix) == schema_prefix() (leg-agnostic)"
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#schema prefix: evidence round-trip carries compiled prefix on returned struct | mix test --only smoke"
        status: pass
    human_judgment: false
  - id: D3
    description: "SAFE-03 smoke: all six spine tables exist in the configured schema (information_schema query, parameterized binding)"
    requirement: SAFE-03
    verification:
      - kind: integration
        ref: "examples/demo_app/test/demo_app/operator_smoke_test.exs#schema existence: all six spine tables exist in the configured schema | mix test --only smoke"
        status: pass
    human_judgment: false
  - id: D4
    description: "Demo compile-out-clean step in CI demo job: mix compile --no-optional-deps --warnings-as-errors passes before smoke test"
    requirement: SAFE-03
    verification:
      - kind: other
        ref: "examples/demo_app | mix compile --no-optional-deps --warnings-as-errors"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-07-01
status: complete
---

# Phase 55 Plan 01: SAFE-03 Sentinel Migration + Smoke Assertions Summary

**Sentinel schema migration + two leg-agnostic SAFE-03 smoke assertions + demo compile-out-clean CI step prove the parapet prefix migrates and writes correctly on a real Phoenix host**

## Performance

- **Duration:** 7 min
- **Started:** 2026-07-01T20:19:05Z
- **Completed:** 2026-07-01T20:26:00Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Created `00000000000000_create_parapet_schema.exs` sentinel migration (version 0 sorts before all spine migrations) — unblocks `mix ecto.migrate` which previously failed with ERROR 3F000 (schema "parapet" does not exist)
- Added two SAFE-03 smoke assertions to `DemoApp.OperatorSmokeTest` at module level (not inside a describe block): (1) `get_meta` round-trip asserting `Ecto.get_meta(incident, :prefix) == Parapet.Evidence.schema_prefix()` (leg-agnostic, never literal "parapet"), (2) six-table existence check via parameterized `information_schema.tables` query using `MapSet.difference` for a clear failure message listing missing tables
- Added `mix compile --no-optional-deps --warnings-as-errors` step to the existing CI `demo` job (placed after `mix deps.get`, before `mix ecto.create`) — no new job created, `release_gate` `needs: [lint, test, demo]` unchanged

## Task Commits

1. **Task 1: Add sentinel schema migration** - `c5e7730` (feat)
2. **Task 2: Add SAFE-03 smoke assertions** - `bbc4f30` (feat)
3. **Task 3: Add CI compile-out-clean step + fix deprecated HEEx syntax** - `423194e` (feat)

## Files Created/Modified

- `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs` — NEW: sentinel migration; `up/0` uses `CREATE SCHEMA IF NOT EXISTS parapet` (re-runnable); `down/0` non-cascading (fail-closed)
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — EXTENDED: two new top-level smoke tests (schema round-trip and six-table existence)
- `.github/workflows/ci.yml` — EXTENDED: one new step `Compile demo (warnings-as-errors, no-optional-deps)` in existing `demo` job
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — BUGFIX: replaced deprecated `<%# %>` EEx comment syntax with `<%!-- --%>` HEEx syntax (Rule 1)

## Decisions Made

- Sentinel migration uses `IF NOT EXISTS` so a re-run or contributor stale DB is safe (idempotent)
- `down/0` is non-cascading: `DROP SCHEMA IF EXISTS parapet` without CASCADE raises `2BP01` if spine tables still exist, preventing silent data loss; user must roll back spine migrations first
- New CI compile step placed after `mix deps.get` (reuses warm `_build` cache) and before `mix ecto.create` (compile does not need the DB)
- Both smoke tests use `Parapet.Evidence.schema_prefix()` (never literal `"parapet"`) — leg-agnostic so they remain correct if the demo ever runs under a nil-prefix leg
- Six-table query uses `schema_prefix() || "public"` nil-guard for correctness under the public leg

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed deprecated `<%# %>` EEx comment syntax in operator_components.ex**
- **Found during:** Task 3 (demo compile-out-clean step verification)
- **Issue:** `operator_components.ex` lines 1428 and 1442 used deprecated `<%# D-07: ... %>` and `<%# D-08: ... %>` EEx comment syntax that triggers warnings under `--warnings-as-errors`, causing `mix compile --no-optional-deps --warnings-as-errors` to fail before any new CI step was added
- **Fix:** Replaced both `<%# ... %>` with `<%!-- ... --%>` (correct HEEx comment syntax) — two-character changes to comment delimiters only, no semantic change
- **Files modified:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`
- **Verification:** `mix compile --no-optional-deps --warnings-as-errors` exits clean after fix
- **Committed in:** `423194e` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Auto-fix was necessary for the CI compile step to pass. No scope creep — existing deprecated syntax was a pre-existing defect directly blocking Task 3's acceptance criteria.

## Issues Encountered

- Local test DB had stale migration state (schema_migrations recorded but `parapet` schema missing): required explicit `MIX_ENV=test mix ecto.drop && mix ecto.create && mix ecto.migrate` to reset. CI runs fresh DB each time so this only affects local development; the sentinel migration correctly resolves this for all future contributors.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes at trust boundaries introduced. The `information_schema` query uses parameterized `$1` binding as required by T-55-01 disposition `mitigate`.

## Known Stubs

None — all deliverables are fully wired. The smoke test assertions target live DB state via `DemoApp.Repo`.

## Next Phase Readiness

- SAFE-03 satisfied: sentinel migration + round-trip assertion + six-table existence + compile-out-clean all passing
- Plan 55-02 (upgrade-1.x.md docs) can proceed independently; it does not depend on this plan's DB changes
- Pre-existing Phase 49 RED test (`GALLERY-02 script: capture_operator_ui_screenshots.sh covers /parapet/_gallery 4 times`) remains red — unrelated to Phase 55 scope, tracked separately

## Self-Check: PASSED

- `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs`: FOUND
- `examples/demo_app/test/demo_app/operator_smoke_test.exs`: FOUND (extended)
- `.github/workflows/ci.yml`: FOUND (extended)
- `c5e7730`: FOUND
- `bbc4f30`: FOUND
- `423194e`: FOUND

---
*Phase: 55-demo-app-upgrade-docs*
*Completed: 2026-07-01*
