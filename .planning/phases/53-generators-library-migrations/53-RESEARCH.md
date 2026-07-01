# Phase 53: Generators & Library Migrations - Research

**Researched:** 2026-07-01
**Domain:** Igniter mix tasks, Ecto migrations, Postgres schema prefix stamping
**Confidence:** HIGH — all primary claims verified directly from installed dep source

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

D-00 through D-16 are locked. Summary for planner:

- **D-00:** Single prefix source: `Parapet.Spine.Schema`. No re-implementation elsewhere.
- **D-01:** Generators stamp a **generate-time literal** `prefix: "<resolved>"` on every `create table`, `references/2`, and `create index`. No runtime call in adopter migrations.
- **D-02:** `references/2` gets its own explicit `prefix:`. Index `prefix:` is always explicit (never inherited).
- **D-03:** FK constraint names and index names stay byte-identical. The Postgres adapter uses `%Table{:name}` only, not `:prefix`, to build these.
- **D-04:** Nil/legacy leg emits **no** `prefix:` opt at all — zero-diff to current output.
- **D-05:** `resolve_prefix/2` — pure core + thin Igniter arity — lives on `Parapet.Spine.Schema`.
- **D-06:** Precedence `flag > existing config > default`. Conflict → flag wins + `Igniter.add_warning/2`. Never clobber, never crash.
- **D-07:** `install` + standalone `gen.spine` persist via `Igniter.Project.Config.configure_new/6` (no-clobber).
- **D-08:** All three tasks set `group: :parapet` in `%Igniter.Mix.Task.Info{}`.
- **D-09:** `resolve_prefix/2` = generate-time; `__prefix__/0` = compile-time. Must not cross-call.
- **D-10:** Edit 5 lib migrations + 3 demo migrations **in place**.
- **D-11:** Committed migrations bind prefix via `Parapet.Spine.Schema.__prefix__()` (compile-time), not a literal.
- **D-12:** Keep timestamps unchanged. One-time contributor step: `mix demo.reset` + drop `parapet_concurrency_test`.
- **D-13:** Sentinel migration filename `00000000000000_create_parapet_schema.exs` via `gen_migration` `:timestamp` option.
- **D-14:** Body: `execute("CREATE SCHEMA IF NOT EXISTS parapet")` up / non-cascading `execute("DROP SCHEMA IF EXISTS parapet")` down. No `CASCADE`.
- **D-15:** Flag surface: `schema: :string`, `create_schema: :boolean`, defaults `schema: "parapet", create_schema: true`, alias `s: :schema`. `--no-create-schema` omits sentinel. Remediation via `Igniter.add_notice`.
- **D-16:** Tests: `prefix:` count-guard (`Regex.scan`), one golden `assert_creates/3` on schema migration, `refute_creates` for `--no-create-schema`, FK-constraint-name unchanged under both legs, nil-leg byte-identical golden.

### Claude's Discretion

- Exact `resolve_prefix/2` return-tuple shape and warning/notice wording.
- Whether DBA remediation notice lands on `gen.spine` alone or folds into `install` summary.
- Golden-file exact byte layout (formatter-driven).
- Whether `resolve_prefix`'s Igniter arity returns `value` or `{igniter, value}`.

### Deferred Ideas (OUT OF SCOPE)

- `mix parapet.gen.schema.move` (`ALTER TABLE … SET SCHEMA`) — Phase 54.
- Doctor drift check — Phase 54.
- Optional `ALTER DEFAULT PRIVILEGES … IN SCHEMA parapet GRANT …` — mention in remediation only, not default block.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEN-01 | First-ordered `*_create_parapet_schema` migration: reversible `CREATE SCHEMA IF NOT EXISTS` / `DROP SCHEMA IF EXISTS` (non-cascading) | Sentinel filename via `gen_migration` `:timestamp` option; version 0 sorts first; confirmed in Igniter.Libs.Ecto source |
| GEN-02 | `gen.spine` and `gen.archive_indexes` stamp literal `prefix:` on every `create table`, `references/2`, and index; FK constraint names unchanged | Ecto `%Table{prefix:, name:}` separation confirmed in `ecto_sql/lib/ecto/adapters/postgres/connection.ex:1264,1884-1885`; index names from `ecto_sql/lib/ecto/migration.ex:1041-1045` use table name only |
| GEN-03 | `configure_new/6` writes config (no-clobber); `--schema` vs existing-config conflict warns | `configure_new/6` verified in `deps/igniter/lib/igniter/project/config.ex:27-38`; `add_warning/2` confirmed at `deps/igniter/lib/igniter.ex:409-411` |
| GEN-04 | `--schema` / `--no-create-schema` flags Oban-verbatim; omits sentinel; prints DBA remediation | Oban option names `prefix:` and `create_schema:` confirmed in `deps/oban/lib/oban/migrations/postgres.ex:88,94`; Oban default: `create_schema = (prefix != "public")` |
| GEN-05 | Shared resolver (`flag > existing config > default`) in `gen.spine`, `gen.archive_indexes`, `install` | All three tasks read `igniter.args.options` via `Info.schema` parsing; `group: :parapet` routes the flag to all |
| GEN-06 | 5 lib + 3 demo committed migrations prefixed via `__prefix__()` | All 8 files read; `__prefix__()` is the correct compile-time ref |
| GEN-07 | Generator tests: `prefix:` count-guard, one golden (schema migration), `--no-create-schema` + existing-config branch coverage | `assert_creates/3` does exact-bytes when `content` arg provided; `refute_creates/2` available; all confirmed in `deps/igniter/lib/igniter/test.ex:638-671,688-700` |
</phase_requirements>

---

## Summary

Phase 53 is well-constrained by a CONTEXT.md with 17 locked decisions. The research task is narrow: confirm the actual Igniter 0.7.9 / Oban 2.22.1 / ecto_sql 3.13.5 API signatures match what the CONTEXT assumes, and surface any discrepancy.

**Critical finding:** CONTEXT.md has a discrepancy between GEN-03 text (says `configure_new/5`) and D-07 prose (says `configure_new/6`). The installed Igniter 0.7.9 source declares `configure_new/6` (5 required args + 1 optional `opts \\ []`). The planner must use `configure_new/6`. The `configure_new/5` reference in the GEN-03 acceptance text is incorrect; both the `@spec` and the implementation take 6 args.

**Secondary finding:** `group: :parapet` routing is more nuanced than D-08 implies. `args_for_group/2` strips flags that are namespaced as `--parapet.schema` into `--schema`, but plain `--schema` (no dot) passes through unchanged to any task that declares `schema: :string` in its `Info.schema`. So `group: :parapet` is the disambiguation mechanism for **conflicts** — it allows operators to write `--parapet.schema` to disambiguate when another composed task also defines `--schema`. The plain `--schema foo` short form still works when there is no conflict. This is the correct semantics and aligns with D-08.

**Primary recommendation:** Build `resolve_prefix/2` as a pure function on `Parapet.Spine.Schema`, use `configure_new/6` (not `/5`), use `gen_migration` with `timestamp: "00000000000000"` (string), and use `add_warning/2` for conflicts / `add_notice/2` for the summary panel.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Prefix resolution at generation time | Mix task layer | `Parapet.Spine.Schema` | `resolve_prefix/2` lives in the schema module; tasks call it |
| Config persistence (no-clobber) | Mix task layer | Igniter config API | `configure_new/6` writes to host's `config/config.exs` |
| Sentinel schema migration | Mix task layer (`gen.spine`) | Igniter Ecto lib | `gen_migration/4` with `:timestamp` option |
| DDL prefix stamping (generated migrations) | Mix task layer heredoc | — | Generate-time literal interpolation into `body:` string |
| DDL prefix stamping (committed migrations) | Library migration files (8 files) | `Parapet.Spine.Schema.__prefix__()` | Compile-time macro call, not runtime |
| Flag routing (`--schema`, `--no-create-schema`) | Igniter `Info` struct | `args_for_group/2` seam | `group: :parapet` + schema/aliases declarations |
| Warning vs. notice display | Igniter (`add_warning/2`, `add_notice/2`) | — | Warnings prevent nothing but surface in output; notices appear in summary panel |

---

## Verified API Signatures

### 1. `Igniter.Project.Config.configure_new` — arity 6, NOT 5

**CONTEXT discrepancy:** GEN-03 acceptance criterion text says `configure_new/5`; D-07 prose says `configure_new/6`. The installed source is definitive.

**Verified source:** `deps/igniter/lib/igniter/project/config.ex:27-38`

```elixir
# [VERIFIED: deps/igniter/lib/igniter/project/config.ex:27-29]
@spec configure_new(Igniter.t(), Path.t(), atom(), list(atom), term(), opts :: Keyword.t()) ::
    Igniter.t()
def configure_new(igniter, file_path, app_name, config_path, value, opts \\ []) do
```

The 6th argument `opts` has default `[]`, so calling it with 5 positional args is valid Elixir (the default fires), but the `@spec` is arity 6 and the planner should document it as `/6`. No-clobber semantics: `configure_new` calls `configure/6` with `updater: &{:ok, &1}`, which means "if the key already exists, return the existing zipper unchanged" — it never overwrites.

**Config write pattern for Phase 53:**
```elixir
# [VERIFIED: deps/igniter/lib/igniter/project/config.ex:29]
Igniter.Project.Config.configure_new(
  igniter,
  "config.exs",
  :parapet,
  [:schema_prefix],
  resolved_prefix   # the generate-time resolved string, e.g. "parapet"
)
```

**CONTEXT discrepancy verdict:** D-07 is correct (`configure_new/6`). The GEN-03 acceptance text `/5` is a typo. The planner should note this and use `/6`.

---

### 2. `Igniter.Libs.Ecto.gen_migration/4` — `:timestamp` option confirmed

**Verified source:** `deps/igniter/lib/igniter/libs/ecto.ex:17-108`

```elixir
# [VERIFIED: deps/igniter/lib/igniter/libs/ecto.ex:23,32,45]
# - :timestamp - the timestamp to use for the migration.
#   Primarily useful for testing so you know what the filename will be.
@spec gen_migration(Igniter.t(), repo :: module(), name :: String.t(), opts :: Keyword.t()) ::
    Igniter.t()
def gen_migration(igniter, repo, name, opts \\ []) do
  # ...
  file = Path.join(path, "#{opts[:timestamp] || timestamp()}_#{base_name}")
```

`:timestamp` is a string that is interpolated directly into the filename. Passing `"00000000000000"` produces `priv/repo/migrations/00000000000000_create_parapet_schema.exs`.

The default `timestamp()` function (line 153-156) produces `"#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"` — a 14-digit UTC datetime string. `"00000000000000"` is also 14 characters, matching the format convention.

**Ecto version sorting:** Ecto's migrator calls `Integer.parse(Path.rootname(base))` → `{0, ""}`. Version 0 is strictly less than any real timestamp (`20260521010000` ≫ 0). `mix ecto.migrate` runs migrations in ascending version order, so the sentinel runs first. [ASSUMED — `Integer.parse` sort behavior; Ecto migrator source not read, but this is the documented behavior and matches D-13's rationale verbatim]

**On-exists behavior:** If the migration module already exists (installer re-run), the default `:on_exists` is `:increment` — it would try to generate `create_parapet_schema_1.exs`. Use `:on_exists: :skip` for idempotent installer behavior (no second sentinel file).

**Sentinel call pattern:**
```elixir
# [VERIFIED: deps/igniter/lib/igniter/libs/ecto.ex:45]
Igniter.Libs.Ecto.gen_migration(
  igniter,
  repo_module,
  "create_parapet_schema",
  timestamp: "00000000000000",
  on_exists: :skip,
  body: """
    def up do
      execute("CREATE SCHEMA IF NOT EXISTS #{resolved_prefix}")
    end

    def down do
      execute("DROP SCHEMA IF EXISTS #{resolved_prefix}")
    end
  """
)
```

---

### 3. `Igniter.add_warning/2` and `Igniter.add_notice/2`

**Verified source:** `deps/igniter/lib/igniter.ex:408-422`

```elixir
# [VERIFIED: deps/igniter/lib/igniter.ex:408-411]
@doc "Adds a warning to the warnings list. Warnings will not prevent writing, but will be displayed to the user."
@spec add_warning(t, term | list(term)) :: t()
def add_warning(igniter, warning) do
  %{igniter | warnings: List.wrap(warning) ++ igniter.warnings}
end

# [VERIFIED: deps/igniter/lib/igniter.ex:414-422]
@doc "Adds a notice to the notices list. Notices are displayed to the user once the igniter finishes running."
@spec add_notice(t, String.t()) :: t()
def add_notice(igniter, notice) do
  if notice in igniter.notices do
    igniter
  else
    %{igniter | notices: [notice] ++ igniter.notices}
  end
end
```

**Distinction:**
- `add_warning/2`: accepts `term | list(term)`, appears during the run, does NOT block writing. Use for the conflict warning (D-06).
- `add_notice/2`: accepts `String.t()`, deduplicates (if same string added twice, only one appears), displayed AFTER the igniter finishes running — the "summary panel". Use for the DBA remediation block (D-15) and the install summary.

`parapet.install.ex` already calls `Igniter.add_notice/2` at line 86-95 — the existing pattern this phase extends. [VERIFIED: lib/mix/tasks/parapet.install.ex:86-95]

---

### 4. `%Igniter.Mix.Task.Info{group:}` — confirmed; routing mechanics verified

**Verified source:** `deps/igniter/lib/mix/task/info.ex:93-108`

```elixir
# [VERIFIED: deps/igniter/lib/mix/task/info.ex:93-108]
defstruct schema: [],
          defaults: [],
          required: [],
          aliases: [],
          group: nil,         # <-- confirmed field exists
          composes: [],
          # ...

@type t :: %__MODULE__{
  # ...
  group: atom | nil,    # <-- atom is valid
```

**How `group: :parapet` routes `--schema`:**

`Igniter.Util.Info.group/2` at line 525-528:
```elixir
# [VERIFIED: deps/igniter/lib/igniter/util/info.ex:524-528]
def group(%{group: group}, _task_name) when not is_nil(group),
  do: String.replace(to_string(group), "_", "-")
# atom :parapet → "parapet"
```

`args_for_group/2` at lines 382-450 strips namespace prefixes. `--parapet.schema foo` becomes `--schema foo` for any task in the `parapet` group. A plain `--schema foo` (no dot) has no dot, so the condition `String.contains?(arg, ".")` is false, and the flag passes through unchanged. This means:

- `--schema foo` works directly without disambiguation.
- `--parapet.schema foo` also works (longer form, for when conflict disambiguation is needed).
- `--no-create-schema` works because it has no dot and passes through.

**Confirmed `Info` struct for all three tasks:**
```elixir
# Pattern for gen.spine, gen.archive_indexes, install (extended):
%Igniter.Mix.Task.Info{
  schema: [
    schema: :string,
    create_schema: :boolean
  ],
  defaults: [
    schema: "parapet",
    create_schema: true
  ],
  aliases: [s: :schema],
  group: :parapet,
  composes: [...]   # existing composes list, unchanged for gen.spine and gen.archive_indexes
}
```

**`OptionParser` negation:** `--no-create-schema` is standard `OptionParser` boolean negation for `:boolean` typed switches. When `create_schema: :boolean` is in the schema, `--no-create-schema` sets `create_schema: false`. No special handling needed — Igniter passes through to `OptionParser.parse!`. [VERIFIED: deps/igniter/lib/mix/task.ex:240]

---

### 5. Oban `Oban.Migration` — `prefix` and `create_schema` option names confirmed

**Verified source:** `deps/oban/lib/oban/migrations/postgres.ex:10,88,94`

```elixir
# [VERIFIED: deps/oban/lib/oban/migrations/postgres.ex:10,88,94]
@default_prefix "public"

defp with_defaults(opts, version) do
  opts = Enum.into(opts, %{prefix: @default_prefix, version: version})
  opts
  |> Map.put(:quoted_prefix, inspect(opts.prefix))
  |> Map.put(:escaped_prefix, String.replace(opts.prefix, "'", "''"))
  |> Map.put_new(:unlogged, true)
  |> Map.put_new(:create_schema, opts.prefix != @default_prefix)
  #                              ^--- create_schema defaults TRUE when prefix != "public"
end
```

**Oban semantics confirmed:**
- Option name: `prefix:` (string value, e.g. `"private"`)
- Option name: `create_schema:` (boolean)
- Default for `create_schema`: `true` when `prefix != "public"`, `false` when `prefix == "public"`
- Parapet's "Oban-verbatim" (GEN-04) means the same option names and default behavior: `create_schema: true` is the default for non-public prefixes; `--no-create-schema` sets it false.

**What "Oban-verbatim" does NOT mean:** Oban has no installer flag `--prefix`. The "verbatim" refers to borrowing Oban's option semantics/naming, not wrapping an Oban API.

---

### 6. Ecto `%Table{prefix:, name:}` separation — FK/index name behavior confirmed

**Verified source:** `deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex` (ecto_sql 3.13.5) and `deps/ecto_sql/lib/ecto/migration.ex`

**FK constraint names** — source at connection.ex:1884-1885:
```elixir
# [VERIFIED: deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1884-1885]
defp reference_name(%Reference{name: nil}, table, column),
  do: quote_name("#{table.name}_#{column}_fkey")
```
Uses `table.name` (bare string, e.g. `"parapet_tool_audits"`) only. `table.prefix` is NOT used. A `references(:parapet_timeline_entries, prefix: "parapet", ...)` produces the constraint name `parapet_tool_audits_timeline_entry_id_fkey` — identical to the unprefixed baseline.

**Index names** — source at migration.ex:1041-1046:
```elixir
# [VERIFIED: deps/ecto_sql/lib/ecto/migration.ex:1041-1045]
defp default_index_name(index) do
  [index.table, index.columns, "index"]
  |> List.flatten()
  |> Enum.map_join("_", &column_name/1)
  |> String.to_atom()
end
```
Uses `index.table` (bare table name) only. `index.prefix` is NOT used in name generation.

**Table reference in DDL** — connection.ex:1264,1858:
```elixir
# [VERIFIED: deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1264]
table_name = quote_name(table.prefix, table.name)
# → "parapet"."parapet_incidents"

# [VERIFIED: deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1858]
quote_name(Keyword.get(ref.options, :prefix, table.prefix), ref.table)
# → FK target uses ref's explicit prefix, falling back to enclosing table's prefix
```

**D-03 is correct and verified.** `prefix:` on `references/2` must be explicit (D-02) because `connection.ex:1858` uses `Keyword.get(ref.options, :prefix, table.prefix)` — the fallback is the **enclosing table's prefix**, which is available at migration execution time (when `Runner.prefix()` provides it). However, D-02's rationale (legibility to a reviewer) is still valid. Stamping the `references/2` `prefix:` explicitly in the heredoc is the correct and clearest approach.

**Pitfall:** `create index` does NOT inherit any prefix from the enclosing `create table` block — `index/3` in `migration.ex:1014-1027` constructs a standalone `%Index{}`. The prefix must be explicit on every index call.

---

### 7. `Igniter.Test.assert_creates/3` — exact-bytes when content provided

**Verified source:** `deps/igniter/lib/igniter/test.ex:638-671`

```elixir
# [VERIFIED: deps/igniter/lib/igniter/test.ex:638-671]
def assert_creates(igniter, path, content \\ nil) do
  assert source = igniter.rewrite.sources[path], ...
  assert source.from == :string, ...   # must be a newly created file

  if content do
    actual_content = Rewrite.Source.get(source, :content)
    if actual_content != content do
      flunk("""
      Expected created file #{inspect(path)} to have the following contents:
      #{content}
      But it actually had the following contents:
      #{actual_content}
      Diff, showing your assertion against the actual contents:
      #{TextDiff.format(actual_content, content)}
      """)
    end
  end
  igniter
end
```

**`assert_creates/3` semantics:**
- 2-arg form (`assert_creates/2`): asserts the file was created, doesn't check content.
- 3-arg form (`assert_creates/3`): asserts the file was created AND the content is **byte-for-byte identical**.
- Returns `igniter` for chaining.
- Already used in `parapet.gen.archive_indexes_test.exs:20` in 2-arg form.

**`refute_creates/2`** confirmed at line 688:
```elixir
# [VERIFIED: deps/igniter/lib/igniter/test.ex:688]
def refute_creates(igniter, path) do
  source = igniter.rewrite.sources[path]
  if source && source.from == :string do flunk(...) end
end
```
Use `refute_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs")` for the `--no-create-schema` test.

**`assert_has_patch/3`** at line 501: does a substring match on the diff text — useful for AST-substring assertions when exact bytes are formatter-dependent.

**D-16 golden test strategy:** For the schema migration golden (exact bytes), the recommended approach is:
1. Capture the actual content from a test run (using `Rewrite.Source.get(source, :content)`).
2. Format it through `mix format` or verify it matches Igniter's unformatted output.
3. Paste as a `content` string in `assert_creates/3`.

The `prefix:` count-guard uses `Regex.scan` on the migration source string directly (not AST). The FK-name assertion uses `contains_snippet?` on the AST (existing helper pattern in both test files).

---

## Standard Stack

### Core (all pre-installed — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| igniter | 0.7.9 | Mix task scaffolding, config writes, migration generation | Already used by all three tasks |
| ecto_sql | 3.13.5 | Migration DSL (`create table`, `references`, `create index`) | Project database layer |
| oban | 2.22.1 | Semantic precedent for `prefix:`/`create_schema:` flag naming | Already in deps; the naming model only |

**No new packages.** Phase 53 is pure source edits + test additions.

## Package Legitimacy Audit

> No new external packages are introduced in this phase. All work is source edits to existing modules and tests. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
mix parapet.gen.spine --schema parapet
        │
        ▼
  Igniter.Mix.Task (gen.spine)
    info/2 returns %Info{group: :parapet, schema: [schema: :string, ...]}
        │
        ├── args_for_group/2 routes --schema / --parapet.schema → options[:schema]
        │
        ▼
  resolve_prefix/2 (Parapet.Spine.Schema)
    flag = options[:schema]           # "parapet" from CLI
    config = Application.get_env(...)  # existing adopter config or nil
    → {:ok, "parapet"} | {:conflict, flag, config}
        │
        ├─ conflict → Igniter.add_warning/2 ("reconcile config.exs; run mix deps.compile --force")
        │
        ▼
  Prefix is resolved → "parapet" (or nil for public leg)
        │
        ├── if prefix non-nil:
        │     gen_migration(..., timestamp: "00000000000000", ...) → sentinel file
        │     configure_new("config.exs", :parapet, [:schema_prefix], resolved_prefix)
        │
        ├── DDL heredoc stamping:
        │     create table(:parapet_incidents, primary_key: false, prefix: "parapet") do
        │     references(:parapet_incidents, type: :binary_id, prefix: "parapet", ...)
        │     create index(:parapet_incidents, [...], prefix: "parapet")
        │
        └── if create_schema: false:
              Igniter.add_notice/2 (DBA remediation copy)
              refute_creates sentinel path in tests
```

### Recommended Project Structure

No new files/directories needed beyond what the generator produces. All edits are in:

```
lib/parapet/spine/schema.ex          # add resolve_prefix/2
lib/mix/tasks/parapet.gen.spine.ex   # add Info schema + resolver + prefix stamping
lib/mix/tasks/parapet.gen.archive_indexes.ex  # add Info schema + resolver + prefix stamping
lib/mix/tasks/parapet.install.ex     # extend Info schema + call resolver
priv/repo/migrations/*.exs           # 5 files: add prefix: __prefix__() calls
examples/demo_app/priv/repo/migrations/*.exs  # 3 files: same
test/mix/tasks/parapet.gen.spine_test.exs          # extend with D-16 tests
test/mix/tasks/parapet.gen.archive_indexes_test.exs # extend with D-16 tests
```

### Pattern 1: resolve_prefix/2 on Parapet.Spine.Schema

Two arities — pure core (table-testable) + thin Igniter arity:

```elixir
# [VERIFIED pattern: matches D-05 spec, thread shape matches existing schema.ex]
# Pure core — no Igniter dependency
def resolve_prefix(flag, existing_config) do
  normalized_flag = if flag, do: normalize(flag), else: nil
  normalized_config = if existing_config, do: normalize(existing_config), else: nil

  cond do
    is_nil(normalized_flag) and is_nil(normalized_config) ->
      {:ok, normalize("parapet")}  # default

    is_nil(normalized_flag) ->
      {:ok, normalized_config}

    is_nil(normalized_config) ->
      {:ok, normalized_flag}

    normalized_flag == normalized_config ->
      {:ok, normalized_flag}

    true ->
      # flag != config — flag wins, but warn
      {:conflict, normalized_flag, normalized_config}
  end
end

# Igniter-aware arity
def resolve_prefix(igniter) do
  flag = igniter.args.options[:schema]
  existing_config = Application.get_env(:parapet, :schema_prefix)
  resolve_prefix(flag, existing_config)
end
```

Note: `safe_ident!/1` is called inside `normalize/1` already — so `resolve_prefix/2` gets it for free. No need to call `safe_ident!` separately.

### Pattern 2: prefix-stamped DDL in gen.spine heredoc (generate-time literal)

```elixir
# [VERIFIED: consistent with D-01/D-02; Ecto source confirms prefix: on each call]
# resolved is the String or nil returned by resolve_prefix
prefix_opts = if resolved, do: ", prefix: #{inspect(resolved)}", else: ""

body = """
  def change do
    create table(:parapet_incidents, primary_key: false#{prefix_opts}) do
      # ...
    end

    create unique_index(:parapet_incidents, [:correlation_key], #{if resolved, do: "prefix: #{inspect(resolved)}, ", else: ""}where: "state = 'open'")

    create table(:parapet_timeline_entries, primary_key: false#{prefix_opts}) do
      add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all#{prefix_opts}), null: false
    end
  end
"""
```

### Pattern 3: prefix-stamped DDL in committed migrations (compile-time call)

```elixir
# [VERIFIED: matches D-11; __prefix__/0 is the single compile-time source]
defmodule Parapet.Repo.Migrations.CreateParapetActionClaims do
  use Ecto.Migration

  @prefix Parapet.Spine.Schema.__prefix__()

  def change do
    create table(:parapet_action_claims, primary_key: false, prefix: @prefix) do
      add :incident_id,
          references(:parapet_incidents, type: :binary_id, on_delete: :delete_all, prefix: @prefix),
          null: false
      # ...
    end

    create unique_index(:parapet_action_claims, [:incident_id, :action_kind, :action_key],
             prefix: @prefix)
  end
end
```

**Important:** `@prefix` at module level calls `__prefix__/0` at compile time. Under the `public` CI leg, `__prefix__()` returns `nil`, and Ecto's `create table(:foo, prefix: nil)` is equivalent to no prefix — byte-identical to the legacy output. Verified via `migration.ex:1733-1747` which handles nil prefix by falling back to `runner_prefix`.

### Pattern 4: `--no-create-schema` conditional sentinel

```elixir
# In gen.spine igniter/1:
igniter =
  if options[:create_schema] do
    Igniter.Libs.Ecto.gen_migration(igniter, repo_module, "create_parapet_schema",
      timestamp: "00000000000000",
      on_exists: :skip,
      body: """
        def up do
          execute("CREATE SCHEMA IF NOT EXISTS #{resolved}")
        end

        def down do
          execute("DROP SCHEMA IF EXISTS #{resolved}")
        end
      """
    )
  else
    igniter
    |> Igniter.add_notice(dba_remediation_notice(resolved))
  end
```

### Anti-Patterns to Avoid

- **Calling `configure_new/5`:** The installed `configure_new` is `/6`. The 5th argument is `value`; always pass it. The 6th `opts` defaults to `[]` but name it explicitly when adding `failure_message:`.
- **`prefix: nil` in generated migrations:** Emit nothing at all for the nil/public leg (D-04). `prefix: nil` would appear in the heredoc as the literal string `"prefix: nil"` and would still be parsed — it has different semantics from absence.
- **Putting `prefix:` on the sentinel schema migration's `execute/1`:** `execute/1` is raw SQL, not an Ecto table struct. Prefix belongs in the SQL string itself (`CREATE SCHEMA IF NOT EXISTS parapet`), not as an Ecto option.
- **Using `add_notice/2` for the conflict warning:** Notices appear after the run and are deduped. The conflict warning should be `add_warning/2` — visible during the run, can fire per invocation with different values.
- **Setting `:on_exists` to `:overwrite` for the sentinel:** If a user re-runs `gen.spine`, the sentinel already exists. Use `:skip` so a second install is idempotent.
- **`group: :parapet` on `install` without adding `schema:` to its `Info.schema`:** The `install` task must declare `schema: :string` and `create_schema: :boolean` in its `Info` schema for `args_for_group` to pass these flags through to composed tasks. Tasks in `composes:` have their schemas merged recursively, but `install` itself must accept them to surface in `--help`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Config no-clobber write | Custom zipper manipulation | `configure_new/6` | Already handles "if exists, skip" via `updater: &{:ok, &1}` |
| Migration file generation | `File.write!` calls | `Igniter.Libs.Ecto.gen_migration/4` | Handles path, module naming, dedup, `on_exists` |
| Exact-bytes file assertion | Manual `File.read!` comparison | `assert_creates/3` | Already integrated with Igniter.Test harness |
| Notice deduplication | Manual `notices in acc` check | `add_notice/2` | Igniter does this already (line 418-422) |
| SQL identifier safety | Custom regex | `safe_ident!/1` (already on `Parapet.Spine.Schema`) | The allowlist guard is already implemented |

---

## Common Pitfalls

### Pitfall 1: `on_exists: :increment` creates `create_parapet_schema_1.exs` on re-run

**What goes wrong:** `gen_migration/4` default `:on_exists` is `:increment`. If a user runs `mix parapet.gen.spine` twice, the second call finds `create_parapet_schema` module exists, appends `_1`, and produces a second sentinel file with a different filename. The Igniter `test_project()` harness starts fresh so tests don't expose this.

**How to avoid:** Pass `on_exists: :skip` for the sentinel. First install generates it; subsequent installs skip silently.

**Warning signs:** Two `00000000000000_create_parapet_schema*.exs` files in `priv/repo/migrations/`.

### Pitfall 2: Nil prefix in the `--no-create-schema` branch still needs prefix-stamped DDL

**What goes wrong:** An operator passes `--no-create-schema --schema parapet`. The `create_schema: false` flag only means "omit the sentinel migration." The resolved prefix is still `"parapet"`, and DDL must still be stamped with `prefix: "parapet"`. Mixing up these two flags leads to tables created in `public` with no schema migration, defeating the purpose.

**How to avoid:** `--no-create-schema` controls only the sentinel migration. `resolve_prefix/2` runs regardless. DDL stamping depends on `resolved_prefix != nil`, not on `create_schema`.

### Pitfall 3: `@prefix` module attribute in committed migrations evaluated at compile time

**What goes wrong:** Writing `prefix: Parapet.Spine.Schema.__prefix__()` directly inside `create table(...)` calls (not as a module attribute) means Ecto's migration macro tries to call the function at compile time of the migration module, not at schema resolution time. For the library's own migrations, this is fine if `parapet` app is compiled first. But if the migration file is compiled before `Parapet.Spine.Schema`, you get a compile error.

**How to avoid:** Use a module attribute `@prefix Parapet.Spine.Schema.__prefix__()` at the top of the migration module and pass `@prefix` into the macro calls. This is the idiomatic Elixir pattern for compile-time constants in migrations.

### Pitfall 4: Index prefix in the `drop` direction of archive_indexes migration

**What goes wrong:** The archive_indexes `down/0` calls `drop index(...)` and `drop constraint(...)`. These must also carry `prefix: resolved` on the index/constraint reference, or Postgres looks in `public` and fails with "index does not exist."

**How to avoid:** Every `drop index(...)` and `drop constraint(...)` in the heredoc must carry the same `prefix:` literal as the corresponding `create` call.

### Pitfall 5: generate-time vs compile-time confusion in tests

**What goes wrong:** Tests call `Spine.igniter()` in `test_project()` context, where `Application.get_env(:parapet, :schema_prefix)` may return the compiled test value (`"parapet"` under the prefixed CI leg). The resolver then sees the config already set and may treat `--schema parapet` as non-conflicting, masking conflict-path tests.

**How to avoid:** For conflict-branch tests, explicitly override `Application.get_env` via `Application.put_env` in the test setup (or use the pure `resolve_prefix/2` core directly, bypassing Igniter). The pure core is the reason D-05 specifies "table-testable with zero Igniter scaffolding."

### Pitfall 6: Backslash-escape collision in heredoc SQL strings

**What goes wrong:** The existing `gen.spine` heredoc uses `parapet_action_claims` etc. as string literals inside the heredoc, which is fine. But interpolating `prefix: #{inspect(resolved)}` can produce `prefix: "parapet"` or `prefix: nil`. The string `"nil"` (if `inspect(nil)` is used) in the heredoc is incorrect — the intent is no `prefix:` at all.

**How to avoid:** Gate the prefix option on `resolved != nil`. When nil, omit the `, prefix: ...` fragment entirely from the interpolation. Do not pass `prefix: nil` to Ecto migration macros.

---

## Committed Migration File Audit

All 8 files have been read. Summary of edits required per D-10/D-11:

### Library migrations (`priv/repo/migrations/*.exs`)

| File | Operations requiring `prefix:` |
|------|-------------------------------|
| `20260511000000_add_runbook_data_to_incidents.exs` | `alter table(:parapet_incidents)` — add `prefix: @prefix` |
| `20260516233447_add_trace_id_to_incidents.exs` | `alter table(:parapet_incidents)` — add `prefix: @prefix` |
| `20260517000000_add_parapet_system_events.exs` | `create table(:parapet_system_events)`, `create index(...)` — add `prefix: @prefix` |
| `20260521010000_create_parapet_action_claims.exs` | `create table(:parapet_action_claims)`, `references(:parapet_incidents)`, 3 `create index/unique_index` — add `prefix: @prefix` |
| `20260528010000_add_lease_until_to_parapet_action_claims.exs` | `alter table(:parapet_action_claims)`, raw `execute("UPDATE parapet_action_claims …")`, `create index(...)` — add `prefix: @prefix` on Ecto calls; raw SQL UPDATE is trickier (see below) |

**Landmine in `add_lease_until`:** The raw `execute("UPDATE parapet_action_claims SET lease_until = …")` cannot take a `prefix:` Ecto option — it is raw SQL. Under the prefixed leg this query will fail if `parapet_action_claims` is in the `parapet` schema, because the SQL references the bare table name without schema qualification.

**Resolution (D-11 mandate, code read confirms):** The `execute/2` call must interpolate the schema-qualified table name:
```elixir
# In the committed migration, using @prefix:
execute(
  if @prefix,
    do: "UPDATE #{inspect(@prefix)}.parapet_action_claims SET lease_until = ...",
    else: "UPDATE parapet_action_claims SET lease_until = ..."
)
```
Or use `Parapet.Spine.Schema.__prefix__()` inline in the string. This is not a generated adopter migration (D-01 doesn't apply), so the compile-time binding is correct.

### Demo migrations (`examples/demo_app/priv/repo/migrations/*.exs`)

| File | Operations requiring `prefix:` |
|------|-------------------------------|
| `20260525000000_add_parapet_spine_tables.exs` | 5 `create table`, 2 `references`, 8 `create index/unique_index` |
| `20260525000001_add_action_item_kind_and_incident_id.exs` | `alter table(:parapet_action_items)`, `references(:parapet_incidents)`, `create index` |
| `20260525000002_add_parapet_action_claims.exs` | `create table(:parapet_action_claims)`, `references(:parapet_incidents)`, 4 `create index/unique_index` |

Demo migrations use `DemoApp.Repo.Migrations.*` namespace and already inline all columns (no incremental alters on the demo side). Edits are straightforward `prefix: @prefix` additions.

---

## Validation Architecture

`workflow.nyquist_validation` key is absent from `.planning/config.json` — treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) + Igniter.Test |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mix/tasks/parapet.gen.spine_test.exs test/mix/tasks/parapet.gen.archive_indexes_test.exs --no-start` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | File | Automated Command | Exists? |
|--------|----------|-----------|------|-------------------|---------|
| GEN-01 | Sentinel `00000000000000_create_parapet_schema.exs` created | unit (Igniter.Test) | `parapet.gen.spine_test.exs` | `mix test test/mix/tasks/parapet.gen.spine_test.exs` | ❌ Wave 0 |
| GEN-01 | `--no-create-schema` omits sentinel | unit | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-01 | Non-cascading `DROP SCHEMA` in down | unit (assert_creates/3 golden) | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-02 | `prefix:` count-guard on gen.spine output | unit (Regex.scan) | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-02 | FK constraint name unchanged under parapet leg | unit (contains_snippet?) | `parapet.gen.spine_test.exs` and `parapet.gen.archive_indexes_test.exs` | same | ❌ Wave 0 |
| GEN-02 | FK constraint name unchanged under nil (public) leg | unit (contains_snippet?) | same files | same | ❌ Wave 0 |
| GEN-02 | Nil leg → byte-identical to current output | unit (assert_creates/3 golden) | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-03 | `configure_new` writes `:schema_prefix` config | unit (Igniter.Test) | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-03 | Conflict warns, does not crash | unit (resolve_prefix/2 pure core) | `test/parapet/spine/schema_test.exs` | `mix test test/parapet/spine/schema_test.exs` | ❌ Wave 0 |
| GEN-04 | `--no-create-schema` produces notice (Igniter notices) | unit | `parapet.gen.spine_test.exs` | same | ❌ Wave 0 |
| GEN-05 | Same resolver used by all three tasks | unit (pure core) | `schema_test.exs` | same | ❌ Wave 0 |
| GEN-06 | Committed migrations have `prefix:` under parapet leg | integration (full suite, parapet CI leg) | CI matrix | `PARAPET_SCHEMA_PREFIX=parapet mix test` | ❌ (implicit in CI matrix) |
| GEN-07 | All test assertions listed above | unit | see above | see above | ❌ Wave 0 |

### Key test details for D-16 (GEN-07)

**`prefix:` count-guard (Regex.scan):**
```elixir
# Assert that every table, reference, and index carries prefix: in the generated migration
# Total expected: (N tables) + (N references) + (N indexes) occurrences
prefix_count = migration_source |> String.scan(~r/\bprefix:/) |> length()
assert prefix_count >= expected_count
```

**Schema migration golden (`assert_creates/3`):**
```elixir
assert_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs",
  """
  defmodule TestRepo.Migrations.CreateParapetSchema do
    use Ecto.Migration

    def up do
      execute("CREATE SCHEMA IF NOT EXISTS parapet")
    end

    def down do
      execute("DROP SCHEMA IF EXISTS parapet")
    end
  end
  """
)
```
The exact content must match Igniter's formatting exactly. Use a live test run to capture the real content first, then pin it.

**`refute_creates` for `--no-create-schema`:**
```elixir
test "skips sentinel migration under --no-create-schema" do
  igniter =
    test_project(app_name: :test)
    |> Igniter.assign(:argv, ["--no-create-schema"])
    |> Spine.igniter()

  refute_creates(igniter, "priv/repo/migrations/00000000000000_create_parapet_schema.exs")
end
```

**FK constraint name unchanged:**
```elixir
assert contains_snippet?(
  migration_ast,
  ~s(drop(constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey")))
)
```
This assertion runs under both legs. The constraint name must be byte-identical regardless of `prefix:`.

### Wave 0 Gaps

- [ ] New tests in `test/mix/tasks/parapet.gen.spine_test.exs` covering GEN-01/02/03/04/07
- [ ] New tests in `test/mix/tasks/parapet.gen.archive_indexes_test.exs` covering GEN-02/07
- [ ] New tests in `test/parapet/spine/schema_test.exs` covering `resolve_prefix/2` pure core (GEN-05, GEN-03 conflict path)

---

## Security Domain

`security_enforcement` key is absent from `.planning/config.json` — treat as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | `safe_ident!/1` (already implemented on `Parapet.Spine.Schema`) |
| V6 Cryptography | no | — |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via schema prefix (Triplex/apartment CVE-class) | Tampering | `safe_ident!/1` allowlist (`^[a-z_][a-z0-9_]*$`, 63 bytes) — already applied in `normalize/1` |
| Slopsquatting of schema names | Tampering | `safe_ident!/1` rejects non-lowercase identifiers and reserved-word patterns |

`resolve_prefix/2` runs through `normalize/1` which calls `safe_ident!/1` before any interpolation — so any prefix that reaches the heredoc has already been allowlist-validated. This is the correct defense-in-depth position.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Ecto migrator sorts by `Integer.parse(filename_prefix)` → version 0 sorts first | Standard Stack / D-13 | The sentinel migration would not run first, breaking GEN-01; low risk — this is documented Ecto behavior |
| A2 | `prefix: nil` on an Ecto table/index call is functionally equivalent to omitting it at runtime | Pattern 3 | Tables could land in wrong schema; verify with actual migration test under the `public` CI leg |
| A3 | `Application.get_env(:parapet, :schema_prefix)` inside `resolve_prefix/2` returns the adopter's runtime config correctly during a `mix` invocation (not the compiled value) | resolve_prefix/2 pattern | Conflict detection would not work; low risk — `Application.get_env` at mix-task invocation time reads the host's running config, not compile_env |

---

## Open Questions

1. **`resolve_prefix/2` Igniter arity return type** (Claude's Discretion)
   - What we know: D-05 says "returns the value or a `{igniter, value}` tuple (planner's call)".
   - What's unclear: If the Igniter arity calls `add_warning/2`, it must carry the igniter. So the Igniter arity must return `{igniter, resolved}` (to thread warnings). The pure core returns `{:ok, value} | {:conflict, v1, v2}`.
   - Recommendation: Igniter arity returns `{igniter, resolved_value}` where `igniter` may have a warning prepended. The pure core returns the `:ok`/`:conflict` tuple directly.

2. **raw SQL UPDATE in `add_lease_until_to_parapet_action_claims.exs`**
   - What we know: `execute("UPDATE parapet_action_claims SET lease_until = …")` is a raw SQL call without Ecto's prefix support.
   - What's unclear: D-11 says use `__prefix__()`, but doesn't address raw SQL explicitly.
   - Recommendation: Planner add an explicit sub-task for this file: replace the bare table reference in the `execute` call with a schema-qualified interpolation using `@prefix`. The pattern:
     ```elixir
     @prefix Parapet.Spine.Schema.__prefix__()
     @table if @prefix, do: ~s("#{@prefix}"."parapet_action_claims"), else: "parapet_action_claims"
     execute("UPDATE #{@table} SET lease_until = claimed_at + INTERVAL '5 minutes'", "")
     ```

3. **`install.ex` should it also call `resolve_prefix/2` or only compose `gen.spine`?**
   - What we know: `install.ex` currently calls `Igniter.compose_task("parapet.gen.spine", [])` and `gen.spine` would itself call `resolve_prefix`. `install` must forward `--schema` and `--no-create-schema` to composed tasks.
   - What's unclear: Whether `install` needs to call `configure_new` itself (it currently calls `Config.configure` for `:repo` and `:instrumenter`, not `:schema_prefix`).
   - Recommendation: `install` should declare `schema: :string` and `create_schema: :boolean` in its `Info` schema with `group: :parapet`, which causes Igniter to forward these flags to `gen.spine` via `args_for_group`. No direct resolver call needed from `install` since `gen.spine` (composed) handles the config write. Config write happens inside `gen.spine`; `install` passes the flags through.

---

## Environment Availability

This phase is code/config edits only. No new external tools, runtimes, or services are required. The existing Postgres test DB is required for integration testing under the CI dual-prefix matrix, but that is already available (Phase 52 CI matrix runs green).

**Step 2.6: SKIPPED** — no new external dependencies; all deps already installed.

---

## Sources

### Primary (HIGH confidence — read directly from installed dep source)

- `deps/igniter/lib/igniter/project/config.ex:27-38` — `configure_new/6` signature and no-clobber semantics
- `deps/igniter/lib/igniter.ex:408-422` — `add_warning/2` and `add_notice/2` signatures and behavior
- `deps/igniter/lib/mix/task/info.ex:93-108` — `%Igniter.Mix.Task.Info{}` struct and `group:` field type
- `deps/igniter/lib/igniter/util/info.ex:524-528,382-450` — `group/2` atom→string conversion, `args_for_group/2` routing
- `deps/igniter/lib/igniter/libs/ecto.ex:17-108` — `gen_migration/4`, `:timestamp` option, `:on_exists` default
- `deps/igniter/lib/igniter/test.ex:638-671,501-531,688-700` — `assert_creates/3`, `assert_has_patch/3`, `refute_creates/2`
- `deps/oban/lib/oban/migrations/postgres.ex:10,88,94` — `prefix:`, `create_schema:` option names and defaults
- `deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1264,1858,1884-1885` — FK/index name vs. prefix separation
- `deps/ecto_sql/lib/ecto/migration.ex:1041-1045` — default index name from table+columns (no prefix)
- `lib/parapet/spine/schema.ex` — `__prefix__/0`, `normalize/1`, `safe_ident!/1` current shape
- `lib/mix/tasks/parapet.gen.spine.ex` — existing heredoc body and `gen_migration` call
- `lib/mix/tasks/parapet.gen.archive_indexes.ex` — existing heredoc body, FK constraint drop pattern
- `lib/mix/tasks/parapet.install.ex` — existing `Info` struct, `Igniter.add_notice` pattern, `compose_task` pattern
- `test/support/concurrency_bootstrap.ex` — the `q/1` two-leg qualifier, already-working prefix resolution pattern
- `priv/repo/migrations/*.exs` (5 files) — read all; identified raw SQL landmine in `add_lease_until`
- `examples/demo_app/priv/repo/migrations/*.exs` (3 files) — read all
- `test/mix/tasks/parapet.gen.spine_test.exs` — `contains_snippet?`, existing `Regex.scan` pattern for counts
- `test/mix/tasks/parapet.gen.archive_indexes_test.exs` — `assert_creates/2` usage, FK drop constraint pattern

### Tertiary (LOW confidence)

- A2 (`prefix: nil` equivalence) — assumed from Ecto semantics; needs empirical verification under the `public` CI leg

---

## Metadata

**Confidence breakdown:**
- API signatures: HIGH — all read from installed dep source code
- Architecture patterns: HIGH — derived from verified source + existing task code
- Committed migration edits: HIGH — all 8 files read; one landmine (raw SQL in `add_lease_until`) identified
- Test patterns: HIGH — `assert_creates/3` and helpers read from Igniter.Test source

**Research date:** 2026-07-01
**Valid until:** 2026-08-01 (Igniter and ecto_sql are stable; no breaking changes expected in 30 days on a locked mix.lock)

---

## RESEARCH COMPLETE
