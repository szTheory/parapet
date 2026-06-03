---
phase: 23-foundations-telemetry-contract-lease-until-migration
verified: 2026-05-27T00:00:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification: false
gaps: []
deferred: []
human_verification: []
---

# Phase 23: Foundations — Telemetry Contract + `lease_until` Migration — Verification Report

**Phase Goal:** Lock the v1.1 telemetry event family under the Experimental stability tier and add the `lease_until` claim-lease column to `parapet_action_claims` before any capability code ships — both decisions are irreversible-on-publish under the v1.0 freeze.
**Verified:** 2026-05-27
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Running `mix ecto.migrate` on a database that already has `parapet_action_claims` rows succeeds and backfills `lease_until` with a sensible default so no operator-claim ordering breaks. | VERIFIED | `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` (`:unboxed`, `@migration_version 20_260_528_010_000`) exercises `Ecto.Migrator.up/4` against a real DB with a pre-existing row inserted without `lease_until`, then asserts `diff_seconds == 300` (5 minutes). The migration SQL is `UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'` in `def change`. The `:from` option (`modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}`) ensures rollback works. This automated integration test fulfills SC-1 as confirmed automation (replacing the original `checkpoint:human-verify`). |
| 2 | `docs/telemetry.md` enumerates the full `[:parapet, :operator, :recovery_action, ...]` event family under the Experimental stability tier — every event name, measurement key, and metadata key is explicit and distinguishable from the v1.0 frozen Stable telemetry. | VERIFIED | Section `## Recovery Action Family (Experimental)` exists at line 138 of `docs/telemetry.md`. The Stable header at lines 1-10 is untouched. All 8 event tuples are enumerated: `:previewed`, `:preview_failed`, `:confirmed`, `:short_circuited`, `:conflicted`, and the `:executed` span family's three sub-events (`:start`, `:stop`, `:exception`). Every subsection has explicit measurements and metadata keys. Closed vocabularies are enumerated in a dedicated `### Closed Vocabularies` subsection. `duration_ms` / `duration_native` convention is documented inline for the span family. |
| 3 | `ClaimService.claim_action/1` self-heals an expired-lease row atomically (`UPDATE ... WHERE lease_until < now() RETURNING *`), proven by a concurrency test that wins a claim against a stale claim left behind by a simulated node crash. | VERIFIED | `defp steal_expired_claim/2` in `claim_service.ex` (lines 109-140) issues a single `repo.update_all(steal_query, [])` where `steal_query` is an Ecto `from` with `where: ... claim.lease_until < ^now` and `select: claim` (the Ecto equivalent of `RETURNING *`). No `SELECT FOR UPDATE`. The `acquire_claim/2` tries `steal_expired_claim/2` before falling through to `{:conflicted, claim}`. The `@tag :unboxed` test "self-heals an expired-lease stale claim left by a crashed node" (lines 139-179 of `claim_service_test.exs`) inserts a stale claim with `lease_until: past`, calls `ClaimService.claim_action/1`, and asserts: `{:won, claim}`, `claim.id == original.id`, `claim.attempt_count == 2`, new idempotency_key, `DateTime.compare(claim.lease_until, DateTime.utc_now()) == :gt`. No concurrent tasks — sequential per D-08. |
| 4 | A future capability addition can wire a new emit-site to a documented telemetry event without inventing a new event name. | VERIFIED | `Parapet.Telemetry.RecoveryAction.event_families/0` returns the exact 8-element frozen list. `shape_metadata/2` accepts family atom or full event tuple and produces contract-conformant payloads. `normalize_outcome/1`, `normalize_short_circuit_reason/1`, `normalize_failure_class/1`, `normalize_actor_kind/1`, `normalize_action_kind/1` enforce closed vocabularies. The module is documented in `docs/telemetry.md` and listed in `docs/stability.md` Experimental table. Phase 26 emit-sites need only call `RecoveryAction.shape_metadata/2` with family + raw metadata — no event name invention required. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/parapet/telemetry/recovery_action.ex` | Frozen contract module for the `[:parapet, :operator, :recovery_action, ...]` family under Experimental tier | VERIFIED | 332 lines (exceeds 250 minimum). Contains `@event_families` (8 tuples), `@span_families`, 5 vocab maps, `allowed_public_keys/1`, `shape_metadata/2`, 5 `normalize_*/1` functions. `> #### Experimental {: .warning}` admonition present. `@doc since: "1.1.0"` on all 7 public functions. CR-01 (atom-table exhaustion) fixed: uses `String.to_existing_atom/1` + `:__unknown__` sentinel — `String.to_atom/1` is absent. |
| `test/parapet/telemetry/recovery_action_test.exs` | Module-introspection contract test — 4 required tests + regression tests for CR-01 and WRs | VERIFIED | 12 total tests. `use ExUnit.Case, async: true`. The 4 original tests required by the plan exist verbatim. 8 additional regression tests cover WR-01 (nil/keyword-list refs), WR-02 (malformed event names), and CR-01 (atom-table safety for all 5 `normalize_*/1` helpers and `normalize_ref_key/1`). No `:telemetry.attach`, no `Process.sleep`, no `:telemetry.execute`. |
| `docs/telemetry.md` | New `## Recovery Action Family (Experimental)` section with all 8 events, measurement keys, metadata keys, closed vocabularies | VERIFIED | Section present at line 138. All 9 event name instances in the section (6 headers + 3 sub-event bullets). Experimental admonition present. Closed Vocabularies subsection enumerates all 6 vocab categories. Stable header at lines 1-10 byte-identical (verified `grep -n "Stable Contract"` returns line 3). |
| `docs/stability.md` | New row in Experimental Modules table for `Parapet.Telemetry.RecoveryAction` | VERIFIED | `\| \`Parapet.Telemetry.RecoveryAction\` \| Machine-readable recovery action telemetry contract \|` exists at line 49, between `Parapet.MCP.PrometheusClient` and `Parapet.Automation.CircuitBreaker` per D-14. |
| `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` | Migration: add nullable → backfill → NOT NULL + partial index | VERIFIED | 53 lines. `def change` performs 4 steps in order: `add :lease_until, :utc_datetime_usec, null: true`, `execute(backfill SQL, "")`, `modify :lease_until ... null: false, from: {:utc_datetime_usec, null: true}`, `create index ... where: "status = 'claimed'", name: :parapet_action_claims_lease_until_claimed_index`. No `default:` clause (honoring D-02). `@moduledoc` documents production locking risk (WR-04 fix). |
| `lib/parapet/spine/action_claim.ex` | Schema field `:lease_until`, cast, validate_required | VERIFIED | `field(:lease_until, :utc_datetime_usec)` after `field(:claimed_at, ...)`. `:lease_until` appears in both `cast/3` and `validate_required/2`. No other changes to schema. |
| `lib/parapet/automation/claim_service.ex` | `@default_lease_ms`, `lease_until` in attrs, `steal_expired_claim/2`, `:lease_until` in `returning_fields/0` | VERIFIED | `@default_lease_ms 5 * 60 * 1_000` at line 17. `lease_until: lease_until,` in attrs. `defp steal_expired_claim/2` at line 109 with `repo.update_all(steal_query, [])` where `steal_query` includes `select: claim` (equivalent to `RETURNING *`). `:lease_until` in `returning_fields/0`. No `SELECT FOR UPDATE` in steal path. No `Application.put_env` for lease. |
| `test/support/concurrency_bootstrap.ex` | DDL adds `lease_until timestamp(6) without time zone NOT NULL` + partial index with canonical name | VERIFIED | `lease_until timestamp(6) without time zone NOT NULL,` at line 135 in the `parapet_action_claims` CREATE TABLE block. `CREATE INDEX IF NOT EXISTS parapet_action_claims_lease_until_claimed_index ON parapet_action_claims (lease_until) WHERE status = 'claimed'` present in `ddl_statements/0` list. Index name matches migration exactly. |
| `test/parapet/automation/claim_service_test.exs` | New `@tag :unboxed` test asserting expired-lease self-heal | VERIFIED | Test "self-heals an expired-lease stale claim left by a crashed node" at line 139. `@tag :unboxed` two lines above. All 5 assertions present: `{:won, claim}`, `claim.id == original.id`, `claim.attempt_count == 2`, new idempotency_key, `DateTime.compare(claim.lease_until, ...) == :gt`. No `Task.async`, no `Process.sleep`. |
| `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` | Ecto.Migrator integration test proving SC-1 backfill behavior | VERIFIED | 243 lines. Uses `Ecto.Migrator.up/4` against `MigrationTestRepo` (plain `DBConnection.ConnectionPool`, not Sandbox). Drops `lease_until` column, inserts a row without it, runs migration up, queries `claimed_at` and `lease_until`, asserts `diff_seconds == 300`. Tagged `@tag :unboxed`. Teardown restores NOT NULL and re-creates partial index (WR-05 fix). Uses row-level `DELETE FROM schema_migrations WHERE version = $1` not `DROP TABLE` (WR-06 fix). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/parapet/telemetry/recovery_action.ex` | `mix verify.public_api` gate | `> #### Experimental {: .warning}` admonition matching regex `~r/####\s+Experimental\s*\{:\s*\.warning\}/` | WIRED | Admonition at lines 5-9 of `@moduledoc` exactly matches the required heading shape with 4 hashes and `{: .warning}` on the same line. |
| `test/parapet/telemetry/recovery_action_test.exs` | `lib/parapet/telemetry/recovery_action.ex` | `alias Parapet.Telemetry.RecoveryAction` + 4 required test functions calling `RecoveryAction.event_families/0`, `normalize_*/1`, `shape_metadata/2`, `span_families/0` | WIRED | All introspection calls verified in the test file. |
| `docs/telemetry.md` | `lib/parapet/telemetry/recovery_action.ex` | Recovery Action section enumerates the same 8 events, measurement keys, metadata keys, and vocab atoms the module exposes | WIRED | All 8 event tuples appear in both the module's `@event_families` and in `docs/telemetry.md` subsections. Closed vocabularies match exactly between module attributes and the `### Closed Vocabularies` subsection. |
| `lib/parapet/automation/claim_service.ex` | `lib/parapet/spine/action_claim.ex` | Ecto query against `ActionClaim` schema — `steal_expired_claim/2` uses `from(claim in ActionClaim, ...)` | WIRED | `alias Parapet.Spine.{ActionClaim, Incident}` at line 15. `steal_expired_claim/2` uses `from(claim in ActionClaim, ...)`. `:lease_until` field in schema makes the `update_all` result bind correctly. |
| `lib/parapet/automation/claim_service.ex` | `priv/repo/migrations/20260528010000_...exs` | `attrs` map writes `lease_until: lease_until` into the `NOT NULL` column; partial index on `(lease_until) WHERE status='claimed'` accelerates the `steal_expired_claim/2` WHERE clause | WIRED | `lease_until: lease_until,` in attrs at line 36. Partial index name matches migration name. |
| `test/parapet/automation/claim_service_test.exs` | `test/support/concurrency_bootstrap.ex` | Self-heal test calls `ConcurrencyBootstrap.reset!()` then inserts `%ActionClaim{lease_until: past, ...}` — bootstrap DDL must include the column | WIRED | `ConcurrencyBootstrap.reset!()` is the first call in the self-heal test. `concurrency_bootstrap.ex` DDL includes `lease_until timestamp(6) without time zone NOT NULL` so the insert succeeds. |

### Data-Flow Trace (Level 4)

Not applicable for this phase. All artifacts are contract modules, migrations, schema fields, and service-layer logic — no UI components rendering dynamic data from a store or API route. Data-flow correctness is proven by the concurrency test (self-heal path returns `{:won, claim}` with populated `claim.lease_until`) and the Ecto.Migrator integration test (backfill populates `lease_until` from real SQL execution).

### Behavioral Spot-Checks

The phase delivers no independently runnable CLI entry points or HTTP endpoints that can be exercised without a live database. The test suite is the canonical execution path. The REVIEW.md confirms: "366 tests, 0 failures" after code review fixes were applied, up from 358 pre-review.

Key behavioral correctness is proven by:
- `test/parapet/repo/migrations/add_lease_until_backfill_test.exs`: Real `Ecto.Migrator.up/4` execution proving SC-1
- `test/parapet/automation/claim_service_test.exs` "self-heals an expired-lease stale claim": Real Postgres `UPDATE ... WHERE lease_until < now` execution proving SC-3
- `test/parapet/telemetry/recovery_action_test.exs`: Pure module introspection proving the frozen 8-event list, vocab guards, `shape_metadata/2` behavior, and atom-table safety

| Behavior | Method | Status |
|----------|--------|--------|
| Migration backfills `lease_until = claimed_at + 300s` | `Ecto.Migrator.up/4` in integration test, `assert diff_seconds == 300` | PASS (test-proven) |
| Self-heal returns `{:won, claim}` with `id == original.id` | Unboxed concurrency test with real Postgres | PASS (test-proven) |
| `event_families/0` returns exactly 8 tuples (ordered equality) | `RecoveryAction.event_families() == [... 8-element list ...]` | PASS (test-proven) |
| `normalize_outcome/1` raises ArgumentError, no atom interned | Atom-count stability check with `System.unique_integer` poison strings | PASS (test-proven) |

### Probe Execution

No probes declared in PLAN files. No `scripts/*/tests/probe-*.sh` files exist in this phase. Step 7c: SKIPPED (no probes declared or conventionally present).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FND-01 | 23-02-PLAN.md | `parapet_action_claims` schema migration adds `lease_until` column; existing rows backfilled | SATISFIED | Migration file exists with correct 4-step `def change`. Schema declares `field(:lease_until, :utc_datetime_usec)` with cast/validate_required. `ClaimService` defaults and self-heals. Ecto.Migrator integration test proves backfill. Concurrency test proves self-heal. |
| FND-02 | 23-01-PLAN.md | Telemetry contract for `[:parapet, :operator, :recovery_action, ...]` documented in `docs/telemetry.md` under Experimental tier | SATISFIED | `Parapet.Telemetry.RecoveryAction` module ships with 8 frozen event families, 5 vocab guards, `shape_metadata/2`, Experimental admonition. `docs/telemetry.md` has complete Recovery Action section. `docs/stability.md` has the Experimental Modules table row. |

No orphaned requirements: REQUIREMENTS.md confirms FND-01 and FND-02 are the only Phase 23 requirements. Both are satisfied.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/parapet/automation/claim_service.ex` | 200-201 | Dead code: `defp to_claim(attrs), do: struct(ActionClaim, attrs)` — fallback clause unreachable in current Ecto (REVIEW.md IN-01) | INFO | No functional impact. REVIEW.md marks this as Info, not a blocker. |
| `lib/parapet/telemetry/recovery_action.ex` | 91 | `:start` sub-event's `allowed_public_keys` includes `:outcome` despite docs saying "absent on :start" (REVIEW.md IN-02) | INFO | No functional defect — `shape_metadata` uses `Map.take` which silently ignores missing keys; emitter responsibility documented. Not a blocker. |

No TBD, FIXME, or XXX markers found in any phase-23 modified files.

**Debt-marker gate:** CLEAR — no unreferenced debt markers.

**Code review fixes confirmed:**
- CR-01 (CRITICAL — atom-table exhaustion): FIXED. `String.to_existing_atom/1` + `:__unknown__` sentinel in `normalize_key/1` and `normalize_ref_key/1`. `String.to_atom/1` is absent from `recovery_action.ex`.
- WR-01 (merge_explicit_refs crashes on nil/keyword): FIXED. Clauses for `nil`, `is_list`, and catch-all with `ArgumentError` added.
- WR-02 (family_key crash on malformed list): FIXED. Catch-all clause raises `ArgumentError` naming the offending value.
- WR-03 (ActionClaim changeset tests weakened): FIXED per REVIEW.md `status: fixed`.
- WR-04 (migration locks docs): FIXED. `@moduledoc` contains `ACCESS EXCLUSIVE` and `maintenance window` documentation.
- WR-05 (teardown leaves nullable column): FIXED. Teardown explicitly runs `ALTER COLUMN lease_until SET NOT NULL` after ADD IF NOT EXISTS + backfill.
- WR-06 (DROP TABLE schema_migrations): FIXED. Only `DELETE FROM schema_migrations WHERE version = $1` is used.

### Human Verification Required

None. All four success criteria are verified programmatically:
- SC-1: Automated via `Ecto.Migrator` integration test (`diff_seconds == 300`)
- SC-2: Verified via grep on `docs/telemetry.md`
- SC-3: Verified via `@tag :unboxed` concurrency test in `claim_service_test.exs`
- SC-4: Verified via module introspection in `recovery_action_test.exs`

The original `checkpoint:human-verify` for SC-1 (Task 4 of 23-02-PLAN.md) was converted to an automated `Ecto.Migrator`-driven backfill integration test in `test/parapet/repo/migrations/add_lease_until_backfill_test.exs`. This test programmatically rolls back the migration state, seeds a row via raw SQL, re-applies the migration via `Ecto.Migrator.up/4`, and asserts `lease_until - claimed_at == 300s`. This fulfills SC-1 as automation — the core property (backfill correctness) is machine-verified, and no human judgment is needed for the observable outcome.

### Gaps Summary

No gaps. All four roadmap success criteria are achieved by substantive, wired, and data-flowing artifacts. Both FND-01 and FND-02 requirements are satisfied. The code review cycle closed 1 critical and 6 warning findings; all fixes are confirmed in the codebase. The phase is ready to proceed to Phase 24.

---

_Verified: 2026-05-27_
_Verifier: Claude (gsd-verifier)_
