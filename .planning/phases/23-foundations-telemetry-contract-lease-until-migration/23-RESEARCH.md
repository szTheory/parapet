# Phase 23: Foundations — Telemetry Contract + `lease_until` Migration - Research

**Researched:** 2026-05-27
**Domain:** Ecto schema migration (Postgres `ALTER TABLE` + backfill), telemetry contract module authoring, ExDoc tier annotation enforcement, concurrency test patterns for expired-lease self-heal
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** — `lease_until :utc_datetime_usec, null: false` added via single `def change` migration: (1) add nullable, (2) `execute "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'"` backfill, (3) `modify :lease_until, :utc_datetime_usec, null: false`.

**D-02** — Lease default computed at write time in `ClaimService` (now + duration), NOT a Postgres `default:`.

**D-03** — `@default_lease_ms 5 * 60 * 1_000` as module-level constant in `ClaimService`. NOT Application-env configurable.

**D-04** — Single partial index `CREATE INDEX … ON parapet_action_claims (lease_until) WHERE status = 'claimed'`.

**D-05** — `claim_action/1` self-heals stale claims via single atomic UPDATE-in-place.

**D-06** — New `claim_action/1` flow: insert-wins path → on conflict, attempt self-heal UPDATE → if 1 row returned `{:won, claim}` with bumped `attempt_count`; if 0 rows `{:conflicted, claim}`.

**D-07** — Stolen rows NOT transitioned to `"expired"` status separately; UPDATE-in-place collapses steal.

**D-08** — Concurrency test: sequential test inserts a stale row directly, calls `claim_action/1`, asserts `{:won, claim}`, `claim.id == original_id`, `claim.attempt_count == 2`.

**D-09** — Ship `Parapet.Telemetry.RecoveryAction` mirroring `Parapet.Telemetry.AsyncDelivery` 1:1 under Experimental tier.

**D-10** — Seven event tuples; the `executed` triplet counts as one `:telemetry.span/3` family.

**D-11** — Measurement keys: `count` (every event), `duration_ms` and `duration_native` (span events only; `start` carries `system_time`; `stop`/`exception` carry both duration measurements).

**D-12** — Metadata keys: closed vocabularies for `capability_id`, `action_kind`, `outcome`, `short_circuit_reason`, `failure_class`, `actor_kind`, `refs` sub-map.

**D-13** — New `docs/telemetry.md` section "## Recovery Action Family (Experimental)" placed after "## Semantic Guarantees" (`:131`).

**D-14** — New row in `docs/stability.md` Experimental Modules table for `Parapet.Telemetry.RecoveryAction`.

**D-15** — Ship `test/parapet/telemetry/recovery_action_test.exs` mirroring `async_delivery_test.exs:1-61`.

**D-16** — No emit-site assertions in Phase 23 — contract test is module-introspection only.

**D-17** — No `mix parapet.doctor` lease-aware check in Phase 23 (Phase 29 territory).

**D-18** — No changes to `Parapet.Operator.confirm_runbook_step/4` (Phase 25 territory).

### Claude's Discretion

- Exact migration filename (timestamp + descriptive slug).
- Exact wording of the Experimental admonition in `Parapet.Telemetry.RecoveryAction.@moduledoc`.
- Exact public function signatures on `Parapet.Telemetry.RecoveryAction` — must mirror AsyncDelivery style.

### Deferred Ideas (OUT OF SCOPE)

- Lease-aware `mix parapet.doctor` checks (Phase 29).
- Transitioning stolen rows to `"expired"` status.
- Concurrent-stealer-vs-stealer test harness.
- Per-capability cooldown / breaker scope (v1.2).
- Configurable lease duration per environment.
- MCP Preview surface (v1.3+).
- `Parapet.Telemetry.RecoveryAction` graduating to Stable (Phase 29/v1.2).
- `Parapet.Recovery` behaviour design (Phase 24).
- Preview/Confirm UX (Phase 25).
- Emit-site wiring (Phase 26).
- Playbook scaffolds (Phase 27).
- Demo seed (Phase 28).
- Doctor adoption signal (Phase 29).
- Removing `Application.put_env` from `Parapet.SLO` (v1.2 thread).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FND-01 | `parapet_action_claims` schema migration adds a `lease_until` column; existing rows backfilled; `ClaimService.claim_action/1` self-heals expired claims atomically; concurrency test proves self-heal | Postgres UPDATE ... WHERE RETURNING atomicity (verified), Ecto migration backfill pattern (verified), `ClaimService` `now:` injection opt (verified in code), partial index selectivity (verified) |
| FND-02 | Telemetry contract for `[:parapet, :operator, :recovery_action, ...]` documented in `docs/telemetry.md` under Experimental tier; event names, measurement keys, metadata keys explicit; contract test guards the freeze | ExDoc admonition detection regex (verified in code), `AsyncDelivery` template structure (verified in code), `:telemetry.span/3` measurement key API (verified against docs), `verify.public_api` Experimental path (verified in code) |
</phase_requirements>

---

## Summary

Phase 23 is a pure lock-in phase: two irreversible-on-publish surfaces that must precede all capability code. Every architectural decision is already locked in CONTEXT.md D-01 through D-18. Research deepens and verifies those decisions against Postgres docs, Ecto SQL docs, the official `:telemetry` library API, and the live codebase.

**Key findings:**

1. The Postgres `UPDATE ... WHERE lease_until < now() RETURNING *` atomicity claim is **verified correct** under READ COMMITTED: the second concurrent stealer blocks on the row lock, re-evaluates the WHERE clause against the committed state, finds `lease_until < now()` is now FALSE (the first stealer already set a future `lease_until`), produces 0 affected rows, and falls through to `{:conflicted, claim}`. Exactly one stealer wins per expired row. No `SELECT FOR UPDATE` needed.

2. The single-`def change` migration pattern (add nullable → `execute/2` backfill → `modify` with `:from`) is the **idiomatic Ecto 3.x pattern** for this table size and use case. For a small table like `parapet_action_claims` (not millions of rows on a typical dev/staging db), the three-operation sequence inside one migration file keeps rollback semantics coherent. The `fly-apps/safe-ecto-migrations` two-migration approach targets large production tables with zero-downtime constraints — not relevant here.

3. The project's measurement key convention (`duration_ms` + `duration_native`) differs slightly from the raw `:telemetry.span/3` API keys (`duration` in native units only). D-11's specification is self-consistent with the project's established convention (see `Parapet.Metrics.Probe`, `Parapet.Metrics.Oban`) but the plan must be precise about this distinction to avoid confusion.

4. The `verify.public_api` admonition detection regex is well-understood: `~r/####\s+Experimental\s*\{:\s*\.warning\}/` — the new module just needs `> #### Experimental {: .warning}` in its `@moduledoc` and it classifies correctly.

5. The `concurrency_bootstrap.ex` DDL does NOT include `lease_until` — it must be updated to match the new schema for concurrency tests to work.

**Primary recommendation:** Execute the migration + contract module + docs + contract test in one coherent PR. The only non-obvious implementation detail is updating `ConcurrencyBootstrap` DDL to include the `lease_until` column so the concurrency test can insert rows directly.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `lease_until` column + backfill | Database / Storage | — | Schema DDL lives in Postgres; Ecto migration is the single delivery vehicle |
| Expired-claim self-heal atomicity | Database / Storage | API / Backend | Postgres MVCC + row lock enforces single-stealer; `ClaimService` implements the UPDATE pattern |
| `@default_lease_ms` constant | API / Backend | — | Computed at write time in `ClaimService`; never exposed to DB as default or to config as env var |
| Partial index `(lease_until) WHERE status='claimed'` | Database / Storage | — | Index lives in Postgres; migration delivers it |
| Telemetry contract module | API / Backend | — | Pure Elixir module; no DB or UI dependency |
| Docs update (`docs/telemetry.md`, `docs/stability.md`) | — | API / Backend | Static documentation; indexed by ExDoc for hexdocs.pm |
| `verify.public_api` gate enforcement | API / Backend | — | Regex parses `@moduledoc` at compile time; no changes to the task itself |
| Contract test | API / Backend | — | ExUnit module-introspection; no emit-site assertions |

---

## Standard Stack

### Core (all already in `mix.exs` — zero new dependencies)

| Library | Version (locked) | Purpose in Phase 23 | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `~> 3.10` (currently 3.12+) | Migration DSL — `add`, `execute`, `modify`, `create index` | Project's only migration tool |
| `postgrex` | `~> 0.20` | Executes the migration SQL against Postgres | Project's only DB adapter |
| `telemetry` | `~> 1.2` | `:telemetry.span/3` convention the contract module describes | Already shipped in `mix.exs` |
| `ecto` | `~> 3.10` | `Ecto.Query` for the self-heal `update_all` | Already in every Ecto project |
| `ex_doc` | `~> 0.31` | ExDoc admonition callouts that `verify.public_api` parses | Dev dep only |

**Package Legitimacy Audit:** Phase 23 installs **zero new packages**. No slopcheck run required. Planner should NOT add any `mix deps.get` or `mix deps.update` tasks.

---

## Architecture Patterns

### System Architecture Diagram

```
[Migration: lease_until column]
     │
     ▼
[Postgres: parapet_action_claims]
     │  (unique constraint: incident_id, action_kind, action_key)
     │  (partial index: lease_until WHERE status='claimed')
     │
     ▼
[ClaimService.claim_action/1]
     │
     ├─▶ insert_all on_conflict:nothing ──▶ count==1 ──▶ {:won, claim}
     │                                                         │
     └─▶ count==0 (conflict)                                  │
              │                                               │
              ▼                                               │
         [UPDATE ... WHERE status='claimed'                   │
           AND lease_until < $now RETURNING *]                │
              │                                               │
              ├─▶ 1 row returned (expired claim stolen) ──▶ {:won, claim} (attempt_count bumped)
              │
              └─▶ 0 rows returned (live claim) ──▶ {:conflicted, claim}


[Parapet.Telemetry.RecoveryAction module]
     │
     ├─▶ @event_families (7 tuples, frozen)
     ├─▶ allowed_public_keys/1 (per family allowlist)
     ├─▶ shape_metadata/2 (strips private keys, builds :refs sub-map)
     └─▶ vocab guards (outcome, short_circuit_reason, failure_class, actor_kind)
          │
          ▼
    [verify.public_api] ──▶ Experimental tier detected via admonition regex
          │
          ▼
    [docs/stability.md Experimental table]
          │
          ▼
    [docs/telemetry.md Recovery Action Family section]
```

### Recommended Project Structure

```
lib/parapet/telemetry/
├── async_delivery.ex        # existing Stable template
└── recovery_action.ex       # NEW Experimental contract module (Phase 23)

priv/repo/migrations/
├── 20260521010000_create_parapet_action_claims.exs   # existing (DO NOT TOUCH)
└── 20260528010000_add_lease_until_to_parapet_action_claims.exs  # NEW

test/parapet/telemetry/
├── async_delivery_test.exs     # existing template
└── recovery_action_test.exs    # NEW contract test (Phase 23)

test/parapet/automation/
└── claim_service_test.exs      # existing; add one @tag :unboxed sequential test

test/support/
└── concurrency_bootstrap.ex    # existing; MUST add lease_until to DDL
```

### Pattern 1: Ecto `def change` with backfill via `execute/2`

**What:** Single migration file with three operations inside `def change`: add nullable column, backfill existing rows with `execute/2` (forward SQL / reverse is no-op for data), then `modify` with `:from` option for reversibility.

**When to use:** Adding a non-null column to a small-to-medium table where downtime from the NOT NULL validation scan is acceptable. For zero-downtime on large tables, use separate migrations + `validate: false`.

**Why single `def change` is correct for this phase:** `parapet_action_claims` is a library's own table — not a customer's millions-of-rows table. The backfill is deterministic (`claimed_at + INTERVAL '5 minutes'`), fast, and does not depend on application state. Single file keeps the operation atomic for `mix ecto.migrate` — the docs and code stay in sync.

**Example (canonical shape for D-01):**
```elixir
# Source: Ecto.Migration hexdocs + verified against existing project migration patterns
defmodule Parapet.Repo.Migrations.AddLeaseUntilToParapetActionClaims do
  use Ecto.Migration

  def change do
    alter table(:parapet_action_claims) do
      add :lease_until, :utc_datetime_usec, null: true
    end

    execute(
      "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'",
      # rollback no-op: removing the column reverts the data anyway
      ""
    )

    alter table(:parapet_action_claims) do
      modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}
    end

    create index(:parapet_action_claims, [:lease_until],
      where: "status = 'claimed'",
      name: :parapet_action_claims_lease_until_claimed_index
    )
  end
end
```

**Rollback story:** `execute/2` with empty string reverse is the Ecto-idiomatic way to mark a data migration as non-reversible for the backfill step while keeping `def change` for the structural changes. `modify` with `:from` option makes the NOT NULL flip fully reversible. `mix ecto.rollback` drops the column (structural reversal) which also removes the data.

### Pattern 2: Postgres UPDATE-in-place for expired claim self-heal (D-05/D-06)

**What:** A single `UPDATE ... WHERE ... RETURNING *` statement — no `SELECT FOR UPDATE` prefix. Under READ COMMITTED isolation, Postgres serializes concurrent stealers through the row lock.

**Why atomicity holds (VERIFIED against PostgreSQL docs):**
- When two concurrent `claim_action/1` calls both find the same row with `status='claimed'` AND `lease_until < now()`, both try the self-heal UPDATE.
- The first updater acquires the row lock and commits: it sets a new `lease_until` = `now + 5min`.
- The second updater blocks on the row lock; when unblocked, Postgres re-evaluates the WHERE clause against the updated row. `lease_until < now()` is now FALSE (it was set to a future time). The UPDATE affects 0 rows.
- The second caller's `update_all` returns `{0, []}` → falls through to the existing `{:conflicted, claim}` path.
- **Single-stealer correctness: guaranteed by Postgres MVCC + row lock.** No additional `SERIALIZABLE` isolation or advisory locks needed.

**Ecto shape for the self-heal UPDATE:**
```elixir
# Source: Ecto.Query docs + Postgres UPDATE ... RETURNING semantics
from(claim in ActionClaim,
  where:
    claim.incident_id == ^incident_id and
    claim.action_kind == ^action_kind and
    claim.action_key == ^action_key and
    claim.status == "claimed" and
    claim.lease_until < ^now,
  update: [
    set: [
      status: "claimed",
      idempotency_key: ^new_idempotency_key,
      attempt_count: claim.attempt_count + 1,   # fragment/1 for expression
      claimed_at: ^now,
      lease_until: ^new_lease_until,
      updated_at: ^now
    ]
  ]
)
|> repo.update_all(returning: true)
# Returns {1, [%ActionClaim{}]} on success, {0, []} when another stealer won first
```

**Note on `attempt_count + 1`:** Ecto `update_all` supports SQL expressions via `fragment/1`. The exact form should use `fragment("attempt_count + 1")` or Ecto's increment helper to avoid re-reading the field value.

### Pattern 3: `Parapet.Telemetry.RecoveryAction` module structure

**What:** Mirrors `Parapet.Telemetry.AsyncDelivery` 1:1. Closed `@event_families` list, `allowed_public_keys/1` per family, `shape_metadata/2` ref-key allowlist, bounded vocab normalization functions.

**When to use:** Every time parapet adds a new event family under a named stability tier, a contract module is the delivery vehicle. The module makes the contract machine-readable (testable) rather than docs-only.

**Key structural elements:**
```elixir
# Source: lib/parapet/telemetry/async_delivery.ex (verified live)
defmodule Parapet.Telemetry.RecoveryAction do
  @moduledoc """
  Public contract helpers for Parapet's recovery action telemetry family.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release
  > with a single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """

  @event_families [
    [:parapet, :operator, :recovery_action, :previewed],
    [:parapet, :operator, :recovery_action, :preview_failed],
    [:parapet, :operator, :recovery_action, :confirmed],
    [:parapet, :operator, :recovery_action, :short_circuited],
    [:parapet, :operator, :recovery_action, :conflicted],
    [:parapet, :operator, :recovery_action, :executed, :start],
    [:parapet, :operator, :recovery_action, :executed, :stop],
    [:parapet, :operator, :recovery_action, :executed, :exception]
  ]
  # NOTE: D-10 says "7 tuples" counting the executed triplet as one family.
  # The @event_families list for introspection should enumerate all 8 concrete event names
  # (including :start/:stop/:exception suffixes), but the "7 families" count is correct
  # when the span triplet is counted as one logical unit. See Open Question OQ-1 below.
  ...
end
```

### Pattern 4: ExDoc Experimental admonition — exact shape for `verify.public_api`

**What:** The `verify.public_api` task uses a regex to detect tier from `@moduledoc` text. The exact required shape:

```
> #### Experimental {: .warning}
>
> ...body text...
```

**Detection regex (verified from `lib/mix/tasks/verify.public_api.ex:110`):**
```elixir
Regex.match?(~r/####\s+Experimental\s*\{:\s*\.warning\}/, text)
```

**Rules:**
- Must be `####` (four hashes), not `###` or `#####`
- `Experimental` must immediately follow the hashes (with optional whitespace)
- `{: .warning}` must be on the same line as the heading word
- The body text of the admonition (which follows on the next lines) is irrelevant to detection
- NO separate `@stability` module attribute is used — the admonition is the single source of truth (D-02 from Phase 19 CONTEXT)

**Verified in existing modules:** `Parapet.Automation.ClaimService` (`lib/parapet/automation/claim_service.ex:5-10`), `Parapet.Spine.ActionClaim` (`:5-10`), `Parapet.Automation.Executor` (`:5-10`) all carry the exact shape and pass `verify.public_api`.

### Pattern 5: Contract test (module-introspection only)

**What:** Mirror `test/parapet/telemetry/async_delivery_test.exs` exactly. Four test functions: event family list assertion, vocab normalization + rejection, `shape_metadata/2` ref extraction + key stripping, and span triplet membership check.

**Key constraint (D-16):** No emit-site assertions. The contract test proves the module's data structures are frozen — not that any code emits events.

**Example test structure:**
```elixir
# Source: test/parapet/telemetry/async_delivery_test.exs (verified live)
defmodule Parapet.Telemetry.RecoveryActionTest do
  use ExUnit.Case, async: true   # pure module introspection = safe for async

  alias Parapet.Telemetry.RecoveryAction

  test "exposes the seven locked public event families" do
    assert RecoveryAction.event_families() == [
      [:parapet, :operator, :recovery_action, :previewed],
      [:parapet, :operator, :recovery_action, :preview_failed],
      [:parapet, :operator, :recovery_action, :confirmed],
      [:parapet, :operator, :recovery_action, :short_circuited],
      [:parapet, :operator, :recovery_action, :conflicted],
      [:parapet, :operator, :recovery_action, :executed, :start],
      [:parapet, :operator, :recovery_action, :executed, :stop],
      [:parapet, :operator, :recovery_action, :executed, :exception]
    ]
  end

  test "normalizes bounded outcome atoms only" do ... end
  test "shapes metadata keys and builds refs sub-map" do ... end
  test "normalizes short_circuit_reason and failure_class atoms" do ... end
end
```

### Pattern 6: Expired-lease concurrency test (D-08)

**What:** Sequential test using `@tag :unboxed` in `Parapet.TestSupport.ConcurrencyCase`. Inserts a stale row directly into `ConcurrencyRepo`, calls `ClaimService.claim_action/1`, asserts update-in-place.

**Key insight:** The test does NOT use concurrent Tasks. The unique constraint + Postgres MVCC makes the outcome deterministic. The test proves the UPDATE branch is reached and works correctly — not that concurrent stealers are handled (that's already guaranteed by Postgres and covered in commentary).

```elixir
# Source: test/parapet/automation/claim_service_test.exs pattern (verified live)
@tag :unboxed
test "self-heals an expired-lease stale claim left by a crashed node" do
  unboxed_run(fn ->
    ConcurrencyBootstrap.reset!()

    {:ok, incident} = ConcurrencyRepo.insert(%Incident{} |> Incident.changeset(%{title: "Crashed node remnant"}))

    # Insert the stale claim directly — simulates a node that won and crashed before finishing
    past = DateTime.add(DateTime.utc_now(), -10 * 60, :second) |> DateTime.truncate(:microsecond)
    {:ok, original} =
      ConcurrencyRepo.insert(%ActionClaim{
        id: Ecto.UUID.generate(),
        incident_id: incident.id,
        action_kind: "operator",
        action_key: "step-1",
        status: "claimed",
        idempotency_key: "old_key_#{incident.id}",
        attempt_count: 1,
        claimed_at: past,
        lease_until: past,   # already expired
        inserted_at: past,
        updated_at: past,
        error_metadata: %{}
      })

    # Now attempt to claim the same (incident_id, action_kind, action_key)
    assert {:won, claim} =
      ClaimService.claim_action(
        incident_id: incident.id,
        action_kind: "operator",
        action_key: "step-1",
        idempotency_key: "new_key_#{incident.id}"
      )

    # Update-in-place proof
    assert claim.id == original.id
    assert claim.attempt_count == 2
    assert claim.idempotency_key == "new_key_#{incident.id}"
    assert DateTime.compare(claim.lease_until, DateTime.utc_now()) == :gt
  end)
end
```

### Anti-Patterns to Avoid

- **Adding `lease_until` as a Postgres-level column default:** Breaks the `now:` test injection opt in `ClaimService` (D-02). The DB default would compute `now()` at insert time, not at the application clock provided by the test.
- **Using `Ecto.Repo.update_all` without `returning: true` for the self-heal:** Without `RETURNING`, you get `{count, nil}` and cannot return the `{:won, claim}` struct with bumped fields — callers need the updated claim struct.
- **Listing `@event_families` without `:start/:stop/:exception` suffixes for the span family:** Phase 26 emit-site code uses `RecoveryAction.event_families/0` to verify event names. If the span sub-events aren't in the list, the emit-site can accidentally name them differently. See Open Question OQ-1 for how the planner should resolve the 7-vs-8 count.
- **Using `def up / def down` split instead of `def change`:** The backfill SQL is deterministic; `execute/2` with empty reverse string inside `def change` is cleaner and keeps rollback in one place.
- **Updating `concurrency_bootstrap.ex` DDL without adding `lease_until` to the `CREATE TABLE` statement:** The concurrency test inserts rows directly into `ConcurrencyRepo` which uses the bootstrap DDL, not migrations. Missing `lease_until` will cause a DB constraint violation at test insert time.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Atomic expired-claim steal | Custom `SELECT FOR UPDATE` + separate `UPDATE` | `UPDATE ... WHERE ... RETURNING *` | Postgres MVCC handles the race; extra SELECT round-trip is unnecessary |
| Test time injection for lease | Override system clock via mocking library | Existing `now:` opt at `claim_service.ex:23` | Already designed for this; passes `now` to both `claimed_at` and lease computation |
| Tier detection for new module | Custom `@stability` attribute + separate registry | ExDoc admonition `> #### Experimental {: .warning}` | `verify.public_api` already parses exactly this shape; adding a separate mechanism would create two sources of truth |
| Vocab normalization in contract module | Free-form map matching | Pattern like `AsyncDelivery.normalize_*` (atom-keyed map lookup) | Guards the contract at module boundary; raises `ArgumentError` on unknown atoms rather than silently passing invalid data |

---

## Common Pitfalls

### Pitfall 1: `concurrency_bootstrap.ex` DDL not updated

**What goes wrong:** The concurrency test inserts an `ActionClaim` row directly via `ConcurrencyRepo.insert/1`. The bootstrap DDL (`test/support/concurrency_bootstrap.ex:126-155`) defines the `parapet_action_claims` CREATE TABLE — it does NOT include `lease_until`. Inserting a struct with `lease_until:` set will raise `Postgrex.Error: column "lease_until" of relation "parapet_action_claims" does not exist`.

**Why it happens:** `ConcurrencyBootstrap.bootstrap!` uses its own DDL, not Ecto migrations. Migrations run against the dev/test DB; the bootstrap DDL runs in-process for the concurrency test DB. They can drift.

**How to avoid:** Update the `CREATE TABLE` statement in `concurrency_bootstrap.ex` to add `lease_until timestamp(6) without time zone NOT NULL` and add the corresponding partial index. This is a mandatory companion change to the migration.

**Warning signs:** Concurrency test fails with Postgrex.Error referencing `lease_until` column.

---

### Pitfall 2: `modify` without `:from` is not reversible in `def change`

**What goes wrong:** Writing `modify :lease_until, :utc_datetime_usec, null: false` inside `def change` without `:from` option causes `mix ecto.rollback` to fail with `Ecto.MigrationError: cannot reverse migration command: {:modify, :lease_until, ...}`.

**Why it happens:** Ecto needs the old column definition to generate the `ALTER COLUMN ... DROP NOT NULL` SQL for rollback. Without `:from`, it cannot.

**How to avoid:** Always use `modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}` (D-01). The `:from` option is the signal to Ecto's reversal engine.

**Warning signs:** `mix ecto.rollback` raises `cannot reverse migration command` for the modify step.

---

### Pitfall 3: `@event_families` list count ambiguity (7 vs 8 event names)

**What goes wrong:** D-10 says "seven event tuples (the executed triplet counts as one `:telemetry.span/3` family)." But the contract test in D-15 must enumerate concrete event names including `:start/:stop/:exception` suffixes. If the `@event_families` list uses the "7-family" counting (omitting the triplet sub-events), the contract test and Phase 26 emit-site code have no authoritative list of the 8 concrete emittable event names.

**Why it happens:** `:telemetry.span/3` internally emits three sub-events (`:start`, `:stop`, `:exception`) from one invocation. The "7 families" description is a logical grouping; the actual event names are 8 concrete tuples.

**How to avoid:** Include all 8 concrete event name tuples in `@event_families`. Add a separate `@span_families` list (just the `:executed` family base) if callers need to distinguish spans from single-shot events. See Open Question OQ-1 for the recommended resolution.

---

### Pitfall 4: D-11 measurement key naming vs. raw `:telemetry.span/3` API

**What goes wrong:** The `:telemetry.span/3` API emits `duration` (native units) on `:stop`/`:exception`. D-11 specifies `duration_ms` and `duration_native` as the published measurement keys. These are the *post-conversion* keys in the public RecoveryAction contract — the pattern matches `Parapet.Metrics.Probe` and `Parapet.Metrics.Oban` which also convert `duration` → `duration_ms` in their handlers before re-emitting.

**Why it happens:** The project uses `duration_ms` everywhere in its public telemetry surface (verified in `Parapet.Operator`, `Parapet.Metrics.*`). The raw `duration` key from `:telemetry.span/3` is an internal implementation detail that the metrics layer converts.

**How to avoid:** The RecoveryAction contract module documents `duration_ms` and `duration_native` as the keys adopters should subscribe to on `:stop`/`:exception` events. This is the correct project convention. The Phase 26 emit-site code will be responsible for computing these from the raw span `duration` — Phase 23 just documents the expected surface.

**Warning signs:** Contract module documentation mentions `duration` (raw native) without noting the conversion — would mislead Phase 26 implementer.

---

### Pitfall 5: `returning_fields/0` in `ClaimService` doesn't include `lease_until`

**What goes wrong:** The existing `returning_fields/0` private function in `ClaimService` (`:163-180`) lists the fields to include in the `RETURNING` clause of `insert_all`. After the migration adds `lease_until`, the function will NOT return this field unless explicitly added. The self-heal UPDATE via `update_all(returning: true)` returns the full struct, but the existing `insert_all` winner path returns a partial struct.

**Why it matters:** Callers that match `{:won, claim}` may later access `claim.lease_until` (e.g., Phase 25 to display lease expiry in the UI). A nil `lease_until` on a fresh claim is confusing.

**How to avoid:** Add `:lease_until` to `returning_fields/0` in `ClaimService` as part of Phase 23. This is a one-line addition that makes the returned struct complete.

---

### Pitfall 6: `attrs` map in `acquire_claim/2` doesn't include `lease_until`

**What goes wrong:** The `attrs` map built at `claim_service.ex:25-35` (the data passed to `insert_all`) does not include `lease_until`. After the migration, `insert_all` will fail because the column is `NOT NULL` and the application provides no value (no DB-level default, per D-02).

**How to avoid:** Add `lease_until: DateTime.add(now, @default_lease_ms, :millisecond) |> DateTime.truncate(:microsecond)` to the `attrs` map in `claim_action/1`. This is the primary implementation work for FND-01 in `ClaimService`.

---

## Code Examples

### `ClaimService` attrs construction with `lease_until` (FND-01 core change)

```elixir
# Source: lib/parapet/automation/claim_service.ex:17-35 pattern (verified live)
# Add lease_until to attrs map alongside claimed_at
@default_lease_ms 5 * 60 * 1_000

def claim_action(opts) do
  # ... existing setup ...
  now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:microsecond))
  lease_until = DateTime.add(now, @default_lease_ms, :millisecond) |> DateTime.truncate(:microsecond)

  attrs = %{
    incident_id: incident_id,
    action_kind: action_kind,
    action_key: action_key,
    status: "claimed",
    idempotency_key: idempotency_key,
    attempt_count: Keyword.get(opts, :attempt_count, 1),
    claimed_at: now,
    lease_until: lease_until,   # NEW
    inserted_at: now,
    updated_at: now
  }
  # ...
end
```

### Self-heal UPDATE query shape (Ecto)

```elixir
# Source: Ecto.Query docs + D-05 specification
defp steal_expired_claim(repo, attrs, now) do
  new_lease_until = DateTime.add(now, @default_lease_ms, :millisecond) |> DateTime.truncate(:microsecond)

  {count, rows} =
    from(claim in ActionClaim,
      where:
        claim.incident_id == ^attrs.incident_id and
        claim.action_kind == ^attrs.action_kind and
        claim.action_key == ^attrs.action_key and
        claim.status == "claimed" and
        claim.lease_until < ^now,
      update: [
        set: [
          idempotency_key: ^attrs.idempotency_key,
          claimed_at: ^now,
          lease_until: ^new_lease_until,
          updated_at: ^now
        ],
        inc: [attempt_count: 1]   # Ecto shorthand for attempt_count = attempt_count + 1
      ]
    )
    |> repo.update_all(returning: true)

  if count == 1 do
    {:won, rows |> List.first() |> to_claim()}
  else
    nil   # signals fall-through to {:conflicted, claim}
  end
end
```

### Contract test shape (D-15 mirror of `async_delivery_test.exs`)

```elixir
# Source: test/parapet/telemetry/async_delivery_test.exs:1-61 (verified live)
defmodule Parapet.Telemetry.RecoveryActionTest do
  use ExUnit.Case, async: true

  alias Parapet.Telemetry.RecoveryAction

  test "exposes the locked public event families" do
    families = RecoveryAction.event_families()
    assert [:parapet, :operator, :recovery_action, :previewed] in families
    assert [:parapet, :operator, :recovery_action, :executed, :start] in families
    assert [:parapet, :operator, :recovery_action, :executed, :stop] in families
    assert [:parapet, :operator, :recovery_action, :executed, :exception] in families
    assert length(families) == 8  # or 7 if span triplet grouped — see OQ-1
  end

  test "normalizes bounded outcome atoms only" do
    assert RecoveryAction.normalize_outcome(:succeeded) == :succeeded
    assert_raise ArgumentError, fn -> RecoveryAction.normalize_outcome(:unknown_outcome) end
  end

  test "shapes metadata into public keys and builds refs sub-map" do
    shaped = RecoveryAction.shape_metadata(:previewed, %{
      capability_id: :retry_async_item,
      outcome: :previewed,
      incident_id: "inc-123",
      internal_debug: "ignored"
    })
    assert shaped.capability_id == :retry_async_item
    assert shaped.refs.incident_ref == "inc-123"
    refute Map.has_key?(shaped, :internal_debug)
  end
end
```

---

## Runtime State Inventory

This is a schema migration phase (adding a column to an existing table). Relevant runtime state to audit:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `parapet_action_claims` rows in dev/staging/production databases | The migration backfills `lease_until = claimed_at + INTERVAL '5 minutes'` automatically — rows made 10+ minutes ago will have `lease_until` in the past (already expired), which is correct semantics |
| Live service config | No live service config references `lease_until` — it's a new column | None |
| OS-registered state | None | None — verified by grep |
| Secrets/env vars | `@default_lease_ms` is a module constant, NOT env var (D-03) | None |
| Build artifacts | `concurrency_bootstrap.ex` has inline DDL that must be updated | Code change required (see Pitfall 1) |
| Existing claims at migration time | Any `status = 'claimed'` row where `claimed_at + 5 min < now()` will be immediately expired | This is the intended behavior: stale claims should be self-healable by the next `claim_action/1` caller |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `def up / def down` for any backfill migration | `def change` with `execute/2(forward, reverse)` + `modify` with `:from` | Ecto 3.x | Simpler; rollback works correctly |
| `SELECT FOR UPDATE` + separate `UPDATE` for claim acquisition | `UPDATE ... WHERE ... RETURNING *` (one statement) | Standard Postgres recommendation | Fewer round-trips; atomicity guaranteed by row lock |
| Module attribute `@stability :experimental` as tier signal | ExDoc admonition `> #### Experimental {: .warning}` in `@moduledoc` | Phase 19 (v1.0) | Single source of truth parseable by `verify.public_api` regex |

---

## Open Questions

### OQ-1: `@event_families` list — 7 logical families vs. 8 concrete event names

**What we know:** D-10 says "seven event tuples (the executed triplet counts as one `:telemetry.span/3` family)." The contract test in D-15 must enumerate concrete event names for the freeze assertion. `:telemetry.span/3` emits three concrete event name tuples for the `executed` family (`:start`, `:stop`, `:exception`).

**What's unclear:** Should `RecoveryAction.event_families/0` return a 7-element list (grouping span as one) or an 8-element list (enumerating all concrete names)? The test in D-15 says "seven locked public event families" mirroring async_delivery_test's "six locked public event families."

**Recommendation:** Return all 8 concrete event name tuples from `event_families/0`. The docstring can say "seven event families (the executed span counts as one logical family with three sub-events)." Add a companion `span_families/0` function that returns just the `:executed` base tuple `[:parapet, :operator, :recovery_action, :executed]` for callers who need to distinguish span vs. single-shot. The contract test asserts the full 8-item list. This gives Phase 26 the authoritative list it needs to verify emit-sites.

**If planner disagrees:** Planner should document the chosen count in PLAN.md so Phase 26 implementer has an unambiguous spec.

---

### OQ-2: `acquire_claim/2` is private — where does the self-heal branch live in `claim_action/1`?

**What we know:** The current flow at `claim_service.ex:74-97` has `acquire_claim/2` returning `{:won, claim}` or `{:conflicted, claim}`. The self-heal UPDATE must happen between "insert returned 0 rows" and "fall through to conflict path."

**What's unclear:** Should the self-heal be added to `acquire_claim/2` (making it try the UPDATE before returning `{:conflicted, claim}`) or should it be a separate step in the outer `claim_action/1` transaction block?

**Recommendation:** Add the self-heal to `acquire_claim/2`. When `insert_all` returns `count == 0`, before falling through to the `repo.one!` select (which is the current conflict path), attempt `steal_expired_claim/3`. If it returns `{:won, claim}`, return that. If nil, proceed to `{:conflicted, claim}` via `repo.one!`. This keeps the steal logic encapsulated in the same private function and requires no changes to the outer `claim_action/1` transaction structure.

---

### OQ-3: `lease_until` field in `Parapet.Spine.ActionClaim` schema

**What we know:** The `ActionClaim` schema (`lib/parapet/spine/action_claim.ex`) does not yet declare `field(:lease_until, :utc_datetime_usec)`. The changeset's `cast/3` call must include it for the self-heal UPDATE changeset to work.

**Recommendation:** Add `field(:lease_until, :utc_datetime_usec)` to the schema and add `:lease_until` to the `cast/3` and `validate_required/2` lists in `changeset/2`. This is a required companion change to the migration — without it, Ecto cannot read/write the column through the schema.

**This is not in CONTEXT.md's locked decisions but is an obvious necessary companion.** Including it in the plan as a sub-task of FND-01.

---

## Package Legitimacy Audit

**Phase 23 installs zero new packages.** No audit required.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All | ✓ | 1.19.5 (OTP 28) | — |
| PostgreSQL (psql) | Migration + concurrency test | ✓ | 14.17 (Homebrew) | — |
| `mix ecto.migrate` | FND-01 migration | ✓ | Ecto SQL ~> 3.10 | — |
| ExUnit | Contract test + concurrency test | ✓ | Bundled with Elixir | — |

**No missing dependencies with or without fallback.**

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/telemetry/recovery_action_test.exs test/parapet/automation/claim_service_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FND-01 (migration) | `mix ecto.migrate` succeeds on a DB with existing rows; backfill sets sensible default | Smoke / manual | `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` | ❌ Wave 0 (migration file) |
| FND-01 (self-heal) | Expired-lease row is updated in place; `{:won, claim}` with bumped `attempt_count` and same `id` | unit/db | `mix test test/parapet/automation/claim_service_test.exs --tag unboxed` | ❌ Wave 0 (new test function) |
| FND-01 (attrs) | Fresh `claim_action/1` writes `lease_until = claimed_at + 5 min` | unit/db | (covered by existing concurrency test after column addition) | ✓ (extends existing) |
| FND-02 (event families) | `RecoveryAction.event_families/0` returns exact frozen list | unit | `mix test test/parapet/telemetry/recovery_action_test.exs` | ❌ Wave 0 |
| FND-02 (vocab guards) | `normalize_outcome/1` raises for unknown atoms | unit | same file | ❌ Wave 0 |
| FND-02 (shape_metadata) | Strips private keys, builds `:refs` sub-map | unit | same file | ❌ Wave 0 |
| FND-02 (tier gate) | `mix verify.public_api` classifies new module as `:experimental` | gate | `mix verify.public_api` | ✓ (runs against compiled module) |
| FND-02 (docs) | `docs/telemetry.md` section exists and references all 7+ events | manual | review + grep | ❌ Wave 0 (doc section) |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/telemetry/recovery_action_test.exs test/parapet/automation/claim_service_test.exs`
- **Per wave merge:** `mix test && mix verify.public_api`
- **Phase gate (before `/gsd:verify-work`):** `mix test && mix verify.public_api && mix credo --strict && mix dialyzer`

### Wave 0 Gaps

- [ ] `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` — FND-01 migration
- [ ] `lib/parapet/telemetry/recovery_action.ex` — FND-02 contract module
- [ ] `test/parapet/telemetry/recovery_action_test.exs` — FND-02 contract test
- [ ] New test function in `test/parapet/automation/claim_service_test.exs` — FND-01 self-heal proof
- [ ] `test/support/concurrency_bootstrap.ex` DDL update — required for the new concurrency test to insert rows with `lease_until`
- [ ] `lib/parapet/spine/action_claim.ex` — add `field(:lease_until, :utc_datetime_usec)` + changeset update
- [ ] `lib/parapet/automation/claim_service.ex` — add `lease_until` to `attrs`, add self-heal UPDATE branch, add `:lease_until` to `returning_fields/0`

---

## Security Domain

ASVS analysis: Phase 23 is schema DDL + a new internal Elixir module + documentation. No new user-facing inputs, no authentication/session changes, no cryptography. The lease duration is a module constant, not configurable — eliminating the attack surface of `Application.put_env` injection.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Partial | `normalize_*` functions in RecoveryAction module raise `ArgumentError` on unknown atoms — closes the open-enum risk for vocab keys |
| V6 Cryptography | No | — |

No new threat patterns introduced. The `lease_until` column narrows the existing multi-node claim leak surface (Pitfall 4 in PITFALLS.md).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Ecto.Query` `update: [inc: [attempt_count: 1]]` shorthand generates correct `attempt_count = attempt_count + 1` SQL | Code Examples | Must use `fragment("attempt_count + 1")` instead; causes silent incorrect attempt count |
| A2 | Postgres 14+ (the minimum for `parapet_action_claims` adopters) supports the partial index with `WHERE status = 'claimed'` string literal | Architecture Patterns | Partial indexes with string predicates exist since PG 8.x; essentially no risk |
| A3 | `ConcurrencyRepo.insert/1` with an explicit `ActionClaim` struct (bypass changeset) will work for the test fixture if all NOT NULL columns are populated | Concurrency test example | If repo enforces changeset validation, must use `ActionClaim.changeset/2 |> ConcurrencyRepo.insert/1` instead |

**If this table is non-empty:** Items A1 and A3 should be verified by the implementer at code-write time before committing.

---

## Sources

### Primary (HIGH confidence)

- `lib/parapet/telemetry/async_delivery.ex` — template for RecoveryAction module structure (verified live, 330 lines)
- `test/parapet/telemetry/async_delivery_test.exs` — template for contract test (verified live, 61 lines)
- `test/parapet/automation/claim_service_test.exs` — template for concurrency test structure (verified live)
- `test/support/concurrency_bootstrap.ex` — DDL gap identified (verified live, `lease_until` column absent)
- `lib/parapet/automation/claim_service.ex` — `now:` injection opt at `:23`, `acquire_claim/2` at `:74-97`, `returning_fields/0` at `:163-180` (verified live)
- `lib/parapet/spine/action_claim.ex` — schema shape, `@statuses`, unique constraint (verified live)
- `lib/mix/tasks/verify.public_api.ex` — admonition detection regex at `:110` (verified live)
- `docs/stability.md` — Experimental table insertion point at `:49` (verified live)
- `docs/telemetry.md` — Stable header at `:3-10`, Semantic Guarantees at `:131` (verified live)
- `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` — original migration shape (verified live)
- `lib/parapet/metrics/probe.ex` — `duration` → `duration_ms` conversion pattern (verified live)
- `lib/parapet/operator.ex:285-301` — `duration_native` + `duration_ms` measurement convention (verified live)
- [PostgreSQL docs: transaction isolation (READ COMMITTED)](https://www.postgresql.org/docs/current/transaction-iso.html) — UPDATE ... WHERE re-evaluation after row lock (VERIFIED)
- [PostgreSQL docs: partial indexes](https://www.postgresql.org/docs/current/indexes-partial.html) — predicate matching for `WHERE status = 'claimed'` queries (VERIFIED)
- [Ecto.Migration hexdocs](https://hexdocs.pm/ecto_sql/Ecto.Migration.html) — `modify` with `:from` option for reversibility (VERIFIED)
- [telemetry hexdocs](https://hexdocs.pm/telemetry/telemetry.html) — `:telemetry.span/3` `system_time`/`duration` measurement keys (VERIFIED)

### Secondary (MEDIUM confidence)

- [fly-apps/safe-ecto-migrations](https://github.com/fly-apps/safe-ecto-migrations) — two-migration pattern for large tables (confirmed not required for this use case)
- [Elixir Forum: not-null column backfill](https://elixirforum.com/t/ecto-migration-setting-a-default-for-existing-rows-for-a-new-not-null-column/31568) — community confirmation of single-`def change` approach

---

## Metadata

**Confidence breakdown:**
- Migration pattern: HIGH — verified against Ecto docs and existing project migration conventions
- Postgres UPDATE atomicity: HIGH — verified directly against PostgreSQL isolation docs
- Telemetry measurement keys: HIGH — verified against official telemetry hexdocs; project's `duration_ms` convention verified in 3 live files
- ExDoc admonition shape: HIGH — verified against live `verify.public_api.ex` source and existing Experimental modules
- Test structure: HIGH — verified against live `async_delivery_test.exs` and `claim_service_test.exs` templates

**Research date:** 2026-05-27
**Valid until:** 2026-06-27 (Ecto/Postgres APIs are stable; the dominant risk is codebase drift if Phase 23 is delayed)
