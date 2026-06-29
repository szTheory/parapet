# v1.7 — Schema-Prefix Mechanism & Propagation (PREFIX-CORE + PREFIX-PROP)

**Dimension owner hat:** principal Elixir/Ecto library architect
**Status:** implementation-ready recommendation
**Date:** 2026-06-29
**Confidence:** HIGH (Ecto behavior cross-checked against official precedence docs; prior-art from Oban/Triplex/Ash/Apartment/django-tenants)

---

## Summary recommendation (decisive)

Introduce a single shared base macro `Parapet.Spine.Schema` that every spine schema does `use Parapet.Spine.Schema` (replacing `use Ecto.Schema`). The base macro `use`s `Ecto.Schema`, imports `Ecto.Changeset`, sets `@foreign_key_type :binary_id`, and — critically — sets `@schema_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")` **normalized so that `nil` and `"public"` both collapse to `nil`** (unprefixed semantics). This is the *only* place the prefix is ever named. Because `@schema_prefix` is baked onto the compiled struct, it **auto-propagates** with zero call-site changes to `Repo.all/get/insert/update/delete`, to `insert_all(ActionClaim, …)` (the `claim_service.ex` write path uses the *schema module*, so it inherits the prefix), to every `Ecto.Multi` step in `evidence.ex`, and to cross-schema joins (every spine schema carries the *same* prefix, so the join planner never spans two schemas). Runtime `prefix:` repo options stay **banned** because Ecto's read/write precedence is deliberately asymmetric — a stray runtime `prefix:` silently wins on writes but can lose on reads, producing a split-brain where you write to schema A and read from schema B in the same logical operation. Enforce the ban with a compile-/test-time static guard (a grep-style AST/regex check over `lib/`) plus a property test asserting the prefix on a built struct equals the configured prefix. This coheres cleanly with the upgrade-path, generator, and test dimensions: the macro is the single seam, the generator emits a migration that creates the same named schema, and the test suite pins the contract.

---

## 1. Mechanism comparison

Four candidate mechanisms for putting the six spine tables in a `parapet` Postgres schema. Ecto's own precedence rules are the deciding evidence (see §3 for the proof of asymmetry).

| Mechanism | How it works | Pros | Cons / tradeoffs | Idiomatic when |
|---|---|---|---|---|
| **Compile-time `@schema_prefix`** (RECOMMENDED, locked) | Module attribute baked onto the compiled schema; Ecto stamps it on every built struct and on `from`/`join` for that schema. | Zero call-site changes; impossible to forget at a call site; single source of truth; survives `insert_all`, `Multi`, joins; reads *and* writes agree because the prefix is intrinsic to the schema, not the call. | Prefix is fixed at compile time (cannot vary per-request) — but Parapet is single-tenant-per-host, so this is a *feature*, not a limit. Requires `Application.compile_env` + a recompile on change (Ecto/Mix already warns if compile_env drifts). | The prefix is a *deployment-wide* constant, not per-request. Exactly Parapet's case. |
| **Runtime `prefix:` repo option** (BANNED) | Pass `prefix: "parapet"` to every `Repo.all/insert/...` and into every query/changeset. | Can vary per call (needed for true multitenancy). | **Split-brain footgun** (§3.4): write precedence ≠ read precedence, so a missed or mismatched `prefix:` writes one schema and reads another. Must be threaded through *every* call site (Oban/Triplex both pay this tax). Invisible drift; no compile-time safety. | Genuine per-request tenancy (Triplex, Oban multi-instance). Not Parapet. |
| **Connection `search_path`** (BANNED, locked) | `SET search_path = parapet, public` on each checked-out connection. | No schema annotations needed anywhere; "just works" for unqualified table names. | Tenant-leak risk if a pooled/threaded connection doesn't reset (Rails Apartment's exact motivation to *abandon* it in v4); per-statement `SET` cost (django-tenants' `TENANT_LIMIT_SET_CALLS`); breaks `public`-resident extensions unless `public` stays on the path; fights PgBouncer/RDS Proxy in transaction mode; hides the prefix from the schema (un-inspectable, violates host-owned DNA). | Heavy multi-tenant SaaS that already owns the connection lifecycle. Anti-pattern for a *library* embedded in someone else's repo. |
| **Separate dedicated Repo** | A second `Parapet.Repo` with its own config, possibly a different database/role. | Hard isolation; separate pool/credentials. | Host must configure/migrate/supervise a second repo; cross-repo transactions impossible (the `evidence.ex` Multi spanning incident+timeline+audit+escalation-job would break); violates "host owns the repo" DNA; massive DX cost for a pure namespacing goal. | You actually need a *different database or credentials*, not just a schema. Overkill here. |

**Worked examples**

Compile-time `@schema_prefix` (recommended):

```elixir
defmodule Parapet.Spine.Incident do
  use Parapet.Spine.Schema          # sets @schema_prefix "parapet" (normalized)
  schema "parapet_incidents" do ... end
end

# Call sites are UNCHANGED — prefix rides the struct:
Evidence.repo().insert(%Incident{title: "x"} |> Incident.changeset(...))
# => INSERT INTO "parapet"."parapet_incidents" ...
Evidence.repo().all(from i in Incident, where: i.state == "open")
# => SELECT ... FROM "parapet"."parapet_incidents" AS i0 ...
```

Runtime `prefix:` (banned — shown for contrast):

```elixir
# EVERY call site must remember the prefix, forever:
Evidence.repo().insert(changeset, prefix: "parapet")
Evidence.repo().all(query, prefix: "parapet")
Evidence.repo().insert_all(ActionClaim, rows, prefix: "parapet", on_conflict: :nothing)
# Miss one -> writes/reads land in `public`. No compiler help.
```

Connection `search_path` (banned — shown for contrast):

```elixir
# In the host's Repo (host-owned, but now Parapet dictates connection state):
after_connect: {Postgrex, :query!, ["SET search_path = parapet, public", []]}
# Breaks the moment a background task / PgBouncer txn-mode connection skips it.
```

**Verdict:** the locked compile-time `@schema_prefix` choice is *correct and confirmed*. It is the only mechanism that makes reads and writes agree by construction, needs no call-site edits, and keeps the prefix inspectable in host-owned schema files. Confidence: HIGH.

---

## 2. Shared macro design (`Parapet.Spine.Schema`)

### 2.1 The macro

```elixir
defmodule Parapet.Spine.Schema do
  @moduledoc """
  Shared base for all Parapet spine schemas.

  Replaces `use Ecto.Schema` in `Parapet.Spine.*`. Centralizes the Postgres
  schema prefix so the *only* place the prefix is named is here. The prefix is
  resolved at **compile time** from `config :parapet, :schema_prefix` (default
  `"parapet"`). `nil` or `"public"` mean "no prefix" — i.e. legacy/`public`
  behavior, which existing adopters opt into.

  Runtime `prefix:` repo options are BANNED (see PREFIX ban guard); the prefix
  is an internal DB detail and is not part of the frozen public API or telemetry
  contract.
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      # binary_id is the spine-wide convention (all six schemas already use it).
      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      # Compile-time prefix. Normalized so nil/"public" => nil (unprefixed).
      @schema_prefix Parapet.Spine.Schema.__prefix__()
    end
  end

  @doc false
  # Resolved once, at compile time. Application.compile_env records the read so
  # Mix raises if the value drifts between compile and runtime — exactly the
  # safety we want for an intrinsic, baked-in attribute.
  def __prefix__ do
    case Application.compile_env(:parapet, :schema_prefix, "parapet") do
      nil -> nil
      "" -> nil
      "public" -> nil
      other when is_binary(other) -> other
      other when is_atom(other) -> Atom.to_string(other)
    end
  end
end
```

Notes:
- `__prefix__/0` is a normal function so the normalization logic is testable directly and is shared by the ban-guard test and any `mix parapet.doctor` check.
- `Application.compile_env/3` (not `get_env`) is mandatory: it pins the value at compile time and makes Mix emit a `:badarg`/drift error if config changes without a recompile — which is the correct failure mode for a baked attribute.
- `"public"` → `nil`: emitting `@schema_prefix "public"` would *also* work (Postgres resolves `public.parapet_incidents`), but `nil` is the cleaner "legacy semantics" signal and produces byte-identical SQL to pre-v1.7. Collapsing to `nil` guarantees the opt-out is a true no-op.

### 2.2 One migrated schema, before/after

Before (today):

```elixir
defmodule Parapet.Spine.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "parapet_incidents" do
    field(:title, :string)
    # ...
    timestamps(type: :utc_datetime_usec)
  end
end
```

After (v1.7):

```elixir
defmodule Parapet.Spine.Incident do
  use Parapet.Spine.Schema      # <- replaces `use Ecto.Schema` + import + @primary_key + @foreign_key_type

  schema "parapet_incidents" do
    field(:title, :string)
    # ...
    timestamps(type: :utc_datetime_usec)
  end
end
```

The diff per schema is small and *removes* the repeated `@primary_key`/`@foreign_key_type` boilerplate that all six already duplicate, so the change is a net simplification, not just an addition.

> Constraint imposed on the migration/generator dimension: the table name stays `parapet_incidents` (unqualified). The schema lives in the `parapet` *Postgres schema*. Final identifier is `"parapet"."parapet_incidents"`. The double "parapet" is intentional and harmless; renaming tables is out of scope for v1.7 and would be a needless breaking change.

### 2.3 Edge-case interactions

- **`@primary_key` / `binary_id`:** Orthogonal to `@schema_prefix`. The prefix scopes the *table namespace*; the primary key type is unaffected. Setting both in the macro is safe and matches today's per-file declarations exactly. `Ecto.UUID` generation, `autogenerate: true`, and `:binary_id` all behave identically.
- **`belongs_to` / `references` / associations:** Per Ecto's docs, struct insert/update propagate the *parent's* prefix to associated data, and a schema's `@schema_prefix` applies whenever it appears in a `from`/`join`. Because **all six schemas carry the same prefix**, every `belongs_to(:incident, Incident)` and every join resolves both sides in `parapet`. There is no cross-schema FK: the migration's `references(:parapet_incidents, ...)` is emitted *inside* the `parapet` schema (constraint on the migration dimension below), so the FK target is `parapet.parapet_incidents`. Associations need **no** annotation.
- **`foreign_key_type :binary_id`:** Already required by all spine FKs; centralizing it in the macro is a pure dedup. No interaction with the prefix.
- **`timestamps(type: :utc_datetime_usec)`:** Unaffected by prefix.

> Constraint imposed on the migration dimension: the `references/2` calls in the generated migration must target tables that live in the same `parapet` schema. With `create schema parapet` + tables created `prefix: "parapet"` (or under a migration-level prefix), the FKs are intra-schema and `on_delete: :delete_all` works unchanged. Do **not** split spine tables across schemas.

---

## 3. Propagation correctness — proof + failure points

Ecto's precedence rules (quoted from the official "Multi tenancy with query prefixes" guide):

> **Reads** — "the `:prefix` option in query operations (`all/2`, `update_all/2`, and `delete_all/2`) is a fallback." Effective order: `from`/`join` prefix → `@schema_prefix` → repo `:prefix` option → connection prefix.
>
> **Writes** — "the `:prefix` option in schema operations (`insert_all/3`, `insert/2`, `update/2`, etc) will override the `@schema_prefix`." Effective order: `:prefix` option → changeset/struct prefix → `@schema_prefix` → connection prefix.

The design rationale, quoted: *"we want to allow flexibility when writing queries but we want to enforce struct/changeset operations to always work isolated within a given prefix."*

This is the **read/write precedence asymmetry** the locked decision is built around. With **no** runtime `prefix:` anywhere (enforced in §4), `@schema_prefix` is the highest *active* layer for both reads and writes, so reads and writes always agree. The asymmetry only bites when a runtime `prefix:` is introduced — which is exactly why it's banned.

### 3.1 `Repo.all/get/insert/update/delete` — PROVEN auto-propagates

```elixir
Evidence.repo().insert(Incident.changeset(%Incident{}, %{title: "x"}))
# build %Incident{} carries @schema_prefix "parapet" => INSERT INTO "parapet"."parapet_incidents"
Evidence.repo().get(Incident, id)         # @schema_prefix on the queryable => SELECT ... FROM "parapet"....
Evidence.repo().update(changeset)         # struct prefix preserved
Evidence.repo().delete(struct)            # struct prefix preserved
from(i in Incident, where: ...) |> Evidence.repo().all()  # from carries @schema_prefix
```
All of `operator.ex`, `evidence/retrospective.ex`, `escalation/worker.ex`, `automation/executor.ex`, `mcp/server.ex`, `notifier/oban_worker.ex`, `evidence/archiver.ex`, `system_event_pruner.ex` use **schema modules** in `from`/`get`/`all`/`delete_all`. Every one inherits the prefix with **zero edits**. Confidence: HIGH.

### 3.2 `insert_all(ActionClaim, …)` — PROVEN propagates *because the first arg is a schema module*

`claim_service.ex:111`:
```elixir
repo.insert_all(ActionClaim, [Map.put(attrs, :error_metadata, %{})],
  on_conflict: :nothing,
  conflict_target: [:incident_id, :action_kind, :action_key],
  returning: returning_fields()
)
```
When `insert_all`'s first argument is a **schema module** (`ActionClaim`), Ecto reads that schema's `@schema_prefix` and emits `INSERT INTO "parapet"."parapet_action_claims"`. No change needed. ✅

> **FAILURE POINT (must-not-regress):** if anyone ever rewrites this to a **string table name** — `insert_all("parapet_action_claims", rows)` — Ecto has **no schema to read the prefix from**, so it lands in `public` (or wherever the connection points). Same for `update_all`/`delete_all` with a raw `{"table", Schema}` source where the binary is used. Guard: the ban check in §4 also flags `insert_all(`/`update_all(`/`delete_all(` whose first arg is a **string literal**. Today there are zero such call sites — keep it that way.

### 3.3 `Ecto.Multi` (evidence.ex + alert_processor.ex + escalation/worker.ex) — PROVEN propagates

`Ecto.Multi` carries no prefix of its own; each step is an ordinary `insert`/`update`/`run` on a changeset or struct, so each step inherits the prefix from its schema:

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:incident, Incident.changeset(%Incident{}, attrs))      # parapet.parapet_incidents
|> Ecto.Multi.insert(:timeline_entry, fn %{incident: i} ->
     TimelineEntry.changeset(%TimelineEntry{}, %{incident_id: i.id, ...})     # parapet.parapet_timeline_entries
   end)
|> Ecto.Multi.insert(:tool_audit, fn %{...} -> ToolAudit.changeset(...) end)  # parapet.parapet_tool_audits
|> repo().transaction()
```
The escalation-job step (`apply(worker, :new, [...])`) inserts an **Oban** job, which is the host's Oban schema with its **own** (host-owned) prefix — it is *not* a Parapet spine schema and must not inherit `parapet`. This is correct: Parapet's prefix scopes only the six spine schemas. ✅ No change needed in any Multi.

`Ecto.Multi.run/3` steps that call `repo` directly (e.g. `evidence.ex` broadcast steps) only emit telemetry — no DB write — so prefix is moot there.

### 3.4 Cross-schema joins — PROVEN propagates (all sides same prefix)

Two join sites in `lib/`:
- `mcp/server.ex:38` — `from(t in TimelineEntry, join: i in Incident, on: t.incident_id == i.id, ...)`
- `automation/circuit_breaker.ex:53` — `from(a in ToolAudit, join: t in TimelineEntry, on: a.timeline_entry_id == t.id, ...)`

Both joined schemas are spine schemas with the **same** `@schema_prefix "parapet"`, so the generated SQL is:
```sql
SELECT ... FROM "parapet"."parapet_timeline_entries" AS t0
  INNER JOIN "parapet"."parapet_incidents" AS i1 ON t0."incident_id" = i1."id"
```
Both legs land in `parapet`. ✅ No edits. This is the key advantage of the **uniform** prefix: there is never a join that spans `parapet` and `public`, so the read-side precedence (`join` prefix wins) and the schema prefix coincide.

> **FAILURE POINT (would only arise if the design were violated):** a join between a spine schema (prefixed) and a host/`public` schema (unprefixed) would force you to set per-binding `from`/`join` prefixes by hand, and the read precedence (`from`/`join` > `@schema_prefix`) would silently override. v1.7 keeps **all** spine tables in one schema, so this cannot occur for spine↔spine. Any future "spine joins a host table" feature must use explicit qualified references and is out of v1.7 scope. Note for the test dimension: add a regression test asserting both existing join queries emit `parapet`-qualified SQL on both sides.

### 3.5 Fragments / raw SQL — care needed but currently SAFE

`fragment("?->>'step_id' = ?", t.payload, ...)` (circuit_breaker, operator) reference **columns of an already-prefixed binding** (`t.payload`), not table names, so they inherit the binding's prefix. ✅
There is **no** raw `Repo.query!`/string-table SQL touching spine tables in `lib/` (grep confirms only `fragment/...` column refs). 

> **FAILURE POINT:** any future raw `Repo.query("SELECT ... FROM parapet_incidents")` would hard-code an **unqualified** table name and bypass the prefix entirely. Guard: the §4 check should also flag string SQL mentioning a `parapet_` table name. Currently zero such sites.

### Propagation scorecard

| Call path | Propagates? | Why | Action |
|---|---|---|---|
| `Repo.all/get/insert/update/delete` (schema module/struct) | ✅ | prefix intrinsic to struct/queryable | none |
| `insert_all(Schema, …)` | ✅ | schema module supplies prefix | none; guard against string-table form |
| `update_all/delete_all` (query over schema) | ✅ | `from` carries prefix | none |
| `Ecto.Multi` steps | ✅ | each step is a normal struct/changeset op | none |
| spine↔spine joins | ✅ | both sides same `@schema_prefix` | regression test |
| Oban escalation-job insert in Multi | ✅ (host prefix, by design) | not a spine schema | none |
| `fragment` on a bound column | ✅ | column ref under prefixed binding | none |
| `insert_all("string_table", …)` | ❌ | no schema to read prefix | **ban via guard** |
| raw `Repo.query` string SQL | ❌ | bypasses Ecto entirely | **ban via guard** |

---

## 4. Banning runtime `prefix:` (enforcement)

Two complementary guards. Both are cheap and live in CI alongside the existing `mix verify.public_api` discipline.

### 4.1 Static guard — `mix verify.no_runtime_prefix` (or a test)

A focused source scan over `lib/` (and the generator templates) that fails the build if it finds:
1. `prefix:` passed to any `Repo`/`repo` call (the literal runtime-prefix footgun),
2. `insert_all(`/`update_all(`/`delete_all(` whose **first argument is a string literal** (string-table form that drops the prefix),
3. `search_path` anywhere (the banned connection mechanism),
4. raw SQL string literals containing a `parapet_` table name.

Implementable as a tiny Mix task or, more idiomatically, as a test that reads the files (no new build task to maintain). Test form:

```elixir
defmodule Parapet.Spine.PrefixBanTest do
  use ExUnit.Case, async: true

  @lib_files Path.wildcard("lib/**/*.ex")

  test "no runtime prefix: option is threaded through repo calls" do
    offenders =
      for path <- @lib_files,
          src = File.read!(path),
          # `prefix:` appearing in a repo operation context
          Regex.match?(~r/\brepo(\(\))?\.\w+\([^)]*\bprefix:/, src) or
            Regex.match?(~r/\bRepo\.\w+\([^)]*\bprefix:/, src),
          do: path

    assert offenders == [],
           "Runtime `prefix:` is banned (compile-time @schema_prefix only). Offenders: #{inspect(offenders)}"
  end

  test "insert_all/update_all/delete_all never use a string table name" do
    offenders =
      for path <- @lib_files,
          src = File.read!(path),
          Regex.match?(~r/\b(insert_all|update_all|delete_all)\(\s*"/, src),
          do: path

    assert offenders == [], "Spine writes must pass a schema module, not a string table. Offenders: #{inspect(offenders)}"
  end

  test "no connection search_path manipulation in the library" do
    offenders = for p <- @lib_files, String.contains?(File.read!(p), "search_path"), do: p
    assert offenders == []
  end
end
```

(A regex test is honest about being a heuristic; an AST/`Macro`-based walk via `Code.string_to_quoted/1` is the rigorous upgrade if false positives appear. Start with regex — zero current offenders means it's green from day one.)

### 4.2 Contract guard — prefix is what config says

A positive test pinning the intrinsic prefix (also catches a future accidental `use Ecto.Schema` regression on a spine schema):

```elixir
test "every spine schema carries the configured prefix" do
  expected = Parapet.Spine.Schema.__prefix__()   # "parapet" by default
  for mod <- [Incident, ActionItem, TimelineEntry, ToolAudit, SystemEvent, ActionClaim] do
    assert mod.__schema__(:prefix) == expected
  end
end
```

`Ecto.Schema` exposes `__schema__(:prefix)` — use it; no struct-building needed. This is the cleanest assertion and doubles as documentation of the contract.

> Constraint imposed on the test dimension: these three+one tests are the PREFIX contract. They should run `async: true` and be fast. The opt-out path (`config :parapet, schema_prefix: nil`) must be covered by compiling a fixture in a separate test app or by asserting `__prefix__/0` normalization directly (unit-level), since `@schema_prefix` is compile-time and can't be flipped at runtime in one suite.

---

## 5. Prior-art lessons (cited)

**Ecto `@schema_prefix` (official guide).** Confirms the precise read/write precedence asymmetry this design exploits and the rationale ("enforce struct/changeset operations to always work isolated within a given prefix"). The right call is to let `@schema_prefix` be the single highest active layer. *Source: Ecto "Multi tenancy with query prefixes" + `Ecto.Schema` docs.* Confidence: HIGH.

**Oban (`Oban.Migration` / `prefix`).** Oban uses a **runtime** `prefix` option threaded through config, migrations (`Oban.Migrations.up(prefix: "private")`), and job insert/exec, plus `create_schema`. It gets *real multitenancy* (multiple isolated instances on one DB) — but pays the price Parapet refuses: prefix must be specified in every layer, and the table/notifications isolation only holds if every site agrees. **Lesson taken:** copy Oban's `create_schema: false` least-privilege escape hatch (already locked) and its migration-creates-the-schema pattern; **reject** its runtime-prefix threading because Parapet is single-tenant-per-host and wants zero call-site burden. *Source: Oban.Migration / Oban docs (v2.18–2.23).* Confidence: HIGH.

**Triplex.** Pure **runtime** `prefix:` per call (`Repo.all(User, prefix: Triplex.to_prefix("t"))`). Demonstrates the call-site tax and a migration footgun (Ecto 3 async migrations can't run inside a transaction). **Lesson:** runtime prefix is right for *dynamic* tenancy and wrong for a *static* namespace; the moment the prefix is a deployment constant, baking it into `@schema_prefix` removes an entire class of "forgot the prefix" bugs. *Source: Triplex hexdocs.* Confidence: HIGH.

**Ash multitenancy (`:context` schema strategy).** Threads tenant per-query/per-changeset (`Ash.Query.set_tenant/2`), with a documented footgun: a plug ordering mistake silently operates on the wrong/no tenant. Reinforces that *any* runtime-threaded prefix has an "easy to wire wrong, fails silently" failure mode. **Lesson:** silent-failure surfaces are the enemy; compile-time baking eliminates the surface. *Source: Ash multitenancy hexdocs.* Confidence: MEDIUM (guide is data-layer-deferred).

**Rails `apartment` gem (cross-language, what NOT to do).** Historically relied on `SET search_path` on shared pooled connections; v4 **abandoned** that model because (a) tenant context could *leak* across requests when a connection didn't reset (a "disastrous" security bug), (b) background threads reset to `public`, (c) RDS Proxy / pooled connections broke the `search_path` tracking. They moved to pool-per-tenant. **Lesson:** this is the empirical case *against* the connection-`search_path` mechanism — exactly the locked "no `search_path`" decision, validated by a mature ecosystem's painful retreat. *Source: rails-on-services/apartment GitHub (Discussion #312, v4 release notes), Influitive engineering writeups.* Confidence: HIGH.

**django-tenants (cross-language).** Sets `search_path` inside `_cursor()` on **every** DB operation, with a `TENANT_LIMIT_SET_CALLS` flag to mitigate the per-statement cost, and a two-pass migration split (shared apps vs tenant apps). **Lesson:** per-statement `SET search_path` has a measurable performance tax and forces a bespoke migration router — overhead Parapet avoids entirely by qualifying the table at compile time. *Source: django-tenants readthedocs / GitHub.* Confidence: HIGH.

**Net prior-art synthesis:** every ecosystem that needs *dynamic* tenancy reaches for runtime prefix or `search_path` and then spends years hardening against leak/perf/threading footguns. Parapet needs only a *static* namespace, so it should take the path none of them can: compile-time `@schema_prefix`, uniform across all spine schemas, with zero runtime threading.

---

## 6. Open risks for the executor

1. **`Application.compile_env` drift.** If a host changes `:schema_prefix` after compiling, Mix raises on boot (good — fail loud). Document that changing the prefix requires `mix deps.compile parapet --force` (or a clean build) **and** a data migration. The generator/upgrade dimension owns the migration; this dimension owns the recompile note.
2. **Opt-out must be byte-identical to legacy.** Verify (golden SQL test) that `schema_prefix: nil` produces SQL with **no** schema qualifier — identical to pre-v1.7 — so existing adopters who opt out see zero behavioral change. Normalizing `"public"`→`nil` is what guarantees this.
3. **`insert_all`/raw-SQL regression risk over time.** The §4 string-table and raw-SQL guards are the only thing standing between "all prefixed" and a silent `public` leak. Keep them in CI permanently; they're currently green.
4. **Oban escalation job must NOT inherit `parapet`.** The `evidence.ex` Multi inserts an Oban job; that schema is host-owned with its own prefix. Confirm via a test that the escalation-job insert targets the Oban prefix, not `parapet` (it will, because it's not a spine schema — but pin it).
5. **`__schema__(:prefix)` is the contract assertion** — prefer it over building structs; it's stable Ecto API ≥ 3.x and works under `~> 3.10`.
6. **Migration FK targets.** All `references/2` must resolve within `parapet`. If the migration creates the schema and tables under one prefix, intra-schema FKs are automatic — but a hand-edited migration that qualifies one table and not another would break FK creation. Flag to the migration dimension.

---

## 7. How this coheres with adjacent dimensions (constraints imposed)

- **Upgrade-path dimension:** the macro is the single seam; the upgrade path is "set `config :parapet, schema_prefix: ...`, recompile, run the rename/move migration." Existing adopters set `schema_prefix: nil` (or omit and ship a migration that keeps tables in `public`) to opt out — but per the locked decision, *existing adopters opt in only*, so the upgrade-path doc must make `schema_prefix: nil` the documented "stay on public" one-liner, and `compile_env` drift means they must recompile. **Constraint:** the prefix value is compile-time; the upgrade path cannot flip it without a recompile.
- **Generator dimension:** `mix parapet.gen.spine` must (a) emit `config :parapet, schema_prefix: "parapet"` for new installs, (b) emit a migration that `CREATE SCHEMA IF NOT EXISTS parapet` (honoring `create_schema: false`) and creates the six tables **under that schema** (migration-level `prefix:` or `create table(..., prefix: "parapet")`), keeping all `references/2` intra-schema. **Constraint:** table names stay `parapet_*` (unqualified); the Postgres schema is `parapet`; spine tables never split across schemas.
- **Test dimension:** owns the four PREFIX contract tests in §4 (ban-static, string-table-ban, search_path-ban, `__schema__(:prefix)` positive) + the two join-SQL regression tests in §3.4 + the golden "opt-out = no qualifier" SQL test in §6.2. **Constraint:** tests must cover both `parapet` and `nil` prefix configs; the `nil` case needs a compile-time fixture or unit-level `__prefix__/0` assertion.
- **Public-API / telemetry freeze:** the prefix is an internal DB detail. It must **not** appear in any public function signature or telemetry metadata. `mix verify.public_api` and the telemetry contract test stay green untouched. **Constraint:** do not expose `schema_prefix` through `Evidence` or any public module.

---

### Sources

- [Ecto — Multi tenancy with query prefixes](https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html)
- [Ecto.Schema (`@schema_prefix`)](https://ecto.hexdocs.pm/Ecto.Schema.html)
- [Oban.Migration](https://oban.hexdocs.pm/Oban.Migration.html) · [Oban](https://hexdocs.pm/oban/Oban.html) · [Oban.Job](https://hexdocs.pm/oban/Oban.Job.html)
- [Triplex](https://triplex.hexdocs.pm/Triplex.html)
- [Ash multitenancy](https://ash.hexdocs.pm/multitenancy.html)
- [rails-on-services/apartment — v4 brainstorming (search_path/leak/pooling)](https://github.com/rails-on-services/apartment/discussions/312) · [apartment releases](https://github.com/rails-on-services/apartment/releases)
- [django-tenants (search_path per-cursor, TENANT_LIMIT_SET_CALLS)](https://django-tenants.readthedocs.io/en/latest/use.html) · [django-tenants GitHub](https://github.com/django-tenants/django-tenants)
