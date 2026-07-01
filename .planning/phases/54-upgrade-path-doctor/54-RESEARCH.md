# Phase 54: Upgrade Path & Doctor - Research

**Researched:** 2026-07-01
**Domain:** Postgres schema-move migration mechanics · Igniter generator tasks · Ecto.Migrator round-trip DB testing · mix parapet.doctor static-check framework · compile-time `@schema_prefix`
**Confidence:** HIGH (all design decisions locked in CONTEXT.md; this research supplies exact signatures/line numbers/idioms verified against source in this repo)

## Summary

This phase is **implementation-ready by design**. CONTEXT.md carries 20 mutually-coherent locked decisions (D-01…D-20) from 5 deep-research forks; nothing here re-opens them. This RESEARCH.md is the *mechanics layer*: exact function signatures, file:line integration points, existing idioms to clone verbatim, the six canonical spine tables with FK/partial-index shapes, and — load-bearing — the **Validation Architecture** mapping each of UPG-01..05 + DOCTOR-01 to a concrete test artifact.

Four deliverables, each a natural plan boundary: (1) the doctor `schema` static check (~40 lines into `parapet.doctor.ex`, zero framework change); (2) `mix parapet.gen.schema.move` Igniter task + its emitted reversible `SET SCHEMA` migration with a migrate-time abort guard; (3) the Track B round-trip DB test (clone of `add_lease_until_backfill_test.exs` against a throwaway DB) + a DB-less generator golden test snapshotting the same committed fixture; (4) the Track A `to_sql`/`get_meta` pin, the UPG-05 regex fitness function, and the `resolve_prefix(nil, nil) == {:ok, "parapet"}` default pin.

**Primary recommendation:** Read the four cited source files (`parapet.doctor.ex`, `parapet.gen.spine.ex`, `schema.ex`, `add_lease_until_backfill_test.exs`) as *templates to clone*, not references to admire. Every new artifact has a nearly-verbatim sibling already in the repo. The only genuinely new mechanics are: `after_begin/0` for `SET LOCAL lock_timeout` (Ecto-blessed, verified below), the `DO $$ ... RAISE EXCEPTION $$` migrate-time abort guard, and the dedicated throwaway-DB `storage_up/storage_down` lifecycle.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Drift detection (runtime cfg vs compiled prefix) | Mix task / static analysis | — | Pure comparison of `Application.get_env` vs `Schema.__prefix__()`; no DB. Belongs in default static doctor suite so `--ci` catches it DB-less (D-01). |
| Schema-existence probe | Mix task → Database catalog | — | `to_regnamespace($1)` needs a live repo; degrades to `:skip` when repo not running (D-03). |
| `SET SCHEMA` table move | Database (DDL migration) | Generator (emits literal) | Catalog-only metadata op; the generator bakes the resolved prefix as a literal, the DB performs the move at migrate-time. |
| Missing/renamed-table abort | Database (migrate-time DO-block) | Generator (advisory lint) | Authoritative gate runs at migrate-time against the *target* prod DB, not the dev laptop at generate-time (D-10). |
| Second-move refusal | Generator (Igniter source-file check) | — | Reads tracked source files (rollback-invariant, env-identical) — safe to fail-hard at generate-time (D-11). |
| Track A unprefixed proof | Test / query builder | — | `to_sql` static assertion + live `get_meta` round-trip on the nil CI leg. |

## User Constraints (from CONTEXT.md)

### Locked Decisions

> All 20 decisions below are LOCKED. Do not re-litigate. Verbatim from CONTEXT.md `## Implementation Decisions`.

**A. Doctor schema check — DOCTOR-01**
- **D-01:** ONE new static check named `"schema"` in `@static_checks` in `parapet.doctor.ex` — NOT a new mix task, NOT two checks, NOT folded into `cluster` mode. Honors the `%{status: :info|:warn|:error|:skip, messages: [...]}` contract; inherits `--ci` threshold-flip, `findings_exit_code/2`, JSON output, `parse_requested_checks` allow-listing. Drift stays in the **default static suite** so `mix parapet.doctor --ci` catches it without a live DB.
- **D-02:** Fold two signals into one finding (status = max severity, `cond` rollup like `check_cluster_static`): **(1) drift** — compare `Parapet.Spine.Schema.normalize(Application.get_env(:parapet, :schema_prefix))` vs compiled `Parapet.Spine.Schema.__prefix__()`; disagreement → `:error`. BOTH sides through `normalize/1` so `nil`/`""`/`"public"` collapse equal. **(2) existence** — `SELECT to_regnamespace($1) IS NOT NULL` (parameterized, injection-safe); positively absent → `:error`.
- **D-03:** Existence half **degrades to `:skip`, never `:error`** when repo isn't running — guard via `repo = Application.get_env(:parapet, :repo); is_nil(repo) or Process.whereis(repo) == nil` (the `check_recovery:357` idiom) + wrap probe in `try/rescue`. Exit code 2 stays reserved for probe *execution* failure; this check introduces no new exit code.
- **D-04:** Remediation microcopy names the exact fix inline. (Drift / missing-schema / skip strings — see D-04 verbatim below in Code Examples.)
- **D-05 (load-bearing):** This check is **REQUIRED, not optional** — the primary detection backstop for the UPG-05 footgun (D-17). Moves the compiled-vs-data split left from "loud failure at first prod query" to "caught by `mix parapet.doctor --ci` in the upgrade branch."

**B. Move task & emitted migration — UPG-02**
- **D-06:** New `mix parapet.gen.schema.move` as `use Igniter.Mix.Task`, `info/2` mirroring `gen.spine` verbatim: `schema: [schema: :string, create_schema: :boolean]`, defaults `[schema: "parapet", create_schema: true]`, `aliases: [s: :schema]`, `group: :parapet`; target prefix via `Parapet.Spine.Schema.resolve_prefix(igniter)` interpolated as a **generate-time literal**. Nil/legacy leg (`--schema public` → `resolved == nil`) emits **nothing** + a "tables already in public; no move needed" notice.
- **D-07:** Emit exactly ONE migration via `Igniter.Libs.Ecto.gen_migration/4` with a **real current timestamp** (do NOT override `:timestamp`) — NOT the sentinel `"00000000000000"`. Fixed deterministic module/name `move_parapet_spine_to_schema` so the second-move guard (D-11) can find it.
- **D-08:** Migration body: `after_begin/0` sets `SET LOCAL lock_timeout TO '5s'`; do NOT set `@disable_ddl_transaction`/`@disable_migration_lock`; `up` = [abort guard, D-10] → [inbound-FK/view NOTICE] → conditional `CREATE SCHEMA IF NOT EXISTS <resolved>` (omitted under `--no-create-schema`) → six explicit fully-qualified `ALTER TABLE public.<t> SET SCHEMA <resolved>`; `down` = six explicit `ALTER TABLE <resolved>.<t> SET SCHEMA public` in reverse order, **NEVER `DROP SCHEMA`**. Six explicit lines, NOT a `for`-comprehension.
- **D-09:** Fully-qualify source tables — `public.<t>` on up, `<resolved>.<t>` on down — never rely on `search_path`. The six tables: `parapet_action_items`, `parapet_incidents`, `parapet_timeline_entries`, `parapet_tool_audits`, `parapet_system_events`, `parapet_action_claims`.

**C. Pre-flight catalog detection — UPG-03**
- **D-10:** Missing/renamed-table ABORT is authoritative at MIGRATE time, emitted as a leading `DO $$ ... RAISE EXCEPTION ... $$` using `to_regclass('public.' || quote_ident(t))` over the six tables; raises before any `SET SCHEMA`, inside the transaction. Inbound app FK/view detection is a **non-blocking WARN** via `RAISE NOTICE` over `information_schema.view_table_usage`, mirrored by a best-effort generate-time `Igniter.add_warning`.
- **D-11:** Second-move refusal at GENERATE time via fixed module name (D-07) + `on_exists: {:error, "<points at existing file>"}`. Rollback-invariant (reads tracked source files).
- **D-12:** (a) Best-effort non-fatal generate-time probe via `Ecto.Migrator.with_repo/2` MAY `add_notice`/`add_warning` but NEVER aborts generation. (b) `--no-create-schema`: omit `CREATE SCHEMA` from `up` + emit the shared Ph53-D-15 DBA least-privilege notice via a ONE private helper both `gen.spine` and `gen.schema.move` call.

**D. Round-trip test — UPG-04**
- **D-13:** Clone `add_lease_until_backfill_test.exs`: `use ExUnit.Case, async: false`, `@tag :unboxed`, private non-sandbox `MigrationTestRepo` on `DBConnection.ConnectionPool` + bare `Postgrex` conn, driven by `Code.require_file` of a **committed migration fixture** + `Ecto.Migrator.up/4`/`down/4`. Do NOT generate live in the test. Generated-output correctness is a **separate DB-less generator golden test** snapshotting the SAME fixture.
- **D-14:** Dedicated throwaway DB `parapet_schema_move_roundtrip_test` via `Ecto.Adapters.Postgres.storage_up/1`+`storage_down/1` in `setup_all` (same PG server as `ConcurrencyRepo.database_config()`). NOT the shared `parapet_concurrency_test`.
- **D-15:** Test stands up its OWN isolated fixture spine in `public` (small hand-written DDL: `parapet_incidents` parent + `parapet_action_claims` child with `ON DELETE CASCADE` FK + `WHERE status = 'claimed'` partial index) and moves THOSE. Byte-identical on BOTH CI legs.
- **D-16:** Assertions query the catalog, re-create nothing: (a) table membership via `pg_class`+`pg_namespace`; (b) FK cascade *behavior* (insert parent+child, delete parent, assert cascade); (c) partial-index byte-identical name + `pg_get_expr(indpred, indrelid)`; (d) after down, all six back in `public` AND `parapet` schema exists but empty of spine tables. `@tag :unboxed`, `async: false`.

**E. Track A pin + UPG-05 — UPG-01, UPG-05**
- **D-17 (TRUTH):** No runtime install-detection and there must not be one. Default is `Application.compile_env(:parapet, :schema_prefix, "parapet")`, unconditionally `"parapet"`. UPG-05's literal promise is true ONLY as "no data migration is ever auto-run." **Track A REQUIRES the adopter to explicitly set `config :parapet, schema_prefix: nil` + `mix deps.compile parapet --force`.** A do-nothing upgrader gets compiled `@prefix == "parapet"` pointed at `public` data → loud `relation "parapet.parapet_incidents" does not exist`.
- **D-18:** Honest framing: additive minor, "your data never moves automatically" + "action required: add `config :parapet, schema_prefix: nil` + recompile." NOT "no action required."
- **D-19:** UPG-01 Track A pin — `describe "UPG-01 Track A"` guarded by `if is_nil(@prefix)` in `prefix_propagation_test.exs`, asserting both: (1) `Ecto.Adapters.SQL.to_sql/3` shows bare unqualified table name + no schema qualifier; (2) live write-path round-trip `Ecto.get_meta(record, :prefix) == nil` + green read-back.
- **D-20:** UPG-05 pin — regex fitness function `test/parapet/upgrade_never_forces_move_test.exs` scanning `parapet.install.ex`/`parapet.gen.spine.ex`/`parapet.gen.archive_indexes.ex`, asserting they NEVER reference `parapet.(gen.)?schema.move` or the move module. Plus one test that `Parapet.Spine.Schema.resolve_prefix(nil, nil) == {:ok, "parapet"}`.

### Claude's Discretion
- Exact `check_schema/0` message strings/format; whether existence additionally verifies the six spine tables *resolve under* the compiled prefix (discretionary strengthening; DOCTOR-01 literal met by schema-existence).
- `execute/2` symmetric form vs separate `up`/`down` blocks (D-08 shows separate blocks; planner's call).
- Fixture-spine table count in the round-trip test (2–3 covering parent+child FK + partial index is sufficient; all six acceptable but heavier).
- Whether the generate-time best-effort probe (D-12a) ships in v1.7 or is deferred (migrate-time guard D-10 is the requirement).
- Exact `RAISE NOTICE`/`add_warning` wording for the inbound-FK/view advisory.

### Deferred Ideas (OUT OF SCOPE)
- Full `docs/upgrade-1.x.md` prose + demo-app smoke lane → Phase 55 (this phase fixes the *truth*, D-17/D-18).
- CHANGELOG "action-required" banner + release framing → Phase 56.
- Doctor existence-check strengthening (verify six spine tables resolve under compiled prefix) — discretionary.
- Generate-time best-effort pre-flight probe (D-12a) — may ship or defer.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UPG-01 | Track A (stay on `public`) documented + pinned by a test proving `schema_prefix: nil` emits unprefixed SQL with green queries | D-19 pin in `prefix_propagation_test.exs`; `to_sql`/`get_meta` idioms already proven in that file (lines 22-102); rides the existing nil CI leg |
| UPG-02 | `mix parapet.gen.schema.move` generates reversible migration (`SET LOCAL lock_timeout`, `CREATE SCHEMA IF NOT EXISTS`, six `ALTER … SET SCHEMA` in one transaction; `down` restores public, never `DROP SCHEMA`) | D-06/07/08/09; `gen.spine.ex` is the verbatim Igniter template; `after_begin/0` verified in `Ecto.Migration` (ecto_sql 3.13); §3 of 03-UPGRADE-PATH.md is the migration body |
| UPG-03 | Pre-flight catalog detections — abort on missing/renamed tables, warn on inbound FKs/views, refuse a second move migration | D-10 (`DO $$ RAISE EXCEPTION $$` migrate-time), D-11 (`on_exists: {:error, …}` verified in `igniter/libs/ecto.ex:61`), D-12 |
| UPG-04 | Track B round-trip test (throwaway DB, clones `add_lease_until_backfill_test.exs`): created in `public` → up → resolves under `parapet` with FK cascade + partial indexes → down → restored to `public` | D-13/14/15/16; §6 of 04-TEST-STRATEGY.md is the full skeleton; `storage_up`/`storage_down` verified in postgres adapter (lines 208/247) |
| UPG-05 | Upgrading an existing adopter never forces a schema migration (default flips for new installs only) | D-17 TRUTH, D-20 regex fitness function (clones `schema_prefix_guard_test.exs`) + `resolve_prefix(nil,nil)` pin |
| DOCTOR-01 | `mix parapet.doctor` check compares runtime `:schema_prefix` vs compiled `@schema_prefix`, fails CI-grade on drift with `mix deps.compile parapet --force` remediation; also verifies configured schema exists | D-01..05; drop-in check into `@static_checks` (parapet.doctor.ex:22); `check_recovery:357` skip idiom; `check_cluster_static:290` cond-rollup shape |

## Standard Stack

### Core (all already in the dependency tree — no new installs)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | 3.13.6 | `Ecto.Migration` (`after_begin/0`, `execute/1,2`), `Ecto.Migrator.up/4`/`down/4`, `Ecto.Adapters.Postgres.storage_up/1`/`storage_down/1` | Already the migration + adapter layer for the whole project |
| `ecto` | 3.13.5 | `Ecto.Adapters.SQL.to_sql/3`, `Ecto.get_meta/2` | The Track A proof surface (D-19); already used in `prefix_propagation_test.exs` |
| `igniter` | 0.7.9 | `Igniter.Mix.Task`, `Igniter.Libs.Ecto.gen_migration/4` (`on_exists:`, `body:`, `timestamp:`), `Igniter.add_warning/2`, `Igniter.add_notice/2` | `gen.spine.ex` is built on it; the move task is a sibling |
| `postgrex` | (in tree) | Bare out-of-transaction DDL/DML in the round-trip test | Established Parapet pattern (`add_lease_until_backfill_test.exs`) |

**Installation:** None. Every capability is satisfied by existing deps. **Package Legitimacy Audit is N/A — this phase installs zero external packages.**

### Alternatives Considered (all rejected by locked decisions)
| Instead of | Could Use | Why rejected |
|------------|-----------|--------------|
| Single graded `schema` check (D-01) | Two checks `schema_drift` + `schema_exists` | Drift+existence answer one operator question; Django's single graded `check` precedent |
| Migrate-time `DO $$ RAISE $$` guard (D-10) | Generate-time catalog abort | Dev-DB-vs-prod-DB mismatch makes a wrong generate-time abort the worst outcome (D-12a) |
| File/module `on_exists` guard (D-11) | Catalog-state second-move detection | Catalog check false-positives after `ecto.rollback` (tables back in public, file still exists) |
| Throwaway DB (D-14) | Shared `parapet_concurrency_test` | A half-completed schema move poisons every later `:unboxed` module (F14) |

## Package Legitimacy Audit

**N/A — this phase installs no external packages.** All capabilities are satisfied by `ecto`, `ecto_sql`, `igniter`, and `postgrex`, already present in `mix.lock`.

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
  ADOPTER RUNS            │  mix parapet.doctor [--ci]                    │
  ─────────────          │    │                                          │
                          │    ├─ @static_checks (default suite)          │
                          │    │    runbooks · router · … · recovery      │
                          │    │    + schema  ◄── NEW (D-01)               │
                          │    │        │                                 │
                          │    │        ├─(1) DRIFT: normalize(get_env)   │
                          │    │        │      vs Schema.__prefix__()      │
                          │    │        │      disagree → :error (exit 1)  │
                          │    │        └─(2) EXISTS: repo running?        │
                          │    │             ├ no  → :skip                 │
                          │    │             └ yes → to_regnamespace($1)   │
                          │    │                     absent → :error       │
                          │    └─ findings_exit_code/2 → halt              │
                          └─────────────────────────────────────────────┘

  ADOPTER RUNS            ┌─────────────────────────────────────────────┐
  ─────────────          │  mix parapet.gen.schema.move [-s parapet]     │
                          │        │                                      │
                          │        ├─ resolve_prefix(igniter)             │
                          │        │    nil (--schema public) → notice,   │
                          │        │        emit NOTHING (zero-diff)       │
                          │        ├─ on_exists: {:error, …} ◄─ 2nd-move   │
                          │        │      refusal (D-11, GENERATE time)    │
                          │        └─ gen_migration/4 (real timestamp)     │
                          │             writes ONE file into              │
                          │             priv/repo/migrations/             │
                          └───────────────────────┬─────────────────────┘
                                                  │ adopter reviews diff, runs
                                                  ▼ mix ecto.migrate (weeks later, prod)
                          ┌─────────────────────────────────────────────┐
                          │  move_parapet_spine_to_schema migration       │
                          │   after_begin: SET LOCAL lock_timeout '5s'    │
                          │   up:                                         │
                          │     ① DO $$ RAISE EXCEPTION if any of 6       │
                          │        public.<t> missing $$   ◄─ ABORT       │
                          │        (D-10, MIGRATE time, authoritative)    │
                          │     ② DO $$ RAISE NOTICE inbound FK/view $$    │
                          │     ③ CREATE SCHEMA IF NOT EXISTS <resolved>  │
                          │        (omitted under --no-create-schema)     │
                          │     ④ 6× ALTER TABLE public.<t> SET SCHEMA    │
                          │   down: 6× ALTER <resolved>.<t> SET SCHEMA     │
                          │         public (reverse order); NO DROP SCHEMA │
                          └─────────────────────────────────────────────┘
```

### Component Responsibilities

| Artifact | New/Extend | Responsibility |
|----------|-----------|----------------|
| `lib/mix/tasks/parapet.doctor.ex` | Extend | Add `"schema"` to `@static_checks:22`; add `run_static_check("schema")` clause; add `check_schema/0` privates |
| `lib/mix/tasks/parapet.gen.schema.move.ex` | New | Igniter task: `info/2`, `igniter/1` calling `resolve_prefix`, `gen_migration/4` with `on_exists: {:error,…}`, migration body heredoc |
| shared DBA-notice helper | New/Extract | ONE private helper called by both `gen.spine` (`maybe_emit_dba_notice`) and `gen.schema.move` (D-12b) |
| `priv/repo/migrations/<ts>_move_parapet_spine_to_schema.exs` | New (committed fixture) | The migration fixture the round-trip test `Code.require_file`s AND the generator golden test snapshots |
| `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` | New | Track B round-trip (clone of `add_lease_until_backfill_test.exs`, throwaway DB) |
| generator golden test | New | DB-less: run the generator (or assert the fixture file byte-shape), snapshot the migration source |
| `test/parapet/spine/prefix_propagation_test.exs` | Extend | Add `describe "UPG-01 Track A"` guarded by `if is_nil(@prefix)` |
| `test/parapet/upgrade_never_forces_move_test.exs` | New | UPG-05 regex fitness function + `resolve_prefix(nil,nil)` pin |

### Pattern 1: Doctor static check drop-in (clone `check_cluster_static` rollup + `check_recovery` skip guard)
**What:** A `%{status:, messages:}` map returned by a `check_schema/0` private, dispatched from `run_static_check("schema")`, with `"schema"` added to `@static_checks`.
**When to use:** DOCTOR-01. This is the ONLY framework touch — everything else (`--ci`, JSON, `findings_exit_code`, allow-listing) is inherited.
**Example:**
```elixir
# Source: lib/mix/tasks/parapet.doctor.ex — cond-rollup shape from check_cluster_static:344-350,
# skip guard from check_recovery:357. VERIFIED against repo source.
@static_checks ~w(runbooks router operator_ui endpoint cardinality cluster_static recovery schema)  # add "schema"

defp run_static_check("schema"), do: check_schema()   # add this clause alongside :95

defp check_schema do
  compiled = Parapet.Spine.Schema.__prefix__()
  runtime  = Parapet.Spine.Schema.normalize(Application.get_env(:parapet, :schema_prefix))
  repo     = Application.get_env(:parapet, :repo)

  drift? = runtime != compiled   # both already through normalize/1 (D-02)

  # existence half — degrade to :skip when repo not running (D-03, check_recovery:357 idiom)
  existence =
    if is_nil(repo) or Process.whereis(repo) == nil do
      :skip
    else
      try do
        target = compiled || "public"
        %{rows: [[present]]} = repo.query!("SELECT to_regnamespace($1) IS NOT NULL", [target])
        if present, do: :ok, else: :absent
      rescue
        _ -> :skip
      end
    end

  # cond rollup, status = max severity
  cond do
    drift?             -> %{status: :error, messages: [drift_msg(runtime, compiled)]}
    existence == :absent -> %{status: :error, messages: [missing_msg(compiled, repo)]}
    existence == :skip  -> %{status: :skip,  messages: [skip_msg(compiled)]}
    true                -> %{status: :info,  messages: ["schema_prefix in sync and target schema exists."]}
  end
end
```
> **Landmine:** `Application.get_env(:parapet, :schema_prefix)` may be `nil` legitimately (Track A) — `normalize(nil) == nil`, and compiled `__prefix__()` for a nil-configured build is also `nil`, so they collapse equal. Do NOT compare raw values; the double-`normalize` is what prevents the `nil`-vs-`"public"` false positive (D-02).

### Pattern 2: Igniter move task (clone `gen.spine.ex` structure)
**What:** `use Igniter.Mix.Task` with `info/2` mirroring `gen.spine` verbatim + `igniter/1` resolving the prefix and calling `gen_migration/4`.
**When to use:** UPG-02.
**Example:**
```elixir
# Source: lib/mix/tasks/parapet.gen.spine.ex:34-99 (info/2 + resolve_prefix), and
# deps/igniter/lib/igniter/libs/ecto.ex:34-92 (gen_migration on_exists). VERIFIED.
def info(_argv, _composing_task) do
  %Igniter.Mix.Task.Info{
    schema: [schema: :string, create_schema: :boolean],
    defaults: [schema: "parapet", create_schema: true],
    aliases: [s: :schema],
    group: :parapet
  }
end

def igniter(igniter) do
  app_module = Igniter.Project.Module.module_name_prefix(igniter)
  repo_module = Module.concat([app_module, Repo])
  {igniter, resolved} = # same case/{:ok,_}/{:conflict,_,_} block as gen.spine.ex:58-74
    case Parapet.Spine.Schema.resolve_prefix(igniter) do ... end

  if is_nil(resolved) do
    # nil/legacy leg (--schema public) — emit NOTHING + notice (D-06, Ph53 D-04 zero-diff)
    Igniter.add_notice(igniter, "Tables already resolve to public; no move migration needed.")
  else
    igniter
    |> maybe_emit_dba_notice_move(resolved, igniter.args.options[:create_schema])  # shared helper (D-12b)
    |> Igniter.Libs.Ecto.gen_migration(repo_module, "move_parapet_spine_to_schema",
         # NO :timestamp override → real current timestamp (D-07)
         on_exists: {:error, "A schema-move migration already exists. Run mix ecto.migrate to " <>
           "apply it, or delete it to regenerate. Refusing to emit a second move migration."},  # D-11
         body: move_migration_body(resolved, igniter.args.options[:create_schema]))
  end
end
```
> **`on_exists: {:error, msg}` VERIFIED** at `deps/igniter/lib/igniter/libs/ecto.ex:25-29,61,92`: gen_migration pulls existing migrations into the source set via `include_glob` (`:47`) and checks `module_exists` (`:59`); the `{:error, error}` branch (`:92`) "adds an issue to the igniter that prevents writing and displays to the user." The fixed name `move_parapet_spine_to_schema` (D-07) makes the module name deterministic so this detection is reliable.

### Pattern 3: `after_begin/0` for `SET LOCAL lock_timeout` (Ecto-blessed, applies to BOTH up and down)
**What:** A migration-module `after_begin/0` callback that runs immediately after the transaction opens — for BOTH `up` and `down` (verified: `@callback after_begin() :: term` at `ecto_sql .../migration.ex:418`, docstring at `:413-416` "should consider both the up *and* down cases").
**Why it matters:** D-08 requires `SET LOCAL lock_timeout` on both up and down. Because `after_begin/0` fires on both, you write it ONCE — do NOT duplicate a `SET LOCAL` inside `down`.
**Example:**
```elixir
# Source: deps/ecto_sql/lib/ecto/migration.ex:396-398 (the exact blessed idiom). VERIFIED.
def after_begin do
  repo().query!("SET LOCAL lock_timeout TO '5s'")
end
```
> **Landmine:** `SET LOCAL` is transaction-scoped and no-ops outside a transaction. Setting `@disable_ddl_transaction true` or `@disable_migration_lock true` would (a) break the single-transaction atomicity that keeps the FK graph consistent and (b) make `SET LOCAL` silently do nothing. Both are explicitly forbidden by D-08.

### Pattern 4: Migrate-time abort guard (`DO $$ … RAISE EXCEPTION $$`)
**What:** A leading `execute` of a PL/pgSQL `DO` block that raises before any `SET SCHEMA` if any of the six `public.<t>` tables is missing.
**When to use:** UPG-03 (D-10). Authoritative gate. Runs inside the migration transaction at migrate-time against the *target* DB, so nothing moves on failure.
**Example:**
```elixir
# Emitted INTO the migration body (D-10). to_regclass returns NULL for absent relations
# (no error), making it injection-safe with quote_ident. ASSUMED SQL shape (Postgres-idiomatic);
# planner should keep the exact table array literal.
execute("""
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['parapet_action_items','parapet_incidents','parapet_timeline_entries',
                           'parapet_tool_audits','parapet_system_events','parapet_action_claims'] LOOP
    IF to_regclass('public.' || quote_ident(t)) IS NULL THEN
      RAISE EXCEPTION 'Parapet spine table public.% not found. If you renamed Parapet tables, '
        'edit this migration''s table list before migrating.', t;
    END IF;
  END LOOP;
END $$;
""")
```

### Pattern 5: Round-trip DB test (clone `add_lease_until_backfill_test.exs` + throwaway DB)
**What:** `@tag :unboxed`, `async: false`, a `MigrationTestRepo` on `DBConnection.ConnectionPool` (Ecto.Migrator needs ≥2 connections; sandbox can't provide them) + bare `Postgrex` conn, driven by `Code.require_file` of the committed fixture + `Ecto.Migrator.up/4`/`down/4`. Dedicated throwaway DB via `storage_up`/`storage_down`.
**When to use:** UPG-04.
**Example:** See `test/parapet/repo/migrations/add_lease_until_backfill_test.exs:55-165` for the near-verbatim template. The ONLY deltas (D-14/15):
```elixir
# Source: 04-TEST-STRATEGY.md §6 skeleton + storage_up/down VERIFIED at
# deps/ecto_sql/lib/ecto/adapters/postgres.ex:208,247.
setup_all do
  cfg =
    ConcurrencyRepo.database_config()
    |> Keyword.put(:database, "parapet_schema_move_roundtrip_test")   # dedicated (D-14)
    |> Keyword.put(:pool, DBConnection.ConnectionPool)
    |> Keyword.put(:pool_size, 5)
    |> Keyword.delete(:ownership_timeout)

  _ = Ecto.Adapters.Postgres.storage_up(cfg)   # create throwaway DB
  {:ok, _} = MigrationTestRepo.start_link(cfg)
  MigrationTestRepo.query!("CREATE TABLE IF NOT EXISTS schema_migrations " <>
    "(version bigint PRIMARY KEY, inserted_at timestamp(0) without time zone)", [])
  {:ok, conn} = Postgrex.start_link(Keyword.take(cfg, [:hostname,:port,:database,:username,:password]))
  create_public_fixture_spine!(conn)   # OWN isolated DDL in public (D-15) — NOT ConcurrencyBootstrap
  on_exit(fn -> GenServer.stop(conn); Ecto.Adapters.Postgres.storage_down(cfg) end)  # nuke DB
  {:ok, conn: conn}
end
```
> **Landmine (fixture must be built in `public`, literally):** Because the migration uses literal schema names (`public.<t>` → `<resolved>.<t>`) and the fixture DDL always creates in `public`, the test runs **byte-identically on BOTH CI legs** (D-15). Do NOT route the fixture DDL through `ConcurrencyBootstrap.q/1` (which qualifies to the active prefix) — that would break the parapet leg. Hand-write bare-`public` DDL.

### Pattern 6: Fitness function (clone `schema_prefix_guard_test.exs`)
**What:** A source-scanning test asserting installer/generator files never reference the move task.
**When to use:** UPG-05 (D-20).
**Example:** `test/parapet/schema_prefix_guard_test.exs:12-63` is the template (glob → read → line-scan → assert `offenders == []` with a teaching message). For D-20 the glob targets `lib/mix/tasks/parapet.install.ex`, `parapet.gen.spine.ex`, `parapet.gen.archive_indexes.ex` and the forbidden pattern is `~r/parapet\.(gen\.)?schema\.move/` or the move module name.

### Anti-Patterns to Avoid
- **`for`-comprehension for the six SET SCHEMA lines (D-08):** the generated migration is audited in a prod PR — `grep parapet_incidents migration.exs` must return the moved line. Emit six explicit `execute(...)` lines. (The abort guard's `DO`-block ARRAY listing all six is fine — it's read as one guard.)
- **`DROP SCHEMA` in `down` (D-08):** fail-closed. The possibly-empty schema is the sentinel migration's `down` (or a DBA) to remove; other Parapet objects may live there.
- **Comparing raw prefix values in the doctor check:** always double-`normalize` (D-02) — else compiled `nil` vs runtime `"public"` false-positives.
- **Overriding `:timestamp` on the move migration (D-07):** the sentinel `"00000000000000"` sorts FIRST; a move must sort AFTER the adopter's spine-table migrations or `SET SCHEMA` hits not-yet-created tables. Use a real current timestamp (default behavior — just don't pass `:timestamp`).
- **Generating the migration live inside the round-trip test (D-13):** couples the DB test to file-writing + pre-flight, adds flakiness. Use a committed fixture + a separate DB-less golden test.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Prefix resolution/normalization | A local `nil`/`""`/`"public"` collapse | `Parapet.Spine.Schema.normalize/1` + `resolve_prefix/1,2` (`schema.ex:24-26,150-206`) | Single canonical source; `safe_ident!` allowlist guards injection (ASVS V5) |
| Schema-existence probe | `SELECT … FROM information_schema.schemata WHERE …` string-built | `to_regnamespace($1)` parameterized | Returns NULL (not error) on absent schema; single round-trip; injection-safe (D-02) |
| `lock_timeout` plumbing | Manual `execute` inside up AND down | `after_begin/0` callback | Fires on both up+down automatically (verified); one definition |
| Second-move detection | Catalog-state query | `on_exists: {:error, …}` on `gen_migration/4` | Rollback-invariant; reads tracked source files (D-11) |
| Ecto.Migrator connection provisioning | Sandbox pool | `DBConnection.ConnectionPool` repo + `@tag :unboxed` | Migrator needs ≥2 simultaneous connections; ownership sandbox can't (D-13) |
| Throwaway DB lifecycle | Manual `CREATE DATABASE`/`DROP DATABASE` SQL | `Ecto.Adapters.Postgres.storage_up/1`+`storage_down/1` | Handles the maintenance-DB connection + encoding correctly (verified at postgres.ex:208/247) |
| DBA least-privilege notice | Two copies (spine + move) | ONE shared private helper both tasks call | D-12b single-source; the body already exists at `gen.spine.ex:214-234` |

**Key insight:** Every capability this phase needs already exists as a verified idiom in the repo or a dep. The failure mode is *not* missing tooling — it's cloning the wrong sibling or diverging the two copies (e.g. fixture DDL vs golden-test snapshot, or the DBA notice in two tasks). Wire everything through the single canonical source.

## Runtime State Inventory

> This phase is a *generator + test + doctor-check* phase, not a rename/refactor of existing runtime state. No existing stored data, live service config, OS-registered state, secrets, or build artifacts carry a string this phase renames. The *adopter's* data movement is opt-in and performed by the emitted migration at their discretion — not by this phase.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — this phase writes no data and renames no keys. The `parapet` schema move is opt-in adopter action via the emitted migration. | None |
| Live service config | None. `config :parapet, :schema_prefix` is read (doctor drift check) but never written by this phase. | None |
| OS-registered state | None. | None |
| Secrets/env vars | The round-trip test reads `PARAPET_CONCURRENCY_DB_*` env vars via `ConcurrencyRepo.database_config()` (existing, unchanged) — only to derive the throwaway-DB connection. No new env vars. | None |
| Build artifacts | The committed migration fixture under `priv/repo/migrations/` is a new source file, not a stale artifact. The doctor check reads the compiled `@prefix` — no artifact rename. | None |

## Common Pitfalls

### Pitfall 1: Fixture DDL routed through the prefix-aware qualifier
**What goes wrong:** Reusing `ConcurrencyBootstrap.q/1` (or its compile-time `@prefix`) to build the round-trip fixture spine.
**Why it happens:** It's the nearest DDL sibling and looks reusable.
**How to avoid:** Hand-write bare-`public` DDL (D-15). The migration itself uses literal schema names, so the fixture MUST be in `public` on both legs for the test to be byte-identical.
**Warning signs:** The round-trip test passes on the `public` leg but fails on the `parapet` leg (the fixture landed in `parapet`, then the migration's `public.<t>` abort guard raises).

### Pitfall 2: Doctor drift false-positive on nil-configured builds
**What goes wrong:** `Application.get_env(:parapet, :schema_prefix)` returns `nil` for Track A adopters; comparing raw against compiled `__prefix__()` (also `nil`) *looks* fine, but comparing `"public"` runtime against `nil` compiled fails.
**Why it happens:** Skipping one side of the `normalize/1` (D-02).
**How to avoid:** `normalize(get_env(...))` on the runtime side; compiled `__prefix__()` is already normalized at compile time (`schema.ex:86`). Both nil → equal.
**Warning signs:** `mix parapet.doctor --ci` fails on a correctly-configured Track A app.

### Pitfall 3: Sentinel-timestamp collision / wrong sort order
**What goes wrong:** Passing `timestamp: "00000000000000"` to the move migration (copying the sentinel from `gen.spine.ex:192`).
**Why it happens:** The sentinel is the nearest `gen_migration` sibling.
**How to avoid:** Do NOT pass `:timestamp` (D-07). The sentinel is reserved for schema *creation* (sorts first); a move must sort AFTER the adopter's spine-table migrations.
**Warning signs:** `SET SCHEMA` errors "relation public.parapet_incidents does not exist" at migrate-time because the move ran before the create.

### Pitfall 4: Round-trip test poisoning the shared concurrency DB
**What goes wrong:** Running the move against `parapet_concurrency_test`; a mid-test `lock_timeout` abort leaves the spine in `parapet`, breaking every later `:unboxed` module.
**Why it happens:** `add_lease_until_backfill_test.exs` (the clone target) uses the shared DB.
**How to avoid:** Dedicated throwaway DB via `storage_up`/`storage_down` (D-14). A whole-schema move is too destructive for shared state; `add_lease_until` only mutated a column.
**Warning signs:** Flaky failures in unrelated `:unboxed` tests after the round-trip test runs.

### Pitfall 5: Golden test and round-trip fixture drifting
**What goes wrong:** The DB-less generator golden test snapshots one migration body; the round-trip test `Code.require_file`s a *different* committed fixture; they diverge silently.
**Why it happens:** Two artifacts, no shared source.
**How to avoid:** The golden test and the round-trip test must reference the SAME committed fixture file (D-13) — the golden test snapshots exactly what the round-trip test executes.
**Warning signs:** The generator's output changes but the round-trip test still passes (or vice-versa).

## Code Examples

### D-04 remediation microcopy (verbatim from CONTEXT.md — use these strings)
```elixir
# Drift (:error):
"Config drift: runtime :schema_prefix is #{inspect(runtime)} but Parapet was compiled with " <>
  "#{inspect(compiled)}. Spine reads/writes may target the wrong schema. Recompile the library: " <>
  "mix deps.compile parapet --force"

# Missing schema (:error):
"Schema #{inspect(compiled)} does not exist in the configured repo (#{inspect(repo)}). Create it " <>
  "before migrating: run the CREATE SCHEMA step from mix parapet.gen.spine, then mix ecto.migrate"

# Skip (:skip):
"Schema-existence check skipped: the Parapet repo is not running. Start the OTP app (or run " <>
  "mix parapet.doctor cluster) to verify schema #{inspect(compiled)} exists."
```

### The six canonical spine tables + FK / partial-index shapes (verified from source)
```
# Source: lib/mix/tasks/parapet.gen.spine.ex:99-164 (lib migration) +
#         test/support/concurrency_bootstrap.ex:53-190 (full DDL incl. action_claims). VERIFIED.
Six tables (D-09 order for the move):
  parapet_action_items       (no intra-spine FK in lib; demo adds incident_id → parapet_incidents nilify_all)
  parapet_incidents          (parent; partial indexes: unique WHERE state='open'; WHERE state IN (...); WHERE state='resolved')
  parapet_timeline_entries   FK incident_id → parapet_incidents ON DELETE CASCADE (delete_all)
  parapet_tool_audits        FK timeline_entry_id → parapet_timeline_entries ON DELETE CASCADE (delete_all)
  parapet_system_events      (standalone, no FK)
  parapet_action_claims      FK incident_id → parapet_incidents ON DELETE CASCADE;
                             partial index parapet_action_claims_lease_until_claimed_index WHERE status='claimed'

# Round-trip fixture (D-15, minimal 2-table variant):
#   parapet_incidents (parent) + parapet_action_claims (child)
#     child FK incident_id → parapet_incidents ON DELETE CASCADE
#     partial index ...lease_until_claimed_index (lease_until) WHERE status='claimed'
#   → exercises FK cascade behavior (D-16b) + partial-index survival (D-16c) in one pair.

# All PKs are binary_id/UUID → NO sequences → no orphaned-sequence footgun (03-UPGRADE-PATH §2.6).
```

### Track A pin (D-19) — the load-bearing "proving unprefixed" artifact
```elixir
# Source: test/parapet/spine/prefix_propagation_test.exs:22-102 shows both idioms already in use.
# Add under: if is_nil(@prefix) do  (rides the existing nil CI leg)
describe "UPG-01 Track A: schema_prefix nil emits unprefixed SQL" do
  @describetag :track_a
  test "to_sql carries a bare unqualified table name and no schema qualifier" do
    query = from(i in Incident, select: i.id)
    {sql, _} = Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query)
    refute sql =~ ~s("parapet".), "public leg must not carry a schema qualifier: #{sql}"
    assert sql =~ "parapet_incidents"   # bare, unqualified
  end

  test "write-path round-trip: get_meta prefix is nil + read-back succeeds" do
    {:ok, incident} = Evidence.create_incident(%{title: "track-a", state: "open"})
    assert Ecto.get_meta(incident, :prefix) == nil
    assert ConcurrencyRepo.get(Incident, incident.id)   # green read-back
  end
end
```
> **Note:** This block is guarded by `if is_nil(@prefix)` so it is a no-op on the `parapet` leg and the load-bearing proof on the nil leg — exactly matching the existing `to_sql` else-branch pattern at `prefix_propagation_test.exs:39-42`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Runtime `prefix:` on Repo calls | Compile-time `@schema_prefix` only (runtime prefix BANNED) | v1.7 (Phase 51) | The doctor drift check + Track A pin exist *because* the prefix is compile-time frozen; a stale compile is invisible to `compile_env`'s boot-check when the key is unset |
| `change/0` reversible move | Explicit `up`/`down` (create-on-up, never-drop-on-down) | This phase (D-08) | Prevents `change/0` auto-reversing `CREATE SCHEMA` into a destructive `DROP SCHEMA` on rollback |
| Move all six via `for` loop (03-UPGRADE-PATH §3 draft) | Six explicit `execute` lines (D-08) | This phase | Prod PR auditability: `grep <table> migration.exs` must hit |

**Deprecated/outdated:**
- The draft migration in `03-UPGRADE-PATH.md §3.1` uses a `for table <- @tables` loop and `SET LOCAL lock_timeout = '5s'` inline in both up and down. **This phase supersedes both**: six explicit lines (D-08) and `after_begin/0` (fires on both up+down). Treat §3.1 as the *semantic* reference, not the literal body.
- `03-UPGRADE-PATH.md` names the task `parapet.gen.schema_move` (underscore). **The locked name is `parapet.gen.schema.move`** (dotted, D-06). Use the dotted form.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `DO $$ … to_regclass … RAISE EXCEPTION $$` guard SQL shape (Pattern 4) is Postgres-idiomatic and runs inside the migration transaction | Common Pitfalls / Pattern 4 | LOW — CONTEXT.md D-10 + `specifics` block prescribe exactly this; only the exact PL/pgSQL loop syntax is my rendering. Planner/executor will validate against Postgres 16 at test time. |
| A2 | `Ecto.Adapters.SQL.to_sql(:all, …)` accepts the query kinds needed for the Track A `to_sql` assertion | Track A pin | LOW — `:all` is guaranteed (04-TEST-STRATEGY.md §4.1 note); the existing `prefix_propagation_test.exs:24` already uses `to_sql(:all, …)` successfully. |
| A3 | `Igniter.Libs.Ecto.gen_migration/4` with no `:timestamp` produces a real current timestamp that sorts after existing spine migrations | Pitfall 3 / D-07 | LOW — verified `timestamp/0` fallback at `igniter/libs/ecto.ex:45,153`; sort-order is a Postgres/Ecto migration-version invariant. |

**Note:** No `[ASSUMED]` package names — this phase installs nothing. All three assumptions are LOW-risk renderings of already-locked decisions; none require user confirmation before planning.

## Open Questions

1. **Does the existence probe additionally verify the six spine tables resolve under the compiled prefix?**
   - What we know: DOCTOR-01's literal requirement is met by schema-existence alone (D-02).
   - What's unclear: whether to strengthen to per-table `to_regclass('<prefix>.parapet_incidents')` checks.
   - Recommendation: Claude's Discretion (CONTEXT.md) — ship schema-existence for v1.7; defer table-location strengthening. Planner may include it as a discretionary sub-task if cheap.

2. **Does the generate-time best-effort probe (D-12a) ship in v1.7?**
   - What we know: the migrate-time guard (D-10) is the actual requirement; D-12a is a DX nicety.
   - What's unclear: whether `Ecto.Migrator.with_repo/2` dev-DB feedback is worth the surface area now.
   - Recommendation: Defer unless trivial. The migrate-time guard fully satisfies UPG-03.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (test) | Round-trip test (`storage_up`/`storage_down`, `SET SCHEMA`, catalog assertions) | Assumed ✓ (CI uses postgres:16-alpine per 04-TEST-STRATEGY §0.5; local via `PARAPET_CONCURRENCY_DB_*`) | 16 (CI) | — (test is `:unboxed`, DB-required; no fallback) |
| `ecto_sql` | migration + migrator + storage lifecycle | ✓ | 3.13.6 | — |
| `ecto` | `to_sql`/`get_meta` | ✓ | 3.13.5 | — |
| `igniter` | gen task | ✓ | 0.7.9 | — |
| `postgrex` | bare-conn DDL in round-trip test | ✓ (in tree) | — | — |

**Missing dependencies with no fallback:** None. **Missing with fallback:** None. All capabilities satisfied by the existing tree; PostgreSQL is already the project's test-DB requirement.

## Validation Architecture

> `workflow.nyquist_validation` is **absent** from `.planning/config.json` → treated as **enabled**. This section is load-bearing for VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in), Elixir 1.19 / OTP 26-28 |
| Config file | `test/test_helper.exs` (boots `ConcurrencyRepo` Sandbox `:manual`, runs `ConcurrencyBootstrap.bootstrap!/0`); no `mix test` exclusions of `:unboxed` |
| Quick run command | `mix test test/parapet/upgrade_never_forces_move_test.exs test/parapet/schema_prefix_guard_test.exs` (DB-less fitness fns, sub-second) |
| Full suite command | `mix test` (runs both CI legs' worth in the active compiled prefix; `:unboxed` included) |
| Dual-prefix note | `@schema_prefix` is compile-time; UPG-01 Track A pin only *asserts* on the nil leg (`if is_nil(@prefix)`). CI matrix (`PARAPET_SCHEMA_PREFIX ∈ {parapet, ''}`) recompiles per leg (Phase 52). No new CI wiring needed. |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Layer / What to Assert | Automated Command | File Exists? |
|--------|----------|-----------|------------------------|-------------------|-------------|
| DOCTOR-01 | Drift → `:error` (exit 1 under `--ci`); missing schema → `:error`; repo down → `:skip` | unit (function-level) | Call `Mix.Tasks.Parapet.Doctor` `check_schema/0` (or `run(["schema","--ci"])`) with `put_env` variations; assert `%{status:, messages:}` + exit code | `mix test test/parapet/doctor_schema_check_test.exs` | ❌ Wave 0 |
| UPG-01 | `schema_prefix: nil` emits bare unqualified SQL + green round-trip | integration (to_sql static + live write) | (a) `to_sql(:all,…)` `refute =~ "parapet".`; (b) `get_meta(rec, :prefix) == nil` + read-back | `PARAPET_SCHEMA_PREFIX='' mix test test/parapet/spine/prefix_propagation_test.exs` | ⚠️ extend existing |
| UPG-02 | Generated migration = `after_begin` lock_timeout + `CREATE SCHEMA` (default) + six `SET SCHEMA`, one txn; `down` restores, no `DROP SCHEMA` | golden (DB-less) + up/down round-trip (DB) | golden: snapshot migration source (assert six explicit lines, `after_begin`, no `@disable_ddl_transaction`, no `DROP SCHEMA`); round-trip: catalog membership after up/down | `mix test test/parapet/gen_schema_move_golden_test.exs` + round-trip file | ❌ Wave 0 |
| UPG-03 | Missing table → migrate-time abort (nothing moves); inbound FK/view → NOTICE; second gen → refuse | migrate-time round-trip (abort leg) + generator unit (`on_exists`) | (a) drop a fixture table, run migrator, assert raise + tables unmoved; (b) run generator twice, assert `{:error, …}` issue | round-trip file (abort case) + `mix test test/parapet/gen_schema_move_test.exs` | ❌ Wave 0 |
| UPG-04 | public → up → parapet (FK cascade + partial index intact) → down → public (schema empty, not dropped) | up-down round-trip (DB, `:unboxed`) | pg_class+pg_namespace membership; FK cascade *behavior* (delete parent, assert child gone); `pg_get_expr(indpred,…)` partial-index render; post-down schema exists but empty | `mix test test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` | ❌ Wave 0 |
| UPG-05 | Installer/generators never reference the move task; `resolve_prefix(nil,nil) == {:ok,"parapet"}` | regex fitness (DB-less) + unit | scan source for banned `parapet.(gen.)?schema.move` pattern → assert `offenders == []`; assert default-prefix literal | `mix test test/parapet/upgrade_never_forces_move_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the two DB-less fitness/golden tests (`upgrade_never_forces_move`, `gen_schema_move_golden`) — sub-second, run on every commit.
- **Per wave merge:** full `mix test` in the active leg (includes `:unboxed` round-trip against the throwaway DB).
- **Phase gate:** full `mix test` green under BOTH CI legs (`PARAPET_SCHEMA_PREFIX=parapet` and `=''`) before `/gsd-verify-work`. UPG-01's live-write assertion only fires on the nil leg; that leg MUST be green.

### Observability layers (what proves what, at which layer)
- **`to_sql` static (in-VM, no DB):** UPG-01 SQL-shape proof — legible artifact that the SQL carries no schema qualifier (green suite alone is not legible proof, D-19).
- **`Ecto.get_meta` (live write):** UPG-01 covers `Multi`/`insert_all` paths `to_sql` structurally can't reach (D-19).
- **Live catalog query (`pg_class`/`pg_namespace`/`pg_constraint`/`pg_get_expr`):** UPG-04 membership + partial-index survival (D-16).
- **FK cascade *behavior* (insert/delete round-trip):** UPG-04 — stronger than a pure-catalog FK check (D-16b).
- **Migrate-time `RAISE EXCEPTION` (DB, abort leg):** UPG-03 authoritative gate proof.
- **Regex fitness (source scan):** UPG-05 — statically proves the installer can never auto-chain a data migration (D-20).
- **Golden snapshot (source diff):** UPG-02 — the migration body's shape (six explicit lines, no `DROP SCHEMA`, `after_begin`).

### Wave 0 Gaps
- [ ] `test/parapet/doctor_schema_check_test.exs` — covers DOCTOR-01 (drift/missing/skip + `--ci` exit code)
- [ ] `test/parapet/gen_schema_move_test.exs` — covers UPG-03 second-move refusal (`on_exists`) + nil-leg zero-diff
- [ ] `test/parapet/gen_schema_move_golden_test.exs` — covers UPG-02 migration-body shape (DB-less snapshot of the committed fixture)
- [ ] `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs` — covers UPG-04 up/down round-trip + UPG-03 abort leg (`:unboxed`, throwaway DB)
- [ ] `test/parapet/upgrade_never_forces_move_test.exs` — covers UPG-05 fitness fn + `resolve_prefix(nil,nil)` pin
- [ ] `priv/repo/migrations/<ts>_move_parapet_spine_to_schema.exs` — committed fixture (shared by golden + round-trip tests)
- [ ] Extend `test/parapet/spine/prefix_propagation_test.exs` — add `describe "UPG-01 Track A"` (nil-leg guarded)
- [ ] Framework install: none — ExUnit + PostgreSQL test service already present.

## Security Domain

> `security_enforcement` is not disabled in config → treated as enabled. This phase's attack surface is small (generator output + parameterized catalog probe) but two ASVS categories apply.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | **yes** | Schema-name and table-name are attacker-adjacent inputs (adopter-supplied `--schema` flag, and the six table names interpolated into SQL). Route ALL schema names through `Parapet.Spine.Schema.safe_ident!/1` (`schema.ex:13-21`, allowlist `^[a-z_][a-z0-9_]*$`, ≤63 bytes). The doctor existence probe uses a **parameterized** `to_regnamespace($1)` (never string-interpolated). The migrate-time guard uses `quote_ident(t)` inside the `DO` block. |
| V6 Cryptography | no | — |

### Known Threat Patterns for Postgres-DDL-generating Mix tasks

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via `--schema` value interpolated into `CREATE SCHEMA`/`ALTER … SET SCHEMA` | Tampering | `resolve_prefix` → `normalize/1` → `safe_ident!/1` allowlist BEFORE the value reaches any heredoc (already the `gen.spine` path; the move task inherits it via `resolve_prefix`) |
| SQL injection via schema name in the existence probe | Tampering | Parameterized `to_regnamespace($1)` — bound param, not interpolation (D-02) |
| Injection via renamed/attacker-controlled table name in the abort guard | Tampering | `quote_ident(t)` inside the `DO` block; table list is a fixed literal ARRAY, not user input |
| Destructive rollback (`DROP SCHEMA CASCADE`) | Denial of Service / data loss | `down` NEVER drops the schema (D-08, fail-closed, matches Ph53 D-14) |

> **Note:** `safe_ident!/1` raising `ArgumentError` on a malformed identifier (T-53-01 mitigation, documented at `schema.ex:129-133`) is the load-bearing input-validation control; the move task must not bypass it (it can't — `resolve_prefix` always routes through `normalize`).

## Sources

### Primary (HIGH confidence — verified against repo source in this session)
- `lib/mix/tasks/parapet.doctor.ex` — `@static_checks:22`, `run_static_check:89-95`, `check_cluster_static:290-352` (cond rollup), `check_recovery:354-451` (`:357` skip idiom), `findings_exit_code:516`, `--ci` parse `:34-35`
- `lib/mix/tasks/parapet.gen.spine.ex` — `info/2:35-48`, `resolve_prefix` case `:58-74`, `gen_migration/4` `:99-164`, sentinel `:187-203`, `maybe_emit_dba_notice:214-234`
- `lib/parapet/spine/schema.ex` — `normalize/1` `:24-26`, `safe_ident!/1` `:13-21`, `@prefix` `:81-86`, `__prefix__/0` `:100-102`, `resolve_prefix/1,2` `:150-206`
- `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` — full round-trip clone template `:55-263` (MigrationTestRepo, bare Postgrex, `@tag :unboxed`, idempotent teardown)
- `test/parapet/spine/prefix_propagation_test.exs` — `to_sql`/`get_meta` idioms `:22-102`
- `test/parapet/schema_prefix_guard_test.exs` — fitness-function template `:12-63`
- `test/support/concurrency_bootstrap.ex` / `concurrency_repo.ex` — DDL + `database_config/0` (`:8-22`), six-table FK/index shapes `:53-190`
- `deps/ecto_sql/lib/ecto/migration.ex:384-427` — `after_begin/0` blessed idiom, applies to up+down
- `deps/ecto_sql/lib/ecto/adapters/postgres.ex:208,247` — `storage_up/1`/`storage_down/1`
- `deps/igniter/lib/igniter/libs/ecto.ex:23-92` — `gen_migration/4` `on_exists:`/`timestamp:`/`include_glob`/`module_exists`
- `.planning/REQUIREMENTS.md:36-44` — UPG-01..05, DOCTOR-01 verbatim

### Secondary (MEDIUM confidence — design docs, cited by the forks)
- `.planning/research/v1.7/03-UPGRADE-PATH.md` §2 (SET SCHEMA safety), §3 (migration body), §4 (task design), §5 (recompile order)
- `.planning/research/v1.7/04-TEST-STRATEGY.md` §6 (round-trip skeleton, F11-F14 footguns), §4 (to_sql/get_meta)
- `.planning/phases/53-generators-library-migrations/53-CONTEXT.md` (referenced via CONTEXT.md D-references)

### Tertiary (LOW confidence)
- None — no WebSearch was needed; every claim is verified against repo source or a locked CONTEXT.md decision.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new packages; all deps + versions verified in `mix.lock`.
- Architecture / integration points: HIGH — every file:line cited was read this session.
- Doctor check mechanics: HIGH — `check_cluster_static` + `check_recovery` are exact clone templates.
- Migration body / `after_begin`: HIGH — `after_begin/0` up+down semantics verified in `ecto_sql` source.
- Round-trip test: HIGH — near-verbatim clone target read in full; `storage_up`/`storage_down` verified.
- Migrate-time abort SQL (A1): MEDIUM — decision locked, exact PL/pgSQL syntax is my rendering (validated at test time).
- Validation architecture: HIGH — each requirement mapped to a concrete artifact + assertion layer.

**Research date:** 2026-07-01
**Valid until:** 2026-07-31 (stable — internal repo idioms + pinned deps; only re-verify if `igniter` or `ecto_sql` major-bumps)
