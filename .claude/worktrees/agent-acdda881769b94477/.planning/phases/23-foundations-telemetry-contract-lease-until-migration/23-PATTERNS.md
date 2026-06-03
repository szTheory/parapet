# Phase 23: Foundations — Telemetry Contract + `lease_until` Migration - Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 9
**Analogs found:** 9 / 9

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` | migration | batch (DDL + backfill) | `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` | role-match (alter vs. create) |
| `lib/parapet/telemetry/recovery_action.ex` | contract module | request-response (introspection) | `lib/parapet/telemetry/async_delivery.ex` | exact |
| `test/parapet/telemetry/recovery_action_test.exs` | test | request-response (module introspection) | `test/parapet/telemetry/async_delivery_test.exs` | exact |
| `lib/parapet/spine/action_claim.ex` | model (schema) | CRUD | `lib/parapet/spine/action_claim.ex` itself (field add) | self |
| `lib/parapet/automation/claim_service.ex` | service | CRUD + event-driven (self-heal) | `lib/parapet/automation/claim_service.ex` itself (behaviour extension) | self |
| `test/parapet/automation/claim_service_test.exs` | test | CRUD (db-backed sequential) | `test/parapet/automation/claim_service_test.exs` itself (new test fn) | self |
| `test/support/concurrency_bootstrap.ex` | fixture / config | batch (DDL) | `test/support/concurrency_bootstrap.ex` itself (DDL column add) | self |
| `docs/telemetry.md` | documentation | — | `docs/telemetry.md` itself (section insert) | self |
| `docs/stability.md` | documentation | — | `docs/stability.md` itself (table row insert) | self |

---

## Pattern Assignments

### `priv/repo/migrations/20260528010000_add_lease_until_to_parapet_action_claims.exs` (migration, batch)

**Analog:** `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs`

**Module name / `use` pattern** (lines 1-4):
```elixir
defmodule Parapet.Repo.Migrations.AddLeaseUntilToParapetActionClaims do
  use Ecto.Migration

  def change do
```

**Existing column type to mirror** (analog line 15) — `claimed_at` and `timestamps` both use `:utc_datetime_usec`:
```elixir
add :claimed_at, :utc_datetime_usec, null: false
# ...
timestamps(type: :utc_datetime_usec)
```

**Partial index convention** (analog line 26) — `WHERE`-predicate index over a status column:
```elixir
create index(:parapet_action_claims, [:status, :claimed_at])
```
New index follows this naming convention:
```elixir
create index(:parapet_action_claims, [:lease_until],
  where: "status = 'claimed'",
  name: :parapet_action_claims_lease_until_claimed_index
)
```

**Full `def change` shape for this migration (D-01 spec):**
```elixir
def change do
  alter table(:parapet_action_claims) do
    add :lease_until, :utc_datetime_usec, null: true
  end

  execute(
    "UPDATE parapet_action_claims SET lease_until = claimed_at + INTERVAL '5 minutes'",
    ""   # rollback no-op: column drop reverts data
  )

  alter table(:parapet_action_claims) do
    modify :lease_until, :utc_datetime_usec, null: false, from: {:utc_datetime_usec, null: true}
  end

  create index(:parapet_action_claims, [:lease_until],
    where: "status = 'claimed'",
    name: :parapet_action_claims_lease_until_claimed_index
  )
end
```

**Key rules:**
- `modify` MUST include `from: {:utc_datetime_usec, null: true}` — without it, `mix ecto.rollback` raises `cannot reverse migration command`.
- Backfill formula is `claimed_at + INTERVAL '5 minutes'` — NOT `now() + 5 minutes`.
- `execute/2` second arg is `""` (empty string), not an inverse SQL statement — the data migration is non-reversible; structural rollback drops the column anyway.

---

### `lib/parapet/telemetry/recovery_action.ex` (contract module, request-response)

**Analog:** `lib/parapet/telemetry/async_delivery.ex`

**Module header + Experimental admonition** (analog lines 1-10):
```elixir
defmodule Parapet.Telemetry.RecoveryAction do
  @moduledoc """
  Public contract helpers for Parapet's recovery action telemetry family.

  > #### Experimental {: .warning}
  >
  > This module is **experimental** in v1.x. Its API may change in a minor release
  > with a single-version notice in CHANGELOG.md. See
  > [Stability & Deprecation Policy](stability.html) for details.
  """
```

The `verify.public_api` regex (verified at `lib/mix/tasks/verify.public_api.ex:110`) is:
```elixir
~r/####\s+Experimental\s*\{:\s*\.warning\}/
```
The admonition heading must be exactly `#### Experimental {: .warning}` (four hashes, no deviation).

**`@event_families` constant pattern** (analog lines 56-63):
```elixir
@event_families [
  [:parapet, :delivery, :outbound],
  ...
]
```
New module enumerates all 8 concrete event name tuples (D-10 / OQ-1 resolution — include `:start/:stop/:exception` suffixes for Phase 26 emit-site verifiability):
```elixir
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
```

**Per-family allowed-keys map pattern** (analog lines 12-53):
```elixir
@delivery_family_keys %{
  outbound: [:integration, :provider, :channel, :outcome, :failure_class, :fault_plane],
  ...
}
@allowed_public_keys Map.merge(@delivery_family_keys, @async_family_keys)
```
New module uses a single `@recovery_action_family_keys` map keyed by the last atom of each single-shot event (`:previewed`, `:preview_failed`, `:confirmed`, `:short_circuited`, `:conflicted`) plus the span base (`:executed`). The allowed keys per D-12: `capability_id`, `action_kind`, `outcome`, `short_circuit_reason`, `failure_class`, `actor_kind`.

**Vocab normalization constant + function pattern** (analog lines 65-96 + 172-205):
```elixir
@delivery_outcomes %{
  attempted: :attempted,
  ...
}

def normalize_delivery_outcome(outcome) do
  outcome |> normalize_enum(@delivery_outcomes, "delivery outcome")
end
```
New module defines:
- `@outcomes` map for `normalize_outcome/1`
- `@short_circuit_reasons` map for `normalize_short_circuit_reason/1`
- `@failure_classes` map for `normalize_failure_class/1`
- `@actor_kinds` map for `normalize_actor_kind/1`

All vocab atom values from D-12.

**`@allowed_ref_keys` + `@known_ref_mappings` + `shape_metadata/2` pattern** (analog lines 104-259):
```elixir
@allowed_ref_keys [
  :message_ref, :delivery_ref, :job_ref, :attempt_ref, ...
]

@known_ref_mappings %{
  attempt_id: :attempt_ref,
  delivery_id: :delivery_ref,
  incident_id: :incident_ref,
  ...
}

def shape_metadata(family, metadata) when is_atom(family) and is_map(metadata) do
  public_keys = allowed_public_keys(family)
  public_metadata = metadata |> Map.take(public_keys) |> maybe_normalize_known_values()
  refs = metadata |> extract_known_refs() |> merge_explicit_refs(Map.get(metadata, :refs, %{}))
  if map_size(refs) == 0, do: public_metadata, else: Map.put(public_metadata, :refs, refs)
end
```
New module uses `@allowed_ref_keys` containing: `:incident_ref`, `:claim_ref`, `:step_ref`, `:preview_ref` (D-12 refs sub-map spec). `@known_ref_mappings` maps `incident_id → :incident_ref`, `claim_id → :claim_ref`, `step_id → :step_ref`, `preview_id → :preview_ref`.

**`normalize_enum/3` private helper** (analog lines 285-298) — copy verbatim:
```elixir
defp normalize_enum(value, mapping, label) do
  key = normalize_key(value)
  case Map.fetch(mapping, key) do
    {:ok, normalized} -> normalized
    :error -> raise ArgumentError, "Unsupported #{label}: #{inspect(value)}"
  end
end

defp normalize_key(value) when is_atom(value), do: value
defp normalize_key(value) when is_binary(value), do: value |> String.trim() |> String.to_atom()
```

**`event_families/0` public function** (analog line 139):
```elixir
@doc since: "1.1.0"
@doc """
Returns the list of all eight frozen recovery action telemetry event name tuples
(the executed span counts as one logical family with three sub-events).
"""
def event_families, do: @event_families
```
Note: `@doc since:` must be `"1.1.0"` (not `"1.0.0"`) because this module ships in v1.1.

**`allowed_public_keys/1` pattern** (analog lines 157-165) — supports both list and atom dispatch:
```elixir
def allowed_public_keys(family) when is_list(family) do
  family |> family_key() |> allowed_public_keys()
end

def allowed_public_keys(family) when is_atom(family) do
  Map.fetch!(@allowed_public_keys, family)
end
```

---

### `test/parapet/telemetry/recovery_action_test.exs` (test, module-introspection)

**Analog:** `test/parapet/telemetry/async_delivery_test.exs`

**Module head + alias** (analog lines 1-4):
```elixir
defmodule Parapet.Telemetry.RecoveryActionTest do
  use ExUnit.Case, async: true

  alias Parapet.Telemetry.RecoveryAction
```
`async: true` is correct — pure module introspection, no DB, no process state.

**Event families assertion test** (analog lines 6-15):
```elixir
test "exposes the six locked public event families" do
  assert AsyncDelivery.event_families() == [
           [:parapet, :delivery, :outbound],
           ...
         ]
end
```
New test title: `"exposes the eight frozen recovery action event families"`. Uses `==` (exact ordered list match), not `in` membership. The list enumerates all 8 concrete tuples in declaration order.

**Vocab normalization test** (analog lines 17-30):
```elixir
test "normalizes bounded delivery and async outcomes only" do
  assert AsyncDelivery.normalize_delivery_outcome(:accepted) == :provider_accepted
  assert_raise ArgumentError, ~r/Unsupported delivery outcome/, fn ->
    AsyncDelivery.normalize_delivery_outcome(:queued)
  end
end
```
New test: `"normalizes bounded outcome, short_circuit_reason, and failure_class atoms only"`. Tests `normalize_outcome/1`, `normalize_short_circuit_reason/1`, `normalize_failure_class/1` — each with a valid atom and an invalid atom raising `ArgumentError`.

**`shape_metadata/2` test** (analog lines 32-52):
```elixir
test "shapes exact identifiers into refs and drops unknown metadata" do
  shaped = AsyncDelivery.shape_metadata(:provider_feedback, %{
    integration: :mailglass, provider: :ses, ...
    provider_message_id: "pm-123",
    raw_payload: %{ignored: true}
  })
  assert shaped.outcome == :provider_accepted
  assert shaped.refs == %{provider_message_ref: "pm-123", recipient_ref: "user-42"}
  refute Map.has_key?(shaped, :raw_payload)
end
```
New test: `"shapes metadata into public keys, builds refs sub-map, and strips private keys"`. Passes a map with a public key (e.g. `capability_id`), a mapped ref key (e.g. `incident_id`), and a private key (e.g. `internal_debug`). Asserts public key retained, `refs.incident_ref` populated, private key absent.

**No emit-site test** (D-16): The file contains exactly these four introspection tests. No `:telemetry.attach`, no `Process.sleep`, no event capture.

---

### `lib/parapet/spine/action_claim.ex` (model, CRUD)

**Analog:** Same file — field addition pattern.

**Existing field declarations to slot into** (lines 30-44):
```elixir
schema "parapet_action_claims" do
  field(:action_kind, :string)
  field(:action_key, :string)
  field(:status, :string, default: "claimed")
  field(:idempotency_key, :string)
  field(:attempt_count, :integer, default: 1)
  field(:claimed_at, :utc_datetime_usec)           # ← insert after this line
  field(:finished_at, :utc_datetime_usec)
  ...
  timestamps(type: :utc_datetime_usec)
end
```
New field slots directly after `claimed_at` (temporal adjacency):
```elixir
field(:lease_until, :utc_datetime_usec)
```

**`cast/3` block** (lines 50-63) — `:lease_until` appended to cast list:
```elixir
|> cast(attrs, [
  :incident_id,
  :action_kind,
  :action_key,
  :status,
  :idempotency_key,
  :attempt_count,
  :claimed_at,
  :lease_until,       # NEW — add after :claimed_at
  :finished_at,
  ...
])
```

**`validate_required/2` block** (lines 64-72) — `:lease_until` appended to required list:
```elixir
|> validate_required([
  :incident_id,
  :action_kind,
  :action_key,
  :status,
  :idempotency_key,
  :attempt_count,
  :claimed_at,
  :lease_until        # NEW — add after :claimed_at
])
```

---

### `lib/parapet/automation/claim_service.ex` (service, CRUD + self-heal)

**Analog:** Same file — three insertion points.

**Insertion point 1: `@default_lease_ms` module attribute** — new constant placed before `def claim_action/1` (after the existing aliases at lines 12-15):
```elixir
@default_lease_ms 5 * 60 * 1_000
```
Private, not exposed as a public function (D-03).

**Insertion point 2: `attrs` map with `lease_until`** (lines 23-35) — the `now:` opt already exists at line 23; compute `lease_until` immediately after `now` binding:
```elixir
now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:microsecond))
# NEW: add this line
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
```

**Insertion point 3: self-heal UPDATE inside `acquire_claim/2`** (lines 74-97) — the self-heal branch slots in between `count == 0` and the existing `repo.one!` select:
```elixir
defp acquire_claim(repo, attrs) do
  {count, rows} =
    repo.insert_all(ActionClaim, [Map.put(attrs, :error_metadata, %{})],
      on_conflict: :nothing,
      conflict_target: [:incident_id, :action_kind, :action_key],
      returning: returning_fields()
    )

  if count == 1 do
    {:won, rows |> returned_claim() |> to_claim()}
  else
    # NEW: attempt expired-lease self-heal before falling through to conflict
    case steal_expired_claim(repo, attrs) do
      {:won, claim} ->
        {:won, claim}

      nil ->
        claim =
          repo.one!(
            from(claim in ActionClaim,
              where:
                claim.incident_id == ^attrs.incident_id and
                  claim.action_kind == ^attrs.action_kind and
                  claim.action_key == ^attrs.action_key
            )
          )
        {:conflicted, claim}
    end
  end
end
```

**New private function `steal_expired_claim/2`** — add after `acquire_claim/2`:
```elixir
defp steal_expired_claim(repo, attrs) do
  now = attrs.claimed_at   # already set to the injected clock
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
        inc: [attempt_count: 1]
      ]
    )
    |> repo.update_all(returning: true)

  if count == 1 do
    {:won, rows |> List.first() |> to_claim()}
  else
    nil
  end
end
```
Note: `update_all(returning: true)` is mandatory — without it Ecto returns `{count, nil}` and the claim struct cannot be returned to the caller.

**Insertion point 4: `:lease_until` in `returning_fields/0`** (lines 163-181):
```elixir
defp returning_fields do
  [
    :id,
    :incident_id,
    :action_kind,
    :action_key,
    :status,
    :idempotency_key,
    :attempt_count,
    :claimed_at,
    :lease_until,          # NEW — add after :claimed_at
    :finished_at,
    ...
  ]
end
```

---

### `test/parapet/automation/claim_service_test.exs` (test, CRUD db-backed)

**Analog:** Same file — new test function alongside existing `@tag :unboxed` tests.

**`@tag :unboxed` + `unboxed_run/1` pattern** (lines 9-83):
```elixir
@tag :unboxed
test "one concurrent caller wins the logical claim and the loser is conflicted" do
  # Application.put_env for config...
  unboxed_run(fn ->
    ConcurrencyBootstrap.reset!()
    {:ok, incident} = %Incident{} |> Incident.changeset(%{...}) |> ConcurrencyRepo.insert()
    # ... test body
  end)
end
```

**New sequential self-heal test follows the same scaffold** — no concurrent Tasks, no `for _ <- 1..2` harness. The entire test body is inside a single `unboxed_run/fn ->` (D-08):
```elixir
@tag :unboxed
test "self-heals an expired-lease stale claim left by a crashed node" do
  unboxed_run(fn ->
    ConcurrencyBootstrap.reset!()

    {:ok, incident} =
      %Incident{}
      |> Incident.changeset(%{title: "Crashed node remnant"})
      |> ConcurrencyRepo.insert()

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
        lease_until: past,       # expired
        inserted_at: past,
        updated_at: past,
        error_metadata: %{}
      })

    assert {:won, claim} =
      ClaimService.claim_action(
        incident_id: incident.id,
        action_kind: "operator",
        action_key: "step-1",
        idempotency_key: "new_key_#{incident.id}"
      )

    assert claim.id == original.id           # update-in-place proof
    assert claim.attempt_count == 2          # bump-counter proof
    assert claim.idempotency_key == "new_key_#{incident.id}"
    assert DateTime.compare(claim.lease_until, DateTime.utc_now()) == :gt
  end)
end
```

**Module-level alias to add** — `ActionClaim` is already aliased at line 7; no changes needed if the insert uses the struct directly.

---

### `test/support/concurrency_bootstrap.ex` (fixture DDL, batch)

**Analog:** Same file — DDL column addition in the `parapet_action_claims` `CREATE TABLE` statement.

**Existing `parapet_action_claims` DDL block** (lines 126-143):
```sql
CREATE TABLE IF NOT EXISTS parapet_action_claims (
  id uuid PRIMARY KEY,
  incident_id uuid NOT NULL REFERENCES parapet_incidents(id) ON DELETE CASCADE,
  action_kind varchar(255) NOT NULL,
  action_key varchar(255) NOT NULL,
  status varchar(255) NOT NULL DEFAULT 'claimed',
  idempotency_key varchar(255) NOT NULL,
  attempt_count integer NOT NULL DEFAULT 1,
  claimed_at timestamp(6) without time zone NOT NULL,
  finished_at timestamp(6) without time zone,
  ...
  inserted_at timestamp(6) without time zone NOT NULL,
  updated_at timestamp(6) without time zone NOT NULL
)
```

**Column addition** — insert `lease_until` immediately after `claimed_at` (temporal adjacency):
```sql
claimed_at timestamp(6) without time zone NOT NULL,
lease_until timestamp(6) without time zone NOT NULL,   -- NEW
finished_at timestamp(6) without time zone,
```

**Index addition** — add a new DDL string to the `ddl_statements/0` list after the existing `parapet_action_claims_status_claimed_at_index` entry (lines 148-151):
```sql
CREATE INDEX IF NOT EXISTS parapet_action_claims_lease_until_claimed_index
ON parapet_action_claims (lease_until)
WHERE status = 'claimed'
```
The DDL index name must match the migration index name: `parapet_action_claims_lease_until_claimed_index`.

**Existing index DDL convention** (lines 144-151) to follow:
```elixir
"""
CREATE UNIQUE INDEX IF NOT EXISTS parapet_action_claims_incident_id_action_kind_action_key_index
ON parapet_action_claims (incident_id, action_kind, action_key)
""",
"""
CREATE INDEX IF NOT EXISTS parapet_action_claims_status_claimed_at_index
ON parapet_action_claims (status, claimed_at)
""",
```

---

### `docs/telemetry.md` (documentation, section insert)

**Analog:** Same file — section insertion after line 137 (end of `## Semantic Guarantees`).

**File-level Stable header to NOT touch** (lines 1-10):
```markdown
# Telemetry Event Schema

> #### Stable Contract {: .info}
>
> This telemetry reference is **stable** as of v1.0.0. Event names under
> `[:parapet, …]` are frozen — renaming or removing them is a semver-major change.
```
This header must remain verbatim. The new Experimental section is subordinate to it.

**`## Semantic Guarantees` insertion anchor** (lines 131-137):
```markdown
## Semantic Guarantees

- `provider_accepted` is not the same as `delivered`.
...
- Public metadata is intentionally narrower than the upstream integration payloads.
```

**New section placement:** Append after line 137 (after the last bullet of Semantic Guarantees). The new section heading is:
```markdown
## Recovery Action Family (Experimental)
```

**Section structure to follow** — mirrors the "Async And Delivery Families" section structure:
1. Opening Experimental admonition (callout box)
2. Per-event subsections with `###` heading, **Measurements**, and **Metadata** bullet lists
3. Vocab subsection enumerating closed atom values

**Opening Experimental admonition shape** (from `docs/stability.md` tier definitions):
```markdown
> #### Experimental {: .warning}
>
> This event family is **experimental** in v1.x. Event names, measurement keys, and
> metadata keys may change in a minor release with a single CHANGELOG entry. See
> [Stability & Deprecation Policy](stability.html) for details.
```

**Per-event subsection shape to copy from existing section** (lines 31-43):
```markdown
#### `[:parapet, :delivery, :outbound]`
Emitted when Parapet observes an outbound provider handoff attempt.

**Measurements:**
- `count` (integer) - Defaults to `1`.
- `duration_ms` (integer) - Duration in milliseconds.

**Metadata:**
- `integration` - Adapter name such as `:mailglass`.
```

New section must enumerate all 7 logical event families (D-10) with their D-11 measurement keys and D-12 metadata keys.

---

### `docs/stability.md` (documentation, table row insert)

**Analog:** Same file — row insertion into the Experimental Modules table.

**Table header** (lines 44-46):
```markdown
| Module | Description |
|--------|-------------|
```

**Existing row format template** (line 48 area):
```markdown
| `Parapet.MCP.PrometheusClient` | Prometheus query client for MCP |
| `Parapet.Automation.CircuitBreaker` | Ecto-backed circuit breaker for mitigations |
```

**New row to insert** — between `Parapet.MCP.PrometheusClient` and `Parapet.Automation.CircuitBreaker` (line 49 per CONTEXT D-14):
```markdown
| `Parapet.Telemetry.RecoveryAction` | Machine-readable recovery action telemetry contract |
```

Description pattern: mirrors the existing `Parapet.Telemetry.AsyncDelivery` Stable row (`docs/stability.md` line 38):
```markdown
| `Parapet.Telemetry.AsyncDelivery` | Machine-readable async/delivery telemetry contract |
```

---

## Shared Patterns

### Experimental Admonition (`@moduledoc` + `verify.public_api`)

**Source:** `lib/parapet/automation/claim_service.ex` lines 3-10 (canonical shape) and `lib/parapet/spine/action_claim.ex` lines 3-10.

**Apply to:** `lib/parapet/telemetry/recovery_action.ex`

```elixir
@moduledoc """
[module description sentence]

> #### Experimental {: .warning}
>
> This module is **experimental** in v1.x. Its API may change in a minor release with a
> single-version notice in CHANGELOG.md. See
> [Stability & Deprecation Policy](stability.html) for details.
"""
```

`verify.public_api` detection regex (from `lib/mix/tasks/verify.public_api.ex:110`):
```elixir
~r/####\s+Experimental\s*\{:\s*\.warning\}/
```
Exactly `####` (4 hashes). No `@stability` attribute — admonition is the single source of truth.

---

### `now:` Test-Injection Opt

**Source:** `lib/parapet/automation/claim_service.ex` line 23.

**Apply to:** `claim_service.ex` lease computation (same file, same function).

```elixir
now = Keyword.get(opts, :now, DateTime.utc_now() |> DateTime.truncate(:microsecond))
```

The self-heal test passes `now:` to simulate an expired lease without wall-clock dependency. All datetime values derived from `now` (including `lease_until`) must use this same `now` binding.

---

### `unboxed_run/1` + `ConcurrencyBootstrap.reset!()` Test Scaffold

**Source:** `test/parapet/automation/claim_service_test.exs` lines 9-28.

**Apply to:** new expired-lease test in `claim_service_test.exs`.

```elixir
@tag :unboxed
test "..." do
  unboxed_run(fn ->
    ConcurrencyBootstrap.reset!()
    {:ok, incident} = %Incident{} |> Incident.changeset(%{...}) |> ConcurrencyRepo.insert()
    # ... test body with ConcurrencyRepo
  end)
end
```

Every interaction with the DB in a concurrency test must be inside `unboxed_run/fn ->`. `ConcurrencyBootstrap.reset!()` must be the first line inside.

---

### `normalize_enum/3` + `normalize_key/1` Private Helpers

**Source:** `lib/parapet/telemetry/async_delivery.ex` lines 285-298.

**Apply to:** `lib/parapet/telemetry/recovery_action.ex`

Copy verbatim — these are the atom/string normalization primitives shared by all vocab guard functions:
```elixir
defp normalize_enum(value, mapping, label) do
  key = normalize_key(value)
  case Map.fetch(mapping, key) do
    {:ok, normalized} -> normalized
    :error -> raise ArgumentError, "Unsupported #{label}: #{inspect(value)}"
  end
end

defp normalize_key(value) when is_atom(value), do: value
defp normalize_key(value) when is_binary(value), do: value |> String.trim() |> String.to_atom()
```

---

### `extract_known_refs/1` + `merge_explicit_refs/2` + `maybe_put/3` Private Helpers

**Source:** `lib/parapet/telemetry/async_delivery.ex` lines 264-328.

**Apply to:** `lib/parapet/telemetry/recovery_action.ex`

The `shape_metadata/2` plumbing — copy the structure, substitute `@known_ref_mappings` with the four recovery-action ref mappings (`incident_id → :incident_ref`, `claim_id → :claim_ref`, `step_id → :step_ref`, `preview_id → :preview_ref`):
```elixir
defp extract_known_refs(metadata) do
  Enum.reduce(@known_ref_mappings, %{}, fn {source_key, ref_key}, refs ->
    case Map.get(metadata, source_key) do
      nil -> refs
      value -> Map.put(refs, ref_key, value)
    end
  end)
end

defp merge_explicit_refs(refs, explicit_refs) when is_map(explicit_refs) do
  explicit_refs
  |> Enum.reduce(refs, fn {key, value}, acc ->
    normalized_key = normalize_ref_key(key)
    if normalized_key in @allowed_ref_keys, do: Map.put(acc, normalized_key, value), else: acc
  end)
end
```

---

## No Analog Found

All 9 files have close analogs. No entries in this section.

---

## Metadata

**Analog search scope:** `lib/parapet/telemetry/`, `lib/parapet/automation/`, `lib/parapet/spine/`, `test/parapet/telemetry/`, `test/parapet/automation/`, `test/support/`, `priv/repo/migrations/`, `docs/`
**Files scanned:** 9 analog files read in full
**Pattern extraction date:** 2026-05-27
