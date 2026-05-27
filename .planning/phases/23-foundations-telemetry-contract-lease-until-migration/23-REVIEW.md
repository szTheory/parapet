---
phase: 23-foundations-telemetry-contract-lease-until-migration
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - lib/parapet/telemetry/recovery_action.ex
  - test/parapet/telemetry/recovery_action_test.exs
  - docs/telemetry.md
  - docs/stability.md
  - priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs
  - test/parapet/repo/migrations/add_lease_until_backfill_test.exs
  - lib/parapet/spine/action_claim.ex
  - lib/parapet/automation/claim_service.ex
  - test/support/concurrency_bootstrap.ex
  - test/parapet/automation/claim_service_test.exs
  - test/parapet/concurrency_bootstrap_test.exs
  - test/parapet/spine/action_claim_test.exs
findings:
  critical: 1
  warning: 6
  info: 4
  total: 11
status: fixed
---

# Phase 23: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Phase 23 ships two foundations: (FND-01) `lease_until` column + ClaimService self-heal for crashed-node claims, and (FND-02) the `Parapet.Telemetry.RecoveryAction` machine-readable contract. The claim-stealing logic is correct under contention (Postgres MVCC row locking serializes concurrent UPDATEs against the same row), and the migration backfill is proven by a dedicated `Ecto.Migrator`-driven integration test. The telemetry contract module exposes the eight frozen event families with closed vocabularies.

**However, one Critical security defect exists**: every normalization path that accepts a binary string (`outcome`, `short_circuit_reason`, `failure_class`, `actor_kind`, `action_kind`, and `refs` keys) calls `String.to_atom/1` **before** validating against the closed vocabulary. Since `Parapet.Telemetry.RecoveryAction` is documented as a public adopter-facing contract — adopters will call `shape_metadata/2` on metadata that originates from operator UI input, webhooks, or upstream HTTP payloads — this is a classic Erlang atom-table-exhaustion vector. Atoms are never garbage collected, so an attacker (or a buggy upstream) who supplies attacker-controlled strings can permanently consume the atom table and eventually crash the BEAM. Several robustness issues (non-map `refs` crashes, weakened ActionClaim changeset tests, public-API FunctionClauseError on malformed event lists) round out the findings.

## Critical Issues

### CR-01: Atom-table exhaustion in `RecoveryAction` normalization helpers (public contract surface)

**File:** `lib/parapet/telemetry/recovery_action.ex:241-284`
**Issue:** All five `normalize_*/1` helpers and `normalize_ref_key/1` accept binary strings and unconditionally call `String.to_atom/1` (via `normalize_key/1` at line 254 and directly at line 283) **before** consulting the closed-vocabulary map.

```elixir
defp normalize_key(value) when is_binary(value), do: value |> String.trim() |> String.to_atom()

defp normalize_enum(value, mapping, label) do
  key = normalize_key(value)         # <-- atom created here, BEFORE validation
  case Map.fetch(mapping, key) do
    {:ok, normalized} -> normalized
    :error -> raise ArgumentError, "Unsupported #{label}: #{inspect(value)}"
  end
end
```

Even when the input is invalid and the function raises, the atom has already been interned. Atoms are not garbage-collected and the BEAM atom table is capped (~1,048,576 by default). The module is documented in `docs/stability.md:49` as the public adopter-facing telemetry contract and in `lib/parapet/telemetry/recovery_action.ex:128-138` as the canonical helper to "shape" raw metadata. Adopters will route operator-UI, webhook, and HTTP payload values through these helpers — exactly the surface a malicious or buggy upstream can poison with unbounded unique strings (e.g., `outcome: "evil-#{i}"` in a tight loop).

The same flaw applies to `normalize_ref_key/1` on line 280-284 (called from `merge_explicit_refs/2`, which accepts arbitrary keys from `metadata[:refs]`).

**Fix:** Use `String.to_existing_atom/1` and let the rescue/case convert into the documented `ArgumentError`:

```elixir
defp normalize_key(value) when is_atom(value), do: value

defp normalize_key(value) when is_binary(value) do
  String.to_existing_atom(String.trim(value))
rescue
  ArgumentError -> :__unknown__
end

defp normalize_enum(value, mapping, label) do
  key = normalize_key(value)

  case Map.fetch(mapping, key) do
    {:ok, normalized} -> normalized
    :error -> raise ArgumentError, "Unsupported #{label}: #{inspect(value)}"
  end
end

defp normalize_ref_key(key) when is_atom(key), do: key

defp normalize_ref_key(key) when is_binary(key) do
  String.to_existing_atom(String.trim(key))
rescue
  ArgumentError -> :__unknown__
end
```

The sentinel `:__unknown__` will fail the `Map.fetch` (raising the documented `ArgumentError`) or fail the `in @allowed_ref_keys` check (silently dropped, matching current behavior). All closed-vocabulary atoms (`:succeeded`, `:incident_ref`, etc.) are referenced at module compile-time in `@outcomes`, `@allowed_ref_keys`, etc., so they're guaranteed to exist before any user input reaches the parser.

## Warnings

### WR-01: `shape_metadata/2` crashes with `FunctionClauseError` on non-map `refs`

**File:** `lib/parapet/telemetry/recovery_action.ex:148-157, 265`
**Issue:** `shape_metadata/2` reads `Map.get(metadata, :refs, %{})` and passes the result straight into `merge_explicit_refs/2`, which is guarded by `when is_map(explicit_refs)`. If an adopter passes `refs: nil`, `refs: [{:step_ref, "x"}]` (a keyword list, common in Elixir telemetry handlers), or `refs: "step-9"`, the function clause does not match and the call crashes with an opaque `FunctionClauseError` rather than the polite contract failure the rest of the module advertises.

**Fix:** Add fallback clauses or normalize:

```elixir
defp merge_explicit_refs(refs, explicit_refs) when is_map(explicit_refs) do
  # existing impl
end

defp merge_explicit_refs(refs, explicit_refs) when is_list(explicit_refs) do
  merge_explicit_refs(refs, Map.new(explicit_refs))
end

defp merge_explicit_refs(refs, _other), do: refs
```

### WR-02: `family_key/1` crashes on malformed event names (public API surface)

**File:** `lib/parapet/telemetry/recovery_action.ex:117-125, 222-223`
**Issue:** `allowed_public_keys/1` and `shape_metadata/2` accept "either a full event name list or a family atom" per their docstrings. When passed a list, they funnel through `family_key/1`, which has only two clauses (executed-span 5-tuple, single-shot 4-tuple). Any other shape — including the bare family list `[:previewed]` an adopter might supply, or a typo — yields `FunctionClauseError` with no context.

**Fix:** Either add a clear-error catch-all or document the input contract more narrowly:

```elixir
defp family_key([:parapet, :operator, :recovery_action, :executed, _sub]), do: :executed
defp family_key([:parapet, :operator, :recovery_action, family]) when is_atom(family), do: family
defp family_key(other) do
  raise ArgumentError,
    "Unsupported recovery_action event name: #{inspect(other)}. " <>
      "Expected one of #{inspect(Parapet.Telemetry.RecoveryAction.event_families())}."
end
```

### WR-03: ActionClaim changeset tests no longer assert what they claim — lease_until errors mask the intended assertion

**File:** `test/parapet/spine/action_claim_test.exs:26-56`
**Issue:** Both negative-path tests ("rejects unsupported status values" and "requires a positive attempt count") omit `lease_until` from the changeset attrs. Now that `validate_required([..., :lease_until])` was added to the schema (`lib/parapet/spine/action_claim.ex:74`), every one of those changesets is invalid for **two** reasons — the assertion being tested AND the missing lease_until — and the tests pass via `refute changeset.valid?` only because of the unrelated missing-lease_until error. If the status / attempt_count validations were silently broken in a future refactor, these tests would still pass, giving false confidence.

**Fix:** Add `lease_until` to the attrs in both tests so they isolate the validation under test:

```elixir
lease_until = DateTime.add(claimed_at, 5 * 60, :second) |> DateTime.truncate(:microsecond)

ActionClaim.changeset(%ActionClaim{}, %{
  # ...existing attrs...
  claimed_at: claimed_at,
  lease_until: lease_until,
  status: "looping"
})
```

### WR-04: Migration runs ADD COLUMN → UPDATE → SET NOT NULL in a single transaction (production downtime risk)

**File:** `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs:4-22`
**Issue:** Ecto migrations run inside an implicit transaction unless `@disable_ddl_transaction true` is set. This migration performs three statements:

1. `ALTER TABLE … ADD COLUMN lease_until` (acquires `ACCESS EXCLUSIVE` briefly)
2. `UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'` — **scans and rewrites every row** while holding the table lock
3. `ALTER TABLE … ALTER COLUMN lease_until SET NOT NULL` — **scans every row again** to validate the constraint, still under the same lock

On a production `parapet_action_claims` table with non-trivial history, this can block every read/write against action_claims for the duration of the scan. The migration is also not annotated as an `:experimental` operational note in CHANGELOG / migration guidance.

**Fix:** For the v1.x adopter rollout, document the locking behavior in CHANGELOG and the experimental-stability callout. For very-large-table safety, the canonical pattern is:
1. ADD COLUMN nullable (cheap)
2. Backfill in batches in a background job (no lock)
3. ALTER COLUMN SET NOT NULL using a CHECK constraint validated separately (Postgres 12+ supports `NOT VALID` + `VALIDATE CONSTRAINT` to avoid the second full-scan lock)

For v1.x adopters with small `parapet_action_claims` tables this is fine, but the migration body should at minimum carry a `@moduledoc` comment noting the table-lock implication.

### WR-05: Migration backfill `on_exit` recreates `lease_until` as NULLABLE, diverging from canonical NOT NULL DDL

**File:** `test/parapet/repo/migrations/add_lease_until_backfill_test.exs:82-87`
**Issue:** The teardown does `ALTER TABLE parapet_action_claims ADD COLUMN IF NOT EXISTS lease_until timestamp(6) without time zone` — without `NOT NULL`. If the test crashes before the migration's `SET NOT NULL` step succeeds, this teardown leaves the column nullable. The next test run that depends on the bootstrap schema (`test/support/concurrency_bootstrap.ex:135` declares `lease_until ... NOT NULL`) won't notice the divergence because `CREATE TABLE IF NOT EXISTS` is a no-op when the table already exists. Subsequent concurrency tests inserting rows without `lease_until` would then succeed instead of failing as expected.

**Fix:** Either drop the column outright on teardown (cleaner — bootstrap recreates it on next suite start), or explicitly restore NOT NULL after backfilling NULLs:

```elixir
Postgrex.query!(conn, "ALTER TABLE parapet_action_claims DROP COLUMN IF EXISTS lease_until", [])
```

This makes the test self-contained and forces the next bootstrap to define the schema canonically.

### WR-06: `on_exit` in migration backfill test issues `DROP TABLE … schema_migrations` — heavy-handed teardown

**File:** `test/parapet/repo/migrations/add_lease_until_backfill_test.exs:115-116`
**Issue:** The teardown drops `schema_migrations` entirely. This is fine *today* because no other test exercises the migration repo against the concurrency database, but it's a fragile invariant — any future test that runs migrations against the same DB and expects `schema_migrations` to persist will be broken non-obviously by the ordering of test modules. The intent is clearly "clean up after this test," but dropping the table is broader than needed; deleting the specific row is already done on line 78.

**Fix:** Remove the `DROP TABLE` and rely on `DELETE FROM schema_migrations WHERE version = $1` (already present at line 77-79). If the goal is to ensure no other migrations leave residue, document that explicitly.

## Info

### IN-01: `to_claim(attrs)` fallback clause is unreachable (dead code)

**File:** `lib/parapet/automation/claim_service.ex:200-201`
**Issue:** `repo.insert_all/3` and `repo.update_all/3` with `:returning` both return Ecto schema structs (not raw attribute maps) in current Ecto versions. The fallback `defp to_claim(attrs), do: struct(ActionClaim, attrs)` only fires if Ecto changes its return shape, in which case `__meta__` would not be loaded properly and downstream code (e.g., `ActionClaim.changeset(claim, ...)` ) might behave incorrectly anyway. Defensive coding is fine, but the comment should clarify what it's defending against — or remove it.

**Fix:** Either delete the dead clause, or add a comment:

```elixir
# Defensive: handles older Ecto versions that returned raw attrs from
# insert_all/update_all when :returning is used. Removable when minimum
# Ecto >= 3.10.
defp to_claim(attrs), do: struct(ActionClaim, attrs)
```

### IN-02: `:start` sub-event accepts `:outcome` metadata despite contract saying "absent on :start"

**File:** `lib/parapet/telemetry/recovery_action.ex:91`, `docs/telemetry.md:239`
**Issue:** The docs state `outcome` is "absent on `:start`", but `@recovery_action_family_keys[:executed]` lists `:outcome` and `:failure_class`. Since the family key is shared across all three span sub-events (`:start`, `:stop`, `:exception`), `shape_metadata` for the `:start` sub-event will pass `:outcome` through if present in the input. This isn't a bug today (Map.take silently ignores missing keys), but it weakens the contract — a caller that *accidentally* sets `outcome: :succeeded` on `:start` will see it preserved in the shaped output.

**Fix (optional)**: Either split `@recovery_action_family_keys` into per-sub-event allowlists (`:executed_start`, `:executed_stop`, `:executed_exception`), or document explicitly that `shape_metadata` doesn't enforce the absence-on-`:start` constraint and the emitter is responsible for not passing `:outcome` on `:start`.

### IN-03: No concurrency test for two callers racing to steal the same expired claim

**File:** `test/parapet/automation/claim_service_test.exs:138-179`
**Issue:** The "self-heals an expired-lease stale claim" test is single-threaded — it doesn't prove that under contention, exactly **one** of N concurrent callers wins the steal and the others see `:conflicted`. The contender test at lines 10-83 exercises only the fresh-claim race, not the steal-expired race. Postgres `UPDATE … WHERE lease_until < now` is correctly serialized by row locking, so the property likely holds, but it's not under test.

**Fix:** Add a parallel-tasks test mirroring the existing contender test (lines 32-66), but with an expired claim pre-inserted, asserting exactly one `{:won, _}` and the rest `{:conflicted, _}`.

### IN-04: `@default_lease_ms` is a magic number duplicated in migration SQL

**File:** `lib/parapet/automation/claim_service.ex:17`, `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs:10`
**Issue:** The 5-minute lease window is encoded in two places: `@default_lease_ms = 5 * 60 * 1_000` (ClaimService) and `INTERVAL '5 minutes'` (migration backfill). If the lease window changes, both must be updated in lockstep. Migration text can't reasonably reference the runtime constant, but the divergence should at minimum be called out in a comment on each side.

**Fix:** Add a comment on both constants referencing the other site:

```elixir
# In claim_service.ex
@default_lease_ms 5 * 60 * 1_000
# NOTE: matches priv/repo/migrations/20260528010000_*.exs backfill ('5 minutes')

# In migration
# NOTE: matches Parapet.Automation.ClaimService.@default_lease_ms (5 minutes)
"UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'"
```

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
