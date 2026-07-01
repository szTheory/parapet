---
phase: 53-generators-library-migrations
plan: "04"
subsystem: database
tags: [ecto, migrations, postgres, schema-prefix, compile-time]

# Dependency graph
requires:
  - phase: 53-01
    provides: "Parapet.Spine.Schema.__prefix__/0 compile-time seam and resolve_prefix/2"
provides:
  - "All 5 library migrations stamped with @prefix Parapet.Spine.Schema.__prefix__()"
  - "All 3 demo migrations stamped with @prefix Parapet.Spine.Schema.__prefix__()"
  - "Raw SQL UPDATE landmine in add_lease_until schema-qualified via @table module attribute"
  - "Both CI-matrix legs (parapet + nil/public) green with same 647/2 test count"
affects: [phase-54, phase-55, upgrade-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Committed migration @prefix pattern: module attribute @prefix Parapet.Spine.Schema.__prefix__() bound at compile time, threaded into all Ecto DDL calls (D-11)"
    - "Raw SQL schema qualification: @table if @prefix, do: ~s(\"prefix\".\"table\"), else: \"table\" for execute/2 calls that cannot take prefix: option (D-11)"

key-files:
  created: []
  modified:
    - priv/repo/migrations/20260511000000_add_runbook_data_to_incidents.exs
    - priv/repo/migrations/20260516233447_add_trace_id_to_incidents.exs
    - priv/repo/migrations/20260517000000_add_parapet_system_events.exs
    - priv/repo/migrations/20260521010000_create_parapet_action_claims.exs
    - priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs
    - examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs
    - examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs
    - examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs

key-decisions:
  - "D-10: Edit committed migrations in place (not additive SET SCHEMA move) — safe because these files only run from-scratch in ephemeral CI/test DBs"
  - "D-11: Bind via __prefix__() (compile-time, leg-aware) not a literal and not resolve_prefix/2 — counterpart to D-01 where generated adopter migrations bake a literal"
  - "D-11 raw SQL: @table module attribute using ~s(\"prefix\".\"table\") pattern for schema-qualification inside execute/2 SQL strings"
  - "D-12: Keep migration timestamps unchanged — renaming breaks add_lease_until_backfill_test version pin"

patterns-established:
  - "Pattern: committed library migrations use @prefix module attr (not inline call) — Pitfall 3 avoidance"
  - "Pattern: references/2 carries its own explicit prefix: @prefix (D-02, not inherited from enclosing create table)"
  - "Pattern: every create index/unique_index carries explicit prefix: @prefix (D-02, indexes never inherit)"
  - "Pattern: raw execute/2 SQL strings use @table = if @prefix, do: ~s(\"prefix\".\"table\"), else: \"bare_table\""

requirements-completed: [GEN-06]

coverage:
  - id: D1
    description: "5 library migrations create/alter tables in parapet schema under prefixed CI leg via @prefix Parapet.Spine.Schema.__prefix__()"
    requirement: GEN-06
    verification:
      - kind: integration
        ref: "PARAPET_SCHEMA_PREFIX=parapet mix test — 647 tests, 2 pre-existing failures unrelated to migrations"
        status: pass
    human_judgment: false
  - id: D2
    description: "3 demo migrations create tables in parapet schema under prefixed CI leg via @prefix Parapet.Spine.Schema.__prefix__()"
    requirement: GEN-06
    verification:
      - kind: integration
        ref: "PARAPET_SCHEMA_PREFIX=parapet mix test — 647 tests, 2 pre-existing failures unrelated to migrations"
        status: pass
    human_judgment: false
  - id: D3
    description: "Nil/public CI leg: @prefix resolves to nil, all 8 migrations byte-equivalent to pre-v1.7 behavior"
    requirement: GEN-06
    verification:
      - kind: integration
        ref: "mix compile --force && mix test (no PARAPET_SCHEMA_PREFIX) — 647 tests, 2 pre-existing failures"
        status: pass
    human_judgment: false
  - id: D4
    description: "Raw SQL UPDATE landmine in add_lease_until schema-qualified via @table module attribute"
    requirement: GEN-06
    verification:
      - kind: integration
        ref: "PARAPET_SCHEMA_PREFIX=parapet mix test — migration executes with parapet.parapet_action_claims"
        status: pass
    human_judgment: false
  - id: D5
    description: "One-time contributor stale-DB reset step documented for Phase 55"
    verification: []
    human_judgment: true
    rationale: "Documentation artifact — no automated test can verify the prose content is present and correct; requires human review before Phase 55 carries it into CHANGELOG/upgrade doc"

# Metrics
duration: 35min
completed: 2026-07-01
status: complete
---

# Phase 53 Plan 04: Committed Migration Prefix Stamps Summary

**All 8 committed Parapet migrations (5 library + 3 demo) stamped with compile-time @prefix Parapet.Spine.Schema.__prefix__(), including schema-qualifying the raw SQL UPDATE landmine in add_lease_until, closing GEN-06**

## Performance

- **Duration:** 35 min
- **Started:** 2026-07-01T15:40:00Z
- **Completed:** 2026-07-01T16:15:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Stamped `@prefix Parapet.Spine.Schema.__prefix__()` into all 5 library migrations — each `alter table`, `create table`, `references/2`, and `create index/unique_index` now carries `prefix: @prefix`
- Stamped `@prefix` into all 3 demo migrations — 5 create tables, 2 references (with explicit per-reference `prefix:`), and 8 indexes in the first; alter + reference + index in the second; create table + reference + 4 indexes in the third
- Defused the raw SQL landmine in `add_lease_until_to_parapet_action_claims.exs`: added `@table if @prefix, do: ~s("parapet"."parapet_action_claims"), else: "parapet_action_claims"` and interpolated `@table` into the `execute/2` UPDATE string
- Both CI-matrix legs verified green: `PARAPET_SCHEMA_PREFIX=parapet mix test` (647 tests, 2 pre-existing failures) and the nil/public leg via `mix compile --force && mix test` (647 tests, same 2 pre-existing failures)

## Task Commits

Each task was committed atomically:

1. **Task 1: Stamp @prefix into the 5 committed library migrations (incl. raw-SQL landmine)** - `872ea25` (feat)
2. **Task 2: Stamp @prefix into the 3 demo migrations** - `46d3805` (feat)
3. **Task 3: Run the full suite under both prefix legs; document one-time contributor stale-DB reset** - (documented in this SUMMARY)

## Files Created/Modified

- `priv/repo/migrations/20260511000000_add_runbook_data_to_incidents.exs` — added `@prefix`, `prefix: @prefix` on `alter table(:parapet_incidents)`
- `priv/repo/migrations/20260516233447_add_trace_id_to_incidents.exs` — added `@prefix`, `prefix: @prefix` on `alter table(:parapet_incidents)`
- `priv/repo/migrations/20260517000000_add_parapet_system_events.exs` — added `@prefix`, `prefix: @prefix` on `create table` and `create index`
- `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` — added `@prefix`, `prefix: @prefix` on `create table`, `references/2` (explicit), and 3 index/unique_index calls
- `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` — added `@prefix`, `@table` module attributes; `prefix: @prefix` on both `alter table` calls and `create index`; interpolated `@table` into raw SQL UPDATE
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` — added `@prefix`; 5 tables + 2 references + 8 indexes all prefixed
- `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` — added `@prefix`; alter table + references + create index all prefixed
- `examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` — added `@prefix`; create table + references + 4 indexes all prefixed

## Decisions Made

- **D-11 binding**: Used `@prefix Parapet.Spine.Schema.__prefix__()` module attribute (compile-time, leg-aware) — not a `"parapet"` literal (would break nil/public leg) and not `resolve_prefix/2` (generate-time, wrong binding time). These files ARE recompiled under the dual-prefix CI matrix.
- **Raw SQL pattern**: Used `@table if @prefix, do: ~s("#{@prefix}"."parapet_action_claims"), else: "parapet_action_claims"` module attribute so the schema qualification happens at compile time and is unconditional — this matches the `concurrency_bootstrap.ex` `q/1` pattern.
- **D-02 compliance**: Each `references/2` call carries its own explicit `prefix: @prefix` rather than relying on inheritance from the enclosing `create table` block.
- **D-12 compliance**: No migration filenames or timestamps were changed.

## Deviations from Plan

None — plan executed exactly as written. All 8 files were edited in place exactly as specified by D-10/D-11. The raw-SQL landmine was handled exactly per Open Question #2 resolution in RESEARCH.md (lines 801-809).

## Issues Encountered

Two pre-existing test failures exist in the suite (not caused by this plan's changes):
1. `Parapet.Telemetry.RecoveryActionTest` — atom table leak test (pre-existing, unrelated to migrations)
2. `Parapet.DocsPhase33Test` — README assertion for `"make up-auto"` string (pre-existing docs drift)

Both failures existed before this plan's first commit (`cffd5bb`) and appear identically under both the `parapet` prefix leg and the nil/public leg. Neither is related to schema prefix or migration behavior.

## One-Time Contributor Stale-DB Reset (D-12 — for Phase 55)

> **Carry this verbatim into CHANGELOG/PR body and `docs/upgrade-1.x.md` in Phase 55.**

Contributors and adopters who have already migrated a local development database before the v1.7 GEN-06 commits will have Parapet's spine tables in the `public` schema. Because the migration files were edited in place (D-10) rather than given new timestamps, Ecto's migrator will not re-run them on a DB that already records them as applied.

**One-time reset steps for contributors:**

```bash
# 1. Reset the demo app DB (drops + recreates from scratch):
cd examples/demo_app
mix demo.reset

# 2. Drop the library concurrency-test DB (it will be recreated by the test suite):
mix ecto.drop --repo Parapet.TestSupport.ConcurrencyRepo

# 3. Run the full suite to confirm a clean state:
PARAPET_SCHEMA_PREFIX=parapet mix test
```

After these steps, all Parapet spine tables will be created in the `parapet` schema (or remain in `public` if `PARAPET_SCHEMA_PREFIX` is unset/nil).

**Why this is necessary:** The in-place edit approach (D-10) is safe for CI (always runs from-scratch) but requires this one-time manual reset for contributors with persistent dev DBs. Adopters are not affected (they do not run `Parapet.Repo` migrations directly).

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond what the plan's threat model covers. The `@table` interpolation in the raw SQL UPDATE uses a compile-time module attribute that flows through `__prefix__()` → `normalize/1` → `safe_ident!/1` allowlist (T-53-04 disposition: mitigate, per plan threat model). No new threat surface introduced.

## Next Phase Readiness

- GEN-06 fully closed: all 8 committed migrations will create Parapet's spine tables under the configured schema prefix
- Both CI-matrix legs green — ready for Phase 54 (`mix parapet.gen.schema.move` SET SCHEMA adopter upgrade path)
- The one-time stale-DB reset step is documented above for Phase 55 to carry into CHANGELOG and upgrade docs

---

## Self-Check: PASSED

**Files exist:**
- `FOUND: priv/repo/migrations/20260511000000_add_runbook_data_to_incidents.exs` (modified)
- `FOUND: priv/repo/migrations/20260516233447_add_trace_id_to_incidents.exs` (modified)
- `FOUND: priv/repo/migrations/20260517000000_add_parapet_system_events.exs` (modified)
- `FOUND: priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` (modified)
- `FOUND: priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` (modified)
- `FOUND: examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` (modified)
- `FOUND: examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` (modified)
- `FOUND: examples/demo_app/priv/repo/migrations/20260525000002_add_parapet_action_claims.exs` (modified)

**Commits exist:**
- `FOUND: 872ea25` — feat(53-04): stamp @prefix into 5 committed library migrations (GEN-06)
- `FOUND: 46d3805` — feat(53-04): stamp @prefix into 3 demo migrations (GEN-06)

**Verification:**
- `grep -L 'Parapet.Spine.Schema.__prefix__'` over all 8 migration files returned nothing (all bound)
- No literal `prefix: "parapet"` and no `resolve_prefix` in any of the 8 files
- Both CI-matrix legs: 647 tests, 2 pre-existing failures (unrelated to this plan)

---
*Phase: 53-generators-library-migrations*
*Completed: 2026-07-01*
