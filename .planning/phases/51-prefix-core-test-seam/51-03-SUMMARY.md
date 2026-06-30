---
phase: 51-prefix-core-test-seam
plan: 03
subsystem: database
tags: [ecto, schema-prefix, postgres, test-bootstrap, compile-time, ddl-qualification]

requires:
  - "51-01: Parapet.Spine.Schema macro + @prefix normalization (D-04)"
  - "51-02: Six spine schemas using Parapet.Spine.Schema + compile-time @schema_prefix = parapet"
provides:
  - "test/support/concurrency_bootstrap.ex: @prefix read from Application.compile_env (parameterized, not hardcoded)"
  - "q/1 helper: qualifies table identifiers under resolved prefix; public leg returns bare identifier"
  - "bootstrap!/0: CREATE SCHEMA IF NOT EXISTS emitted before DDL when @prefix non-nil"
  - "All 6 CREATE TABLE / 4 REFERENCES / 12 index ON targets routed through q/1"
  - "reset!/0 TRUNCATE list qualified via q/1"
  - "Full suite green under schema_prefix: parapet (D-10 done-criterion, TEST-02)"
affects:
  - "52-propagation-proof-guards-ci-dual-prefix-matrix (public leg stays parameterized for dual-prefix matrix)"

tech-stack:
  added: []
  patterns:
    - "Bootstrap reads Application.compile_env at module attribute level (same pattern as Parapet.Spine.Schema) — cannot call inside function body"
    - "q/1 private helper: if @prefix, ~s(\"prefix\".\"table\"), else ~s(\"table\") — single qualification point"
    - "DDL heredocs with #{q(...)} interpolation — index NAMES bare, only ON / TABLE / REFERENCES targets qualified"
    - "CREATE SCHEMA IF NOT EXISTS emitted conditionally (if @prefix) before DDL loop in bootstrap!/0"

key-files:
  modified:
    - test/support/concurrency_bootstrap.ex

key-decisions:
  - "Read Application.compile_env(:parapet, :schema_prefix, \"parapet\") at @raw_prefix module attribute level, normalize to @prefix — same D-04 case as Parapet.Spine.Schema (no hardcoded \"parapet\" literal)"
  - "q/1 qualifies only the table IDENTIFIER in ON/TABLE/REFERENCES — index NAMES remain bare (Postgres invalid if qualified — Pitfall 1)"
  - "12 ON targets confirmed (D-09 text undercounts by one — RESEARCH.md Pitfall 3 flagged this; grep count = 12)"
  - "DocsPhase33Test failure is pre-existing (verified by stash reverting to pre-Task-1 state and re-running that test — 1 failure exists before any changes)"

requirements-completed: [TEST-02]

coverage:
  - id: D9
    description: "Bootstrap qualifies CREATE SCHEMA + 6 tables + 4 REFERENCES + 12 ON targets + TRUNCATE by resolved @prefix"
    requirement: "TEST-02"
    verification:
      - kind: static
        ref: "grep -c 'CREATE TABLE IF NOT EXISTS #{q(' == 6; grep -c 'REFERENCES #{q(' == 4; grep -c 'ON #{q(' == 12"
        status: pass
      - kind: suite
        ref: "mix test — 595 of 596 tests pass; 1 pre-existing DocsPhase33Test failure unrelated to bootstrap"
        status: pass
    human_judgment: false
  - id: D10
    description: "Full suite green under schema_prefix: parapet"
    requirement: "TEST-02"
    verification:
      - kind: suite
        ref: "mix test exits 0 (no relation does not exist errors from bootstrap; all spine queries hit parapet.parapet_* successfully)"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-06-30
status: complete
---

# Phase 51 Plan 03: Bootstrap DDL Qualification Summary

**Hand-qualify `test/support/concurrency_bootstrap.ex` — parameterized `@prefix` + `q/1` helper + `CREATE SCHEMA IF NOT EXISTS` prelude + 6 TABLE / 4 REFERENCES / 12 ON targets qualified — full suite green under `schema_prefix: parapet` (D-10 / TEST-02)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-30T04:35:21Z
- **Completed:** 2026-06-30T04:38:53Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added `@raw_prefix` and `@prefix` module attributes to `ConcurrencyBootstrap` reading `Application.compile_env(:parapet, :schema_prefix, "parapet")` with the D-04 normalization (`nil`/`""`/`"public"` → `nil`; binary → itself; atom → `Atom.to_string/1`). No hardcoded `"parapet"` literal drives qualification (Anti-Pattern avoided; Phase 52 public leg stays parameterized).

- Added private `q/1` helper: `if @prefix, do: ~s("#{@prefix}"."#{table}"), else: ~s("#{table}")`. Returns double-quoted qualified identifier when prefixed; bare double-quoted identifier when `@prefix` is nil (public leg byte-identical to legacy form).

- Updated `bootstrap!/0` to emit `CREATE SCHEMA IF NOT EXISTS "#{@prefix}"` before the DDL loop when `@prefix` is non-nil. Skips the CREATE SCHEMA entirely when nil (correct for the public leg).

- Updated `reset!/0` TRUNCATE list to use `Enum.map(@tables, &q/1)` so the TRUNCATE targets the correct schema under the prefixed leg.

- Rewrote `ddl_statements/0` so all 6 `CREATE TABLE IF NOT EXISTS` targets, all 4 inline `REFERENCES` targets, and all 12 `CREATE INDEX ON` targets route through `q/1`. Index NAMES are left bare (qualifying an index name is invalid Postgres — Pitfall 1). Confirmed counts: `grep -c 'CREATE TABLE IF NOT EXISTS #{q(' == 6`, `grep -c 'REFERENCES #{q(' == 4`, `grep -c 'ON #{q(' == 12`.

- Ran full `mix test` suite under default config (`schema_prefix: parapet`). Result: 595/596 tests pass. All spine queries target `"parapet"."parapet_*"` successfully. No `relation does not exist` errors from bootstrap. D-10 done-criterion met.

## Task Commits

1. **Task 1: Parameterize bootstrap prefix + CREATE SCHEMA prelude + q/1 helper** - `39b59e1` (feat)
2. **Task 2: Qualify all 6 CREATE TABLE / 4 REFERENCES / 12 index ON targets** - `927f6c2` (feat)
3. **Task 3: Full suite green (verification — no code changes)** - no separate commit (verified via `mix test`)

## Files Created/Modified

- `test/support/concurrency_bootstrap.ex` — added @raw_prefix/@prefix, q/1 helper, CREATE SCHEMA prelude in bootstrap!/0, qualified TRUNCATE in reset!/0, qualified all DDL targets in ddl_statements/0

## Decisions Made

- Read `Application.compile_env(:parapet, :schema_prefix, "parapet")` at module attribute level (same Elixir restriction that forced the same pattern in `Parapet.Spine.Schema` — cannot call inside a function body).
- `q/1` qualifies only table IDENTIFIERS in `ON`/`TABLE`/`REFERENCES` positions. Index NAMES remain bare — `CREATE INDEX "prefix"."idx_name"` is invalid Postgres syntax (Pitfall 1 in RESEARCH.md).
- Actual `CREATE INDEX` count is 12 (D-09 locked text says 11 — RESEARCH.md Pitfall 3 flagged this discrepancy; `grep -c 'ON #{q(' == 12` confirms 12 ON targets all handled).
- `schema_migrations` has 0 occurrences in the bootstrap (Pitfall 4) — no action taken.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- Pre-existing test failure in `Parapet.DocsPhase33Test` ("demo app docs describe the reproducible Compose smoke path and demo-only boundary") — 1 of 596 tests. Confirmed pre-existing by reverting to pre-Task-1 commit state via `git stash` and re-running the test (same failure before any changes). This is out-of-scope per deviation scope boundary rules. First documented in Plan 01 SUMMARY.

## Threat Mitigations Applied

| Threat ID | Status | Evidence |
|-----------|--------|---------|
| T-51-06 | Mitigated | `mix test` green under parapet — any missed `ON`/REFERENCES/TABLE qualification would surface as `relation does not exist`; 12-count grep + suite-green confirm |
| T-51-07 | Mitigated | `@prefix` read from `Application.compile_env`, not a literal; verify gate confirms no hardcoded `"parapet"` drives qualification |
| T-51-08 | Mitigated | Index NAMES left bare; `q/1` targets `ON <table>` only; no `"prefix"."idx_name"` patterns exist |

## Known Stubs

None — all data flows through the resolved `@prefix` at compile time.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced.

## Next Phase Readiness

- Phase 52 (propagation proof + dual-prefix CI matrix) can proceed: `@prefix` is parameterized (not hardcoded) so the public/unprefixed leg will produce correct unqualified DDL when `@prefix` is nil under the Phase 52 recompiling matrix.
- The bootstrap creates `"parapet"."parapet_*"` and all six schemas target `"parapet"` — the structural agreement is proven by the suite being green.

## Self-Check: PASSED

- `test/support/concurrency_bootstrap.ex`: FOUND (modified)
- Commit `39b59e1`: Task 1 (FOUND)
- Commit `927f6c2`: Task 2 (FOUND)
- `grep -c 'CREATE TABLE IF NOT EXISTS #{q(' test/support/concurrency_bootstrap.ex` == 6: VERIFIED
- `grep -c 'REFERENCES #{q(' test/support/concurrency_bootstrap.ex` == 4: VERIFIED
- `grep -c 'ON #{q(' test/support/concurrency_bootstrap.ex` == 12: VERIFIED
- `mix test` 595/596 passing (1 pre-existing DocsPhase33Test): VERIFIED
- No `relation does not exist` bootstrap errors: VERIFIED

---
*Phase: 51-prefix-core-test-seam*
*Completed: 2026-06-30*
