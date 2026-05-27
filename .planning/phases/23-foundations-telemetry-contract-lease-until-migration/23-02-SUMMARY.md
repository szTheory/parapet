---
phase: 23-foundations-telemetry-contract-lease-until-migration
plan: "02"
subsystem: database
tags: [ecto, postgres, migrations, claim-service, lease, concurrency, ecto-migrator]

# Dependency graph
requires: []
provides:
  - "lease_until :utc_datetime_usec NOT NULL column on parapet_action_claims (migration 20260528010000)"
  - "Ecto schema field :lease_until in ActionClaim with cast + validate_required"
  - "ClaimService.claim_action/1 writes lease_until = now + 5 min on insert"
  - "ClaimService.steal_expired_claim/2: single UPDATE-in-place for expired claims"
  - "partial index parapet_action_claims_lease_until_claimed_index (lease_until) WHERE status='claimed'"
  - "concurrency_bootstrap DDL updated with lease_until column + partial index"
  - "sequential self-heal concurrency test proving UPDATE-in-place semantics"
  - "automated backfill integration test via Ecto.Migrator + MigrationTestRepo"
affects:
  - phase-25-capability-dispatch
  - phase-26-operator-runbook-execution
  - phase-29-adop-02-doctor

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Claim-lease: ClaimService defaults lease_until = now + @default_lease_ms on insert; no Postgres DEFAULT clause (honors :now test-injection opt)"
    - "Self-heal UPDATE-in-place: single UPDATE ... WHERE status='claimed' AND lease_until < now() RETURNING * inside acquire_claim/2 — no SELECT-FOR-UPDATE"
    - "Migration: add-nullable -> execute backfill -> modify NOT NULL with :from (reversibility per Ecto 3.x Finding #2)"
    - "Ecto.Migrator integration test: MigrationTestRepo with DBConnection.ConnectionPool (non-sandbox) so Migrator can acquire multi-connection locks"

key-files:
  created:
    - "priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs"
    - "test/parapet/repo/migrations/add_lease_until_backfill_test.exs"
  modified:
    - "lib/parapet/spine/action_claim.ex"
    - "lib/parapet/automation/claim_service.ex"
    - "test/support/concurrency_bootstrap.ex"
    - "test/parapet/automation/claim_service_test.exs"

key-decisions:
  - "lease_until computed in ClaimService (not Postgres DEFAULT) to preserve :now test-injection opt (D-02)"
  - "@default_lease_ms 5 * 60 * 1_000 is a private module constant — NOT Application-env configurable (D-03)"
  - "Self-heal uses select: claim (not update_all returning: true) — Ecto 3.x deprecates returning on update_all; behavior verified by passing tests"
  - "Task 4 backfill verification automated via Ecto.Migrator + MigrationTestRepo (DBConnection.ConnectionPool) replacing checkpoint:human-verify per user zero-human-verification policy"
  - "MigrationTestRepo uses same parapet_concurrency_test DB as ConcurrencyRepo but plain pool — enables Ecto.Migrator multi-connection locking"
  - "Migration rollback reversibility confirmed: modify with :from option enables mix ecto.rollback without 'cannot reverse migration command'"

patterns-established:
  - "Pattern: Migration backfill test — drop column, insert without it, run Ecto.Migrator.up, assert diff"
  - "Pattern: MigrationTestRepo (local defmodule in test, DBConnection.ConnectionPool) for DDL tests incompatible with sandbox"

requirements-completed: [FND-01]

# Metrics
duration: 85min
completed: 2026-05-27
---

# Phase 23 Plan 02: lease_until Migration + ClaimService Summary

**lease_until column backfill migration, ClaimService expired-claim self-heal (UPDATE-in-place), and automated Ecto.Migrator backfill integration test — FND-01 delivered end-to-end with zero human verification.**

## Performance

- **Duration:** ~85 min (including task 4 automation deviation)
- **Started:** 2026-05-27T12:35:00Z
- **Completed:** 2026-05-27T13:00:00Z
- **Tasks:** 4 (task 4 converted from checkpoint:human-verify to automated test)
- **Files modified:** 6

## Accomplishments

- Migration `20260528010000` adds `lease_until :utc_datetime_usec NOT NULL` via add-nullable → backfill `claimed_at + INTERVAL '5 minutes'` → modify NOT NULL (with `:from` for reversibility); partial index `parapet_action_claims_lease_until_claimed_index` on `(lease_until) WHERE status='claimed'`
- `Parapet.Spine.ActionClaim` schema declares `field(:lease_until, :utc_datetime_usec)` with `:lease_until` in `cast/3` and `validate_required/2`; `concurrency_bootstrap.ex` DDL updated to include the column and partial index
- `ClaimService.claim_action/1` writes `lease_until = now + 5 min` on insert via `@default_lease_ms 5 * 60 * 1_000`; self-heals expired claims via `steal_expired_claim/2` — single atomic `UPDATE ... WHERE status='claimed' AND lease_until < now()` RETURNING, update-in-place preserving the original row id
- Sequential self-heal concurrency test (`:unboxed`) inserted stale claim, called `claim_action/1`, asserted `{:won, claim}` with `claim.id == original.id`, `attempt_count == 2`, new `idempotency_key`, `lease_until > now()`
- Automated backfill test via `Ecto.Migrator.up/4` proves FND-01 Success Criterion #1: pre-existing rows receive `lease_until = claimed_at + 300s` after migration; no human psql step required

## Task Commits

1. **Task 1: Migration + schema field + concurrency_bootstrap DDL** - `b4ee8b8` (feat)
2. **Task 2: ClaimService lease defaulting + expired-claim self-heal** - `ef29a78` (feat)
3. **Task 3: Sequential concurrency test proving expired-lease self-heal** - `cb2df89` (test)
4. **Task 4: Automated backfill verification via Ecto.Migrator** - `ff4d47e` (test)

**Plan metadata:** (this commit, docs)

## Files Created/Modified

- `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` — Single `def change` migration: add nullable, execute backfill SQL, modify NOT NULL with `:from`, create partial index
- `lib/parapet/spine/action_claim.ex` — Added `field(:lease_until, :utc_datetime_usec)` after `claimed_at`; added `:lease_until` to `cast/3` and `validate_required/2`
- `lib/parapet/automation/claim_service.ex` — Added `@default_lease_ms 5 * 60 * 1_000`; compute `lease_until` in `attrs`; `steal_expired_claim/2` UPDATE-in-place branch; `:lease_until` in `returning_fields/0`
- `test/support/concurrency_bootstrap.ex` — Added `lease_until timestamp(6) without time zone NOT NULL` to `parapet_action_claims` DDL; added `parapet_action_claims_lease_until_claimed_index` to `ddl_statements/0`
- `test/parapet/automation/claim_service_test.exs` — New `@tag :unboxed` test "self-heals an expired-lease stale claim left by a crashed node"; fixed two pre-existing tests missing `lease_until` after field became required
- `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` — New Ecto.Migrator integration test; `MigrationTestRepo` with `DBConnection.ConnectionPool`; drops column, inserts row, runs migration, asserts `lease_until - claimed_at == 300s`

## Decisions Made

- `@default_lease_ms` is a private module constant (not Application-env) per D-03 — avoids repeating the v0.10 `Parapet.SLO` Application-env mistake
- Self-heal uses `select: claim` on the update result instead of `update_all(returning: true)` — the latter is deprecated in Ecto 3.x; behavior is verified by passing tests (plan's acceptance grep for `update_all(returning: true)` won't match)
- `MigrationTestRepo` uses `DBConnection.ConnectionPool` (non-sandbox) because `Ecto.Migrator` requires at least two simultaneous connections (one to lock `schema_migrations`, one to execute DDL) — incompatible with `Ecto.Adapters.SQL.Sandbox`
- Migration runs `mix ecto.rollback` cleanly via `modify :lease_until, ..., from: {:utc_datetime_usec, null: true}` — the `:from` option is mandatory for Ecto 3.x `def change` reversibility (Finding #2)
- Claim `returning_fields/0` includes `:lease_until` so the `{:won, claim}` struct from insert-wins path is complete (Pitfall 5); Phase 25 callers can read `claim.lease_until` without nil-handling

## Deviations from Plan

### Plan Changes

**1. [User Direction] Task 4: checkpoint:human-verify → automated Ecto.Migrator integration test**
- **Found during:** Task 4 (prior executor reached checkpoint, user responded "automate this — 0 human verification required")
- **Issue:** Original plan required manual `mix ecto.reset` + psql to verify backfill on seeded rows
- **Fix:** Created `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` using `Ecto.Migrator.up/4` with a local `MigrationTestRepo` (plain connection pool). Test drops `lease_until`, inserts a pre-existing row, runs migration, asserts `diff_seconds == 300`
- **Files modified:** `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` (new)
- **Verification:** `mix test test/parapet/repo/migrations/add_lease_until_backfill_test.exs` passes; second run passes (idempotent)
- **Committed in:** `ff4d47e` (Task 4 commit)
- **Net effect:** FND-01 Success Criterion #1 is now provable by CI — no human psql step

**2. [Ecto 3.x] steal_expired_claim/2 uses select: claim, not update_all(returning: true)**
- **Found during:** Task 2 implementation
- **Issue:** `update_all(returning: true)` emits a deprecation warning in Ecto 3.x; the plan's acceptance grep expects it
- **Fix:** Used `select: claim` in the query to capture the updated row without the deprecated returning option
- **Files modified:** `lib/parapet/automation/claim_service.ex`
- **Verification:** All `claim_service_test.exs` tests pass including self-heal and concurrent-insert tests

**3. [Rule 1 - Bug] Fixed two pre-existing tests missing lease_until after schema field became required**
- **Found during:** Task 3 (running existing tests)
- **Issue:** Two existing `claim_service_test.exs` tests supplied `ActionClaim` structs without `lease_until` — failed changeset validation after Task 1 added `:lease_until` to `validate_required`
- **Fix:** Added `lease_until:` to both test's ActionClaim struct literals
- **Files modified:** `test/parapet/automation/claim_service_test.exs`
- **Verification:** `mix test test/parapet/automation/claim_service_test.exs` exits 0

---

**Total deviations:** 3 (1 user-directed, 1 Ecto 3.x compat, 1 auto-fix Rule 1)
**Impact on plan:** All deviations improve quality or follow user direction. No scope creep.

## Issues Encountered

- `Ecto.Migrator` incompatible with `Ecto.Adapters.SQL.Sandbox` (requires 2+ simultaneous connections; sandbox is single-connection-per-process with ownership). Resolved by defining `MigrationTestRepo` inline in the test module with `pool: DBConnection.ConnectionPool`.
- `Code.require_file/2` needed to load migration module before `Ecto.Migrator` — migration files in `priv/repo/migrations/` are not compiled into test paths by default. Resolved with `Code.require_file("../../../../priv/repo/migrations/...", __DIR__)` at module load time.

## Known Stubs

None — all fields populated, no placeholder data, no wired-to-empty components.

## Threat Flags

None — internal DDL + schema field + service-layer change + test code. No new attack surface. See plan threat_model section.

## Pre-existing Flake (Out of Scope)

`test/mix/tasks/parapet.install_test.exs` raises `Rewrite.Error` when run from the worktree directory (worktree path confuses the Igniter file rewrite path). Passes on `main`. Documented but NOT fixed here per deviation rule scope boundary — pre-existing issue unrelated to this plan's changes.

## Next Phase Readiness

- `parapet_action_claims.lease_until` column, index, schema field, service logic, and all tests are merged-ready
- FND-01 is complete; FND-02 (RecoveryAction telemetry contract) in Plan 23-01 is the sibling plan; both land in one PR per D-17
- Phase 25 (capability dispatch) can read `claim.lease_until` from `{:won, claim}` — field is in `returning_fields/0`, not nil
- Phase 29 (ADOP-02 doctor) is the correct home for lease-aware `mix parapet.doctor` checks — not modified here

---
*Phase: 23-foundations-telemetry-contract-lease-until-migration*
*Completed: 2026-05-27*
