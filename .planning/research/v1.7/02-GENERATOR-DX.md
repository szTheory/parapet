# v1.7 Generator & Migration Emission DX (GEN-MIGRATIONS)

> Dimension: library-generator/DX + migration-safety hat.
> Scope: how `parapet.gen.*` tasks emit `CREATE SCHEMA`, prefix DDL, write host config, stay consistent, and stay testable — judged from the **adopter** seat.
> LOCKED context (not re-litigated): default schema `parapet`; compile-time `@schema_prefix` (no runtime prefix); no `search_path`; `create_schema: false` hatch; Ecto `~> 3.10`.

---

## Summary recommendation (decisive)

1. **Emit a dedicated, first-in-line schema migration** (`*_create_parapet_schema.exs`) separate from the spine tables migration. It runs `execute/2` with reversible up/down (`CREATE SCHEMA IF NOT EXISTS` / `DROP SCHEMA IF EXISTS`). Keeping it standalone makes the `--no-create-schema` hatch a clean *omit-one-file* decision instead of conditional-comment soup inside the spine migration.
2. **Bake the prefix in as a literal string**, not a `config`/`Application.get_env` read at migration runtime. Migrations must be self-contained, reproducible historical artifacts. A migration that reads runtime config is a footgun (Ecto explicitly warns against it). The generator interpolates the chosen prefix once, at gen time, into the emitted file text.
3. **Add `prefix:` to every DDL call** in the spine + archive_indexes migrations: `create table(..., prefix: p)`, `references(..., prefix: p)`, `create index(..., prefix: p)`, `create unique_index(..., prefix: p)`, `drop constraint(...)` and `alter table(..., prefix: p)`. `references/2` needs its **own** `prefix:` (Ecto does not inherit the table's prefix onto the FK target).
4. **Write `config :parapet, :schema_prefix, "parapet"` via Igniter `configure_new/5`** (not `configure/6`) so re-runs and adopters who set a custom prefix are never clobbered. `configure_new` is the idempotent, least-surprise choice.
5. **Flags:** `--schema parapet` (string, default `"parapet"`) and `--no-create-schema` (boolean, default false → schema IS created). Mirrors Oban's `create_schema:` precedent verbatim, in Parapet's established `mix_task.Info{schema:/defaults:}` style.
6. **Generator tests:** keep the existing **AST-normalized substring** assertion style (already in `gen.spine_test`/`gen.archive_indexes_test`) for *structural* checks, and add a **focused golden file** only for the new schema migration (small, high-churn, exact-text-matters). Do not golden-file the whole spine migration — it churns on every column tweak and AST asserts already cover it.

The happy path stays one line: `mix parapet.install` → schema + prefixed tables + config, zero questions. The escape hatch is one discoverable flag: `mix parapet.install --no-create-schema`.

---

## CREATE SCHEMA + `create_schema: false` design

### Where it belongs: a dedicated migration, emitted first

The spine migration today (`parapet.gen.spine.ex`) is one `gen_migration` with a `change/0`. The schema must exist **before** any prefixed `create table` runs. Two structural options:

- **(A) Prepend `execute/2` inside the spine `change/0`.** Works, but couples schema lifecycle to table lifecycle, and the `--no-create-schema` hatch becomes an awkward conditional inside the body string.
- **(B) Emit a separate earlier-timestamped migration** that only creates the schema. ✅ **Recommended.** Clean ownership, clean hatch (just don't emit the file), and `DROP SCHEMA` on `down` is isolated so rolling back the spine doesn't fight the schema.

Generator change — add a composed/preceding `gen_migration` in `parapet.gen.spine.ex`:

```elixir
@impl Igniter.Mix.Task
def igniter(igniter) do
  app_module = Igniter.Project.Module.module_name_prefix(igniter)
  repo_module = Module.concat([app_module, Repo])

  prefix = igniter.args.options[:schema] || "parapet"
  create_schema? = Keyword.get(igniter.args.options, :create_schema, true)

  igniter
  |> Igniter.Project.Config.configure("config.exs", :parapet, [:repo], repo_module)
  |> Igniter.Project.Config.configure_new("config.exs", :parapet, [:schema_prefix], prefix)
  |> maybe_gen_schema_migration(repo_module, prefix, create_schema?)
  |> gen_spine_migration(repo_module, prefix)
end

defp maybe_gen_schema_migration(igniter, _repo, _prefix, false), do: igniter

defp maybe_gen_schema_migration(igniter, repo_module, prefix, true) do
  Igniter.Libs.Ecto.gen_migration(igniter, repo_module, "create_parapet_schema",
    body: """
      def up do
        execute "CREATE SCHEMA IF NOT EXISTS #{prefix}"
      end

      def down do
        execute "DROP SCHEMA IF EXISTS #{prefix}"
      end
    """
  )
end
```

Notes on the emitted SQL:

- **`IF NOT EXISTS` / `IF EXISTS`** makes both directions **idempotent and re-run safe** — re-running the migration suite, or a partially-applied environment, won't crash. This is exactly Oban's posture.
- **Explicit `up`/`down`, not `change` with `execute/2`.** A bare `execute/1` (single-arg) inside `change` is *irreversible* and Ecto will refuse to roll it back. The two-arg `execute "...up...", "...down..."` form is reversible inside `change`, but splitting `up`/`down` is clearer for a destructive `DROP SCHEMA` and matches the archive_indexes precedent already in the repo.
- **`DROP SCHEMA IF EXISTS parapet`** (no `CASCADE`): the spine migration's own `down` drops its tables; we must NOT silently `CASCADE`-drop adopter objects that may live in the schema. Leave the schema-drop non-cascading; if tables remain, the rollback fails loudly — correct least-surprise behavior. Document this.
- **Timestamp ordering:** `gen_migration` stamps files with the current timestamp; emitting the schema migration *before* the spine migration in the pipeline yields an earlier (or composed-earlier) timestamp. Verify ordering in a generator test (assert the schema migration filename sorts before the spine one) — Igniter generates monotonic timestamps within a single run.

### The `--no-create-schema` hatch (Oban precedent, adapted)

Oban's exact precedent ([Oban.Migration docs](https://oban.hexdocs.pm/Oban.Migration.html)):

```elixir
def up,   do: Oban.Migrations.up(prefix: "private", create_schema: false)
def down, do: Oban.Migrations.down(prefix: "private")
```

Parapet's spine is **host-owned generated DDL** (not a library `up()` call), so the equivalent is **"don't emit the CREATE SCHEMA migration at all."** When `--no-create-schema` is passed:

- The schema-creation migration file is omitted.
- The spine + archive migrations are emitted **unchanged** (still fully `prefix:`-stamped — they assume the schema exists).
- The output notice tells the DBA exactly what to run: `CREATE SCHEMA parapet;` plus the grant needed.

This is strictly better than Oban for a least-privilege DBA, because the operator gets a literal, copy-pasteable `CREATE SCHEMA` statement in a reviewable migration file (when enabled) or in the notice (when disabled) — no hidden library behavior.

---

## Prefix-on-DDL: before / after

Ecto applies `prefix:` per-statement; **there is no migration-wide default**, and `references/2` does **not** inherit the table prefix — it needs its own. Below, `p = "parapet"` is interpolated as a literal at gen time.

### `parapet.gen.spine.ex` body — before

```elixir
create table(:parapet_incidents, primary_key: false) do
  add :id, :binary_id, primary_key: true
  # ...
end

create unique_index(:parapet_incidents, [:correlation_key], where: "state = 'open'")

create table(:parapet_timeline_entries, primary_key: false) do
  add :incident_id,
      references(:parapet_incidents, type: :binary_id, on_delete: :delete_all), null: false
end

create index(:parapet_timeline_entries, [:incident_id])
```

### After (prefix literal interpolated by the generator)

```elixir
create table(:parapet_incidents, primary_key: false, prefix: "parapet") do
  add :id, :binary_id, primary_key: true
  # ...
end

create unique_index(:parapet_incidents, [:correlation_key],
         where: "state = 'open'", prefix: "parapet")

create table(:parapet_timeline_entries, primary_key: false, prefix: "parapet") do
  add :incident_id,
      references(:parapet_incidents,
        type: :binary_id, on_delete: :delete_all, prefix: "parapet"), null: false
end

create index(:parapet_timeline_entries, [:incident_id], prefix: "parapet")
```

**Touch every one of these in the spine body:** 5 `create table`, all `create index` / `create unique_index` (8), and **2 `references/2`** (timeline_entries→incidents, tool_audits→timeline_entries). Each `references` gets its own `prefix:`.

### `parapet.gen.archive_indexes.ex` — before/after

`alter table`, `drop constraint`, `create index`, and the `references` inside `modify` all need `prefix:`:

```elixir
# after
def up do
  drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey",
         prefix: "parapet")

  alter table(:parapet_tool_audits, prefix: "parapet") do
    modify :timeline_entry_id,
           references(:parapet_timeline_entries,
             type: :binary_id, on_delete: :delete_all, prefix: "parapet")
  end

  create index(:parapet_incidents, [:updated_at, :id],
           where: "state in ('open', 'investigating')", prefix: "parapet")
  # ... remaining indexes, each with prefix: "parapet"
end
```

> Note: the FK **constraint name** stays `"parapet_tool_audits_timeline_entry_id_fkey"` — the `parapet_` here is the **table-name prefix** (legacy naming), unrelated to the schema. Don't accidentally rename it when adding the schema prefix; the constraint name is computed by Postgres from the unprefixed table name and won't change just because the table moved schemas. Keep this assertion in the test to prevent a silent drift.

### Literal vs config-read at gen time — decision

| Approach | Self-contained migration | Reproducible history | Custom-prefix support | Verdict |
|---|---|---|---|---|
| **Literal string interpolated at gen time** | ✅ | ✅ | ✅ (flag chooses literal) | **Recommended** |
| `Application.compile_env(:parapet, :schema_prefix)` inside migration | ❌ couples migration to config | ❌ history changes if config changes | "works" | Reject |
| `prefix: @schema_prefix` reading runtime config | ❌ | ❌ banned by LOCKED decision | n/a | Reject |

The generator reads the flag/config **once** to decide the literal, then writes plain text. The migration never references `:parapet` config. This is the principle-of-least-surprise position: a checked-in migration always does the same thing forever.

---

## Writing host config

Two distinct config writes, two different idempotency needs:

```elixir
# repo: must reflect the host's actual repo — overwrite-on-update is fine
|> Igniter.Project.Config.configure("config.exs", :parapet, [:repo], repo_module)

# schema_prefix: NEVER clobber an adopter's custom value — use configure_new
|> Igniter.Project.Config.configure_new("config.exs", :parapet, [:schema_prefix], prefix)
```

Behavior ([Igniter v0.8.2 Project.Config](https://igniter.hexdocs.pm/Igniter.Project.Config.html)):

- **`configure_new/5`** — "Sets a config value... if it is not already set." On re-run, or when an adopter already pinned `config :parapet, :schema_prefix, "obs"`, it is a **no-op**. This is the correct semantics for a value that, once chosen, is a compile-time contract you must not silently flip.
- **`configure/6`** — overwrites via updater. Use only for `[:repo]`, where re-deriving from the host is the source of truth.

**On re-run / already-present:** `configure_new` leaves the existing line untouched; Igniter's diff preview shows "no change" for that config — adopters see their value respected. If `--schema foo` is passed but config already says `"bar"`, **prefer config and emit a warning notice** ("Found existing config :parapet, :schema_prefix \"bar\"; ignoring --schema foo"). Never let a flag silently disagree with a compile-time-pinned schema, because the tables were created under whatever the migration literal said.

> Edge case to flag for the prefix-mechanism dimension: the **migration literal and the runtime `@schema_prefix` must agree**. If an adopter changes `:schema_prefix` config after migrating, runtime queries target a schema the tables aren't in. The doctor task (cross-dimension) should assert `config prefix == actual schema of parapet_incidents`.

---

## Cross-generator touch-point map

Every generator that emits DDL or relies on the prefix must resolve it **identically**, from one helper, in one precedence order.

| Generator / task | Touch-point | What changes |
|---|---|---|
| `parapet.gen.spine` | new schema migration + 5 tables, 8 indexes, 2 `references` | emit `create_parapet_schema` migration; stamp `prefix:` on all spine DDL; `configure_new :schema_prefix` |
| `parapet.gen.archive_indexes` | `up`/`down`: `alter`, `drop constraint`, indexes, `references` in `modify` | stamp `prefix:` on every DDL call; **must NOT** re-emit `CREATE SCHEMA` (assumes spine already created it) |
| `parapet.install` (orchestrator) | composes `gen.spine`; owns the summary notice; declares flags in `Info{schema:}` | thread `--schema` / `--no-create-schema` down to `gen.spine`; add schema/least-priv lines to install summary |
| Future per-feature migrations (e.g. action_claims) | any new `gen_migration` body | same `prefix:` literal; pull from shared resolver |
| Runtime schemas (`Ecto.Schema`) | `@schema_prefix` (cross-dimension, LOCKED) | out of scope here, but **must match** the literal this dimension bakes in |

**Single resolver (put in a shared `Parapet.Gen.Schema` helper, used by every generator):**

```elixir
defmodule Parapet.Gen.Schema do
  @moduledoc false
  @default "parapet"

  # Precedence: explicit --schema flag > existing host config > default.
  def resolve_prefix(igniter) do
    igniter.args.options[:schema] ||
      get_configured_prefix(igniter) ||
      @default
  end

  def create_schema?(igniter), do: Keyword.get(igniter.args.options, :create_schema, true)
end
```

Centralizing this is the load-bearing consistency guarantee: `gen.spine` and `gen.archive_indexes` can never drift on prefix precedence because they call the same function. **Flag both generators' `Info{schema:}` to accept `--schema`/`--no-create-schema`** so they're runnable standalone, and have `install` forward `igniter.args` through `Igniter.compose_task("parapet.gen.spine", argv)`.

---

## Generator-test strategy

These tests churn because they assert on emitted text. Structure to minimize churn while keeping a tight contract.

**Tier 1 — AST-normalized substring asserts (keep + extend the existing style).**
The repo already does this well (`contains_snippet?/2` normalizes whitespace via `Macro.to_string |> String.replace(~r/\s+/, " ")`). For v1.7, add prefix assertions to the existing spine/archive tests:

```elixir
assert contains_snippet?(migration_ast,
  "create(table(:parapet_incidents, primary_key: false, prefix: \"parapet\"))")

assert contains_snippet?(migration_ast,
  "references(:parapet_incidents, type: :binary_id, on_delete: :delete_all, prefix: \"parapet\")")

# every index carries the prefix — count guard
prefix_count = Regex.scan(~r/prefix: "parapet"/, migration_source) |> length()
assert prefix_count >= 15  # 5 tables + 2 refs + 8 indexes
```

The count-guard catches the classic bug: someone adds an index later and forgets the prefix. Cheap, durable.

**Tier 2 — one focused golden file for the schema migration only.**
The `create_parapet_schema` migration is tiny, exact-text-sensitive (the `IF NOT EXISTS`/`IF EXISTS` strings matter), and low-churn. A golden fixture (`test/fixtures/golden/create_parapet_schema.exs`) compared with `assert_creates(igniter, path, golden)` is ideal here — Igniter's `assert_creates/3` already does exact-content matching (see `install_test.exs` instrumenter assertion). Do **not** golden-file the whole spine migration: it changes whenever a column is added and produces noisy diffs that train maintainers to blind-accept goldens.

**Tier 3 — hatch + config behavior tests.**

```elixir
test "--no-create-schema omits the schema migration but keeps prefixes" do
  igniter = test_project() |> Spine.igniter_with(["--no-create-schema"])
  refute migration_present?(igniter, "create_parapet_schema")
  assert migration_present?(igniter, "add_parapet_spine_tables")
  assert source(igniter, spine) =~ ~s(prefix: "parapet")
end

test "configure_new does not clobber an existing schema_prefix" do
  igniter =
    test_project()
    |> set_config(:parapet, :schema_prefix, "obs")
    |> Spine.igniter_with(["--schema", "parapet"])
  assert config(igniter) =~ ~s(schema_prefix: "obs")  # adopter wins
end
```

**Guidance to maintainer:** golden-file sparingly (one small file), AST-assert for structure, behavior-test the branches. This keeps the churn surface ~1 file instead of 5 full migration snapshots. Path-gate these in CI under the existing `installer_golden`/installer-path lane (rulestead pattern) so unrelated PRs don't pay the cost.

---

## Adopter-facing DX (flags, output, errors, happy path)

### Flags (in `Info{}` — Parapet's established style, cf. `gen.slo`/`install`)

```elixir
%Igniter.Mix.Task.Info{
  group: :parapet,
  example: "mix parapet.gen.spine --schema parapet",
  schema: [schema: :string, create_schema: :boolean],
  defaults: [schema: "parapet", create_schema: true]
}
```

- `--schema parapet` — string, default `"parapet"`. Names the Postgres schema.
- `--no-create-schema` — OptionParser auto-derives this from the `create_schema: :boolean` entry; `true` by default (schema IS created). Named **identically to Oban** for cross-library muscle memory. Avoid a separate `--skip-schema` synonym — one name, least surprise.

### Happy path (one line, zero questions)

```
$ mix parapet.install
...
Parapet install summary

Generated core artifacts:
- Parapet schema migration (CREATE SCHEMA parapet)
- Parapet evidence spine migration (6 tables in schema "parapet")
- ...
Database schema:
- Tables live in the dedicated `parapet` Postgres schema (prefix "parapet").
- Run `mix ecto.migrate` to create the schema and tables.
```

### Least-privilege path (escape hatch, discoverable)

```
$ mix parapet.install --no-create-schema
...
Database schema (manual step required):
- Schema creation was skipped (--no-create-schema).
- Ask your DBA to run, once, before `mix ecto.migrate`:

      CREATE SCHEMA IF NOT EXISTS parapet;
      GRANT USAGE, CREATE ON SCHEMA parapet TO <app_db_user>;

- Parapet's spine tables will be created INSIDE that schema.
```

### Error messages (least surprise)

- **Schema missing at migrate time** (DBA forgot, used `--no-create-schema`): Postgres raises `ERROR: schema "parapet" does not exist`. Pre-empt it: the `--no-create-schema` notice spells out the exact `CREATE SCHEMA` SQL. Also have `mix parapet.doctor` (cross-dimension) check schema existence and print the same remediation.
- **Flag vs existing config conflict:** emit a *notice*, not a crash — "Existing config `:parapet, :schema_prefix` is \"bar\"; `--schema foo` ignored. Migrations use the config value."
- **Re-run:** `configure_new` no-ops the config; Igniter shows the migration as already-present. Idempotent, quiet.

---

## Prior-art lessons (cited)

- **Oban.Migration** ([oban.hexdocs.pm/Oban.Migration.html](https://oban.hexdocs.pm/Oban.Migration.html), current `Oban.Migration`; older API `Oban.Migrations` in v2.x) — the canonical Elixir precedent.
  - **Did right:** `prefix:` + `create_schema:` pair; `create_schema: false` for least-privilege DBs is exactly the hatch to copy; migrations idempotent between versions; the schema is created *within the migration*, host-reviewable. **Adopt the flag name `create_schema` verbatim.**
  - **Sharp edges to avoid:** Oban hides DDL behind `Oban.Migrations.up()` (opaque library call). Parapet's DNA is **host-owned, inspectable generated files** — so we emit literal `execute "CREATE SCHEMA ..."` and literal `prefix:`-stamped tables instead of a library callback. Adopters can read and modify every line. This is the deliberate divergence.
- **Ecto.Migration** ([hexdocs.pm/ecto_sql/Ecto.Migration.html], Ecto SQL `~> 3.10`) — `prefix:` is per-statement; **`references/2` needs its own `prefix:`** (does not inherit table prefix); single-arg `execute/1` is irreversible → use two-arg `execute/2` or explicit `up`/`down`; migrations should **not** read runtime config (reproducibility). All three constraints drive the recommendations above.
- **Igniter `Project.Config`** ([igniter.hexdocs.pm/Igniter.Project.Config.html], v0.8.2) — `configure_new/5` = idempotent set-if-absent (use for `:schema_prefix`); `configure/6` = overwrite-via-updater (use for `:repo`). The repo's existing `gen.slo`/`install` already use `configure/6` with custom `updater` for list-merge — same toolbox, here we just pick `configure_new` for the don't-clobber value.
- **Rulestead release-eng doc** (`prompts/prior-art/rulestead-release-engineering-and-ci.md`) — golden/installer tests belong behind a **path-gated `installer_golden` lane**; package `files:` whitelist must include `priv/repo/migrations` and templates. Keep new golden fixtures small to avoid blind-accept drift (their explicit anti-pattern).
- **Parapet engineering DNA** (`prompts/parapet-engineering-dna-from-sibling-libs.md`) — "host-owned generated code over opaque magic," "make the happy path short and obvious," "golden installer tests when the install surface stabilizes." This dimension's literal-DDL + one-line-install + tiered-tests posture is a direct application.

---

## Constraints this imposes on adjacent dimensions

- **Prefix-mechanism dimension:** the **migration literal is the source of truth** for which schema tables physically live in. Runtime `@schema_prefix` MUST equal that literal. Provide a doctor check asserting `config prefix == schema-of(parapet_incidents)`. The flag→config precedence (flag > existing config > default) must be defined once and shared; if the prefix-mechanism dimension defines its own resolver, they must be the same function.
- **Upgrade/migration-safety dimension:** existing adopters are **opt-in only** — the schema migration + prefix stamping describe the *fresh-install* path. A separate, generated **move/transition migration** (`ALTER ... SET SCHEMA`, or move-then-backfill) is needed for adopters already on `public`; its `down` must be reversible and it must coordinate with the `create_schema:false` hatch (DBA may need to pre-create + grant before the move). That migration is NOT this dimension's spine emission — flag it as its own requirement.
- **Test dimension:** budget for ~1 small golden fixture + extended AST asserts (prefix count-guard) + 3 hatch/config branch tests, gated under the existing installer-golden CI lane. Avoid full-migration goldens.
- **Hatch semantics:** `--no-create-schema` omitting the migration means the spine migration **assumes** the schema exists; any future generator that emits prefixed DDL inherits the same assumption and must surface the same DBA remediation notice.

---

## Sources

- [Oban.Migration — current docs](https://oban.hexdocs.pm/Oban.Migration.html) (HIGH; curated official)
- [Oban.Migrations — v2.x API history](https://hexdocs.pm/oban/Oban.Migration.html) (HIGH; curated official)
- [Igniter.Project.Config — v0.8.2](https://igniter.hexdocs.pm/Igniter.Project.Config.html) (HIGH; curated official)
- Ecto.Migration `prefix:` / `references/2` / `execute/2` reversibility — Ecto SQL `~> 3.10` (HIGH; curated official)
- Codebase: `lib/mix/tasks/parapet.gen.spine.ex`, `parapet.gen.archive_indexes.ex`, `parapet.install.ex`, `parapet.gen.slo.ex`, `priv/repo/migrations/*`, `test/mix/tasks/parapet.gen.*_test.exs` (HIGH; direct read)
- `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/prior-art/rulestead-release-engineering-and-ci.md` (HIGH; repo docs)
