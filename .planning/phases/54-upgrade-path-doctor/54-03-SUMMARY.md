---
phase: 54-upgrade-path-doctor
plan: "03"
subsystem: database
tags: [ecto, postgres, schema-isolation, migration, round-trip-test, upgrade-path]

requires:
  - phase: 54-02
    provides: committed fixture at priv/repo/migrations/20260701000000_move_parapet_spine_to_schema.exs

provides:
  - test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs — Track B up/down round-trip + abort leg (UPG-04, UPG-03)

affects:
  - 54-04 (UPG-05 fitness function scans source; round-trip proof is the complementary DB-level gate)
  - 55-demo-app-upgrade-docs (round-trip test is the evidence surface for Track B upgrade prose)

tech-stack:
  added: []
  patterns:
    - "Dedicated throwaway DB via Ecto.Adapters.Postgres.storage_up/1 + storage_down/1 — isolated from shared parapet_concurrency_test (D-14, Pitfall 4)"
    - "All six bare public DDL fixture tables (not ConcurrencyBootstrap.q/1) — byte-identical on both CI legs (D-15, Pitfall 1)"
    - "Code.require_file of committed Plan 02 fixture — anti-drift contract between golden test and round-trip test (D-13, Pitfall 5)"
    - "Postgrex.Error raised by Ecto.Migrator.up when PL/pgSQL RAISE EXCEPTION fires — use assert_raise Postgrex.Error, not RuntimeError (D-10 abort leg)"

key-files:
  created:
    - test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs
  modified: []

key-decisions:
  - "Fixture must create all six spine tables — the committed migration's DO-block FOREACH checks all six by name; a two-table fixture causes the abort guard to fire on parapet_action_items (first in the array) during the round-trip test, not just the abort leg"
  - "Ecto.Migrator wraps PL/pgSQL RAISE EXCEPTION as Postgrex.Error, not RuntimeError — assert_raise Postgrex.Error is the correct abort-leg pattern"
  - "Bare public DDL for the fixture (not routed through ConcurrencyBootstrap.q/1) so the test runs byte-identically under PARAPET_SCHEMA_PREFIX=parapet and ='' (D-15)"

requirements-completed: [UPG-04, UPG-03]

duration: 3min
completed: 2026-07-01
status: complete
---

# Phase 54 Plan 03: Track B Round-Trip DB Test Summary

**Dedicated-throwaway-DB round-trip test for the committed `MoveParapetSpineToSchema` migration: all six fixture tables in `public` → up → `parapet` (FK cascade + partial index intact) → down → `public` (schema empty, not dropped); abort leg raises on a missing table and moves nothing (UPG-04, UPG-03)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-01T18:38:54Z
- **Completed:** 2026-07-01T18:41:54Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` as an `:unboxed` round-trip test cloned from `add_lease_until_backfill_test.exs`
- Implements a dedicated throwaway DB `parapet_schema_move_roundtrip_test` via `Ecto.Adapters.Postgres.storage_up/1`/`storage_down/1` (D-14) — completely isolated from the shared `parapet_concurrency_test`; a whole-schema move abort cannot contaminate other `:unboxed` modules
- Builds all six fixture spine tables in bare `public` DDL (D-15, Pitfall 1) — not routed through `ConcurrencyBootstrap.q/1`; the migration itself uses literal `public.<t>` names so the fixture runs byte-identically under both CI legs
- `Code.require_file` loads the committed Plan 02 fixture `20260701000000_move_parapet_spine_to_schema.exs` (D-13) — golden test and round-trip test share exactly one fixture file; they cannot drift
- Round-trip test (Test 1) asserts all four D-16 dimensions: (a) all six tables move to `parapet` via `pg_class`+`pg_namespace` catalog queries; (b) FK cascade BEHAVIOR — insert parent+child, delete parent, assert child row gone; (c) partial index `parapet_action_claims_lease_until_claimed_index` exists under `parapet` with `pg_get_expr(indpred,…)` rendering the `status = 'claimed'` predicate; (d) after DOWN all six back in `public`, `parapet` schema exists but empty (deliberate no-DROP-SCHEMA, D-08)
- Abort leg test (Test 2) drops `parapet_action_claims` before UP, asserts `Ecto.Migrator.up` raises `Postgrex.Error` (the PL/pgSQL RAISE EXCEPTION path, D-10), surviving tables remain in `public`, migration version not recorded in `schema_migrations`

## Task Commits

1. **Task 1: Round-trip up/down DB test (throwaway DB, isolated public fixture)** — `4560ce2` (feat)

## Files Created/Modified

- `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` — `:unboxed` round-trip test (467 lines)

## Decisions Made

- All six spine tables required in fixture: the committed migration's DO-block FOREACH checks all six tables by name (`parapet_action_items` is first in the array); a minimal two-table fixture would cause the abort guard to fire on the first missing table during Test 1 (the round-trip test, not the abort leg). Creating all six satisfies the abort guard and lets the migration proceed.
- `assert_raise Postgrex.Error` for the abort leg: `Ecto.Migrator.up` wraps the PL/pgSQL `RAISE EXCEPTION` inside a `Postgrex.Error`, not a `RuntimeError`. Using `RuntimeError` in the abort test caused the test to fail with "expected RuntimeError but got Postgrex.Error".

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixture must create all six spine tables, not just two**
- **Found during:** Task 1 (first test run)
- **Issue:** The plan describes a "minimal 2-table variant" (parapet_incidents + parapet_action_claims) for the fixture. However, the committed migration's DO-block FOREACH checks all six spine tables; a two-table fixture caused the abort guard to raise `Parapet spine table public.parapet_action_items not found` even during the round-trip test (Test 1), not just the abort leg (Test 2).
- **Fix:** Extended `create_public_fixture_spine!/1` to create all six tables in bare `public` DDL: `parapet_incidents` (parent), `parapet_action_items` (stub), `parapet_timeline_entries` (FK → incidents CASCADE), `parapet_tool_audits` (FK → timeline_entries CASCADE), `parapet_system_events` (standalone), `parapet_action_claims` (FK → incidents CASCADE + partial index). The two-table FK/partial-index pair remains the load-bearing part for D-16b/D-16c; the other four are minimal stubs satisfying the six-table abort guard.
- **Files modified:** `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs`
- **Verification:** Both tests pass (2/2 green)
- **Committed in:** `4560ce2`

**2. [Rule 1 - Bug] Abort leg must use `assert_raise Postgrex.Error`, not `RuntimeError`**
- **Found during:** Task 1 (first test run, abort leg)
- **Issue:** Used `assert_raise RuntimeError` for the abort leg. `Ecto.Migrator.up` wraps PL/pgSQL `RAISE EXCEPTION` inside a `Postgrex.Error`, not a `RuntimeError`. The test failed with "Expected exception RuntimeError but got Postgrex.Error".
- **Fix:** Changed `assert_raise RuntimeError` to `assert_raise Postgrex.Error` to match the actual exception type Ecto surfaces.
- **Files modified:** `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs`
- **Verification:** Abort leg passes (D-10 correctly exercised)
- **Committed in:** `4560ce2`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs — fixture scope + exception type corrections)
**Impact on plan:** Both fixes were test-construction corrections; the migration behavior is unchanged. The round-trip proof is now correct and comprehensive.

## Issues Encountered

None beyond the two auto-fixed bugs documented above.

## Known Stubs

None — the round-trip test is fully wired; no placeholder or TODO values remain.

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The test creates and destroys an ephemeral Postgres database on the local test server; it cannot affect production data.

| Threat | Mitigation Implemented |
|--------|------------------------|
| T-54-08: round-trip test poisoning shared state | Dedicated `parapet_schema_move_roundtrip_test` DB via `storage_up`/`storage_down`; `on_exit` nukes the entire DB — no possibility of leaving a half-moved spine in `parapet_concurrency_test` |
| T-54-09: fixture DDL routed through prefix-aware qualifier | Fixture is bare `public` DDL (six hand-written CREATE TABLE statements); `ConcurrencyBootstrap.q/1` is never called — byte-identical on both CI legs |

## Next Phase Readiness

- Plan 04 (Track A pin + UPG-05 fitness function) is complete (already executed in wave 1)
- Phase 54 is now fully complete — all four plans delivered

---
## Self-Check: PASSED

All files confirmed present on disk. Task commit `4560ce2` confirmed in git history.

*Phase: 54-upgrade-path-doctor*
*Completed: 2026-07-01*
