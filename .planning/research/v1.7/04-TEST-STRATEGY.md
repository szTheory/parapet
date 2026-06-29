# v1.7 Test Strategy & Contract Safety (TEST-INFRA + CONTRACT-SAFETY)

**Dimension:** Elixir test-architecture + release-safety
**Milestone:** v1.7 Postgres Schema Isolation — 6 spine tables move to a dedicated `parapet` schema by default via a compile-time `@schema_prefix` (`Application.compile_env(:parapet, :schema_prefix, "parapet")`); runtime `prefix:` banned; `nil`/`"public"` ⇒ unprefixed.
**Confidence:** HIGH on the central recommendation and Sandbox mechanics; MEDIUM on a couple of Ecto-internal edge details (flagged inline).

---

## 0. Critical context discovered in the codebase (read this first)

These facts change the shape of the recommended solution. They override naive assumptions in the requirements:

1. **The library has NO `config/` directory at all.** There is no `config/config.exs`, no `config/test.exs`, no `runtime.exs` in the lib root (only `examples/demo_app/config/*`). `mix verify.public_api`, `mix test`, etc. all run with **zero project config files**. Therefore `Application.compile_env(:parapet, :schema_prefix, "parapet")` will, in the lib's own build, **always resolve to the default `"parapet"`** unless we add a config file or feed it from an env var at config-eval time. There is currently nowhere for a value to come from. **This is a footgun and an opportunity**: it means we get to design the config seam from scratch, and we must add a `config/config.exs` (gated on an env var) to make the dual-prefix matrix possible at all.

2. **The main test suite does NOT use migrations.** `test/test_helper.exs` boots a single `ConcurrencyRepo` (Sandbox pool) and calls `ConcurrencyBootstrap.bootstrap!/0`, which issues hand-written `CREATE TABLE` / `CREATE INDEX` DDL for the 6 spine tables. `reset!/0` does a raw `TRUNCATE`. The schema prefix lives **only** in those hand-written strings plus the `schema "parapet_incidents"` declarations in `lib/parapet/spine/*.ex`. There is no `Parapet.Repo`; `:parapet, :repo` is injected by `ConcurrencyCase.setup` (`Application.put_env(:parapet, :repo, ConcurrencyRepo)`).

3. **Spine schemas today have NO `@schema_prefix`.** e.g. `lib/parapet/spine/incident.ex` is just `schema "parapet_incidents" do`. v1.7 adds `@schema_prefix unquote(Application.compile_env(:parapet, :schema_prefix, "parapet"))` (or equivalent) to all 6. When that value is `nil`/`"public"`, the schema must compile to an unprefixed table.

4. **`ConcurrencyCase` is the workhorse.** Sandbox checkout + `ConcurrencyBootstrap.reset!()` run per test (unless `@tag :unboxed`). Manual mode is set in `test_helper.exs` (`Sandbox.mode(ConcurrencyRepo, :manual)`).

5. **CI** (`.github/workflows/ci.yml`) runs three jobs — `lint` (includes `mix verify.public_api`), `test` (`mix test` against a `postgres:16-alpine` service, DB `parapet_concurrency_test`), `demo` (`cd examples/demo_app && mix ecto.create && mix ecto.migrate && mix test --only smoke`) — gated by `release_gate`. Matrix is OTP 26/27/28 on Elixir 1.19.

6. **Migration backfill test** (`test/parapet/repo/migrations/add_lease_until_backfill_test.exs`) already demonstrates the canonical "escape the Sandbox" pattern: a dedicated `DBConnection.ConnectionPool` repo + a bare `Postgrex` connection, `@tag :unboxed`, idempotent `on_exit` teardown that restores the canonical bootstrap DDL. **The Track B round-trip test (§6) should be modeled on this file almost verbatim.**

---

## 1. Summary recommendation (decisive)

**Adopt a combination, with a clear primary:**

- **Primary (satisfies TEST-02 for real): a CI matrix leg that recompiles under each prefix.** Add a `schema_prefix: ['parapet', '']` (or `['parapet', 'public']`) axis to the `test` job. Feed the value into a new `config/config.exs` via `System.get_env("PARAPET_SCHEMA_PREFIX")` so `Application.compile_env/3` bakes it in at compile time. Each matrix leg does a **clean compile** (no `_build` cache reuse across prefix values — see footgun F1) and runs the full `mix test`. This is the only mechanism that truly proves "suite green under `parapet` AND under `nil`" because `@schema_prefix` is a compile-time constant and **cannot be flipped within one BEAM run**.

- **Secondary (fast, in-process, no recompile): `to_sql`-level propagation assertions.** A single in-process test module asserts that the *currently compiled* prefix is emitted by representative queries / `insert_all` / `Multi` via `Ecto.Adapters.SQL.to_sql/3` and `Ecto.get_meta/2`. This is cheap drift insurance that runs in **every** matrix leg and therefore validates *both* prefixes (each leg sees its own compiled constant). It is NOT a substitute for the recompiled run — it cannot exercise Sandbox checkout / TRUNCATE under the other prefix — but it makes propagation regressions fail fast and locally.

- **Tertiary (guard): a runtime-`prefix:`-ban grep/AST test.** A test that proves no source file in `lib/` threads a runtime `prefix:` option into a query/changeset/`insert_all`/`Multi`/`Repo` call. Pure static check, no DB.

- **Do NOT** attempt option (b) "parallel stay-on-public assertion via a separately compiled config in the same run." It's not possible: there is one compiled `@schema_prefix` per BEAM. You can compile a *throwaway test-only schema module* with a literal `@schema_prefix nil` to assert the unprefixed SQL shape (a `to_sql` micro-check), but that proves the *Ecto mechanism*, not *your spine modules*. Keep it as a tiny supplement, not the TEST-02 proof.

**One-paragraph rationale:** `compile_env` is a compile-time seam by design (Phoenix moved its endpoint config to `compile_env` precisely so the value is frozen at build time). The ElixirForum consensus is unambiguous: you cannot change a `compile_env` value mid-run; `recompile/1` does not reload config. The only honest way to get "green under both values" is **two builds**, which maps cleanly onto a CI matrix axis. The `to_sql` checks and the runtime-ban guard ride along for free and give per-leg, fast-feedback coverage.

---

## 2. THE compile_env dual-prefix testing problem + chosen solution

### 2.1 Why TEST-02 cannot be satisfied at runtime

`@schema_prefix` is read at **module-compile time** from `Application.compile_env(:parapet, :schema_prefix, "parapet")`. Once `Parapet.Spine.Incident` is compiled, its prefix is a literal baked into the BEAM module. Within one `mix test` run:

- `Application.put_env(:parapet, :schema_prefix, nil)` does **nothing** to already-compiled schemas.
- `IEx.Helpers.recompile/1` "simply recompiles Elixir modules, without reloading configuration" ([ElixirForum](https://elixirforum.com/t/change-config-compile-env-variables-during-exunit-test/53526)) — and ExUnit isn't IEx anyway.
- Elixir actively *guards* against drift: if the value used at compile time differs from the value present at runtime, the VM raises `Application.compile_env/3` mismatch at boot. So even hacking `put_env` is hostile.

Conclusion: **TEST-02 = two compilations = two CI legs.** Anything else is theater.

### 2.2 The config seam to add (the lib currently has none)

Create **`config/config.exs`** in the library root:

```elixir
# config/config.exs
import Config

# Schema-prefix seam for v1.7. Resolved at COMPILE TIME by
# Application.compile_env(:parapet, :schema_prefix, "parapet") in the spine
# schemas and in ConcurrencyBootstrap. Consuming apps override this in their
# own config/config.exs; the library only sets it here to drive the CI
# dual-prefix matrix. Default-on (= "parapet") so omitting the env var keeps
# the new default behavior.
#
# Semantics: "" or "public" => unprefixed (public schema); anything else =>
# that schema name.
schema_prefix =
  case System.get_env("PARAPET_SCHEMA_PREFIX") do
    nil -> "parapet"          # default-on
    "" -> nil                 # explicit opt-out → unprefixed
    "public" -> nil           # treat public as unprefixed
    other -> other
  end

config :parapet, schema_prefix: schema_prefix
```

**Why `config/config.exs` and not `runtime.exs`:** `compile_env` reads from compile-time config. `runtime.exs` is evaluated at boot, *after* compilation, and Elixir will raise a `compile_env` mismatch if you try to source a `compile_env` key from runtime config. It **must** be `config/config.exs` (or an imported compile-time file).

**Footgun F0 — packaging:** `config/` is NOT in the Hex `package.files` list and should NOT be (consuming apps supply their own config; shipping a `config/config.exs` that sets `:parapet, :schema_prefix` could surprise adopters). It exists only for the lib's own build + CI. Confirm `mix.exs` `package[:files]` does **not** add `config`. (Today it lists `~w(lib priv ... )` — good, leave it.)

**Footgun F0b — the central normalization helper.** Put the `"" | "public" | nil ⇒ unprefixed` normalization in **one** place that *both* `config/config.exs` and any code path uses, so the three-way contract ("parapet" default / nil opt-out / "public" alias) can't drift. Recommend a tiny pure module compiled into `lib/` (e.g. `Parapet.Internal.SchemaPrefix.normalize/1`) and have `config.exs` call... — **caveat:** `config/config.exs` runs *before* the app is compiled, so it generally **cannot** call your lib modules. Keep the normalization literal in `config.exs` (as above) AND duplicate it as a unit-tested pure function the schemas use when they read the compiled value, and add a unit test asserting the two implementations agree on `["parapet", "", "public", nil, "custom"]`. (This is the cheapest guard against the two copies diverging.)

### 2.3 The CI matrix leg (runnable)

Modify the `test` job in `.github/workflows/ci.yml` to add a `schema_prefix` axis. Because `_build` is cached by OTP/Elixir/`mix.lock` only, **two legs with the same cache key but different compiled constants would poison each other** (F1). Fix by namespacing the cache key with the prefix value AND forcing a clean compile.

```yaml
  test:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        elixir: ['1.19.0']
        otp: ['26.x', '27.x', '28.x']
        schema_prefix: ['parapet', '']      # '' => unprefixed (public)
    env:
      MIX_ENV: test
      PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: parapet_concurrency_test
        ports: ['5432:5432']
        options: >-
          --health-cmd pg_isready --health-interval 10s
          --health-timeout 5s --health-retries 5
    steps:
      - uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5
      - uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93
        with:
          elixir-version: ${{ matrix.elixir }}
          otp-version: ${{ matrix.otp }}
      - name: Cache dependencies
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830
        with:
          path: deps
          key: ${{ runner.os }}-mix-${{ matrix.elixir }}-${{ matrix.otp }}-${{ hashFiles('**/mix.lock') }}
      # F1: build cache MUST include the prefix, or leg B reuses leg A's
      # compiled @schema_prefix and silently tests the wrong value.
      - name: Cache _build
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830
        with:
          path: _build
          key: ${{ runner.os }}-build-${{ matrix.elixir }}-${{ matrix.otp }}-sp-${{ matrix.schema_prefix }}-${{ hashFiles('**/mix.lock') }}
      - name: Install dependencies
        run: mix deps.get
      # Belt-and-suspenders: force the compile-env constant to be re-baked.
      - name: Recompile parapet with this prefix
        run: mix deps.compile --force parapet >/dev/null 2>&1 || true; mix compile --force
      - name: Test
        run: mix test
```

**Mechanics walkthrough (the exact env → compile_env path):**
`PARAPET_SCHEMA_PREFIX` (GitHub matrix) → read by `System.get_env/1` in `config/config.exs` → stored as compile-time `config :parapet, schema_prefix: …` → `Application.compile_env(:parapet, :schema_prefix, "parapet")` reads it during compilation of `lib/parapet/spine/*.ex` (and `ConcurrencyBootstrap`) → baked into each module as a literal. `mix compile --force` guarantees the bake happens this run.

**F1 in detail (the #1 silent-failure footgun):** Elixir *does* track `compile_env` reads and will recompile dependent modules when the value changes **within the same `_build`** — but across separate CI runners with a *restored* `_build` cache keyed only by `mix.lock`, the restored artifacts already encode the old prefix and `mix` may consider them current. The cache-key suffix `sp-${{ matrix.schema_prefix }}` + `mix compile --force` removes the ambiguity. Without this, the `''` leg can pass while actually still running the `parapet` build — a false green that defeats the entire milestone gate.

**F2 — empty-string matrix value:** YAML `''` becomes an empty env var, which `config.exs` maps to `nil` (unprefixed). If your shell/Action turns an unset-vs-empty distinction into trouble, prefer the literal `'public'` token in the matrix and let `config.exs` map `"public" -> nil`; it's more legible in the CI UI ("test (parapet)" vs "test (public)").

**F3 — the `demo` job:** it runs real migrations (`mix ecto.migrate`). If the demo app's migrations gain a prefix (Track A/default-on), the demo DB now needs `CREATE SCHEMA parapet`. Add a `schema_prefix` axis to the `demo` job too, OR pin the demo app to one prefix and add a second smoke leg. At minimum the default-on (`parapet`) demo leg must prove `mix ecto.migrate` creates the schema and `--only smoke` passes (see §5).

### 2.4 Decision table

| Option | Proves TEST-02? | Cost | Verdict |
|---|---|---|---|
| (a) CI matrix recompile per prefix | **Yes** (full suite incl. Sandbox/TRUNCATE under each) | +1 axis, ~2× test wall-clock | **PRIMARY** |
| (b) parallel "stay-on-public" in one run | No (one compiled constant per BEAM) | — | **Rejected** as TEST-02 proof; keep tiny `to_sql` literal-nil micro-check only |
| (c) `to_sql`/SQL-gen assertion of prefixed/unprefixed | Partially (mechanism + current-leg prefix) | trivial | **SECONDARY** (rides every leg) |
| (d) combination a+c+guard | **Yes, best** | low marginal | **CHOSEN** |

---

## 3. Sandbox under a non-public schema + `concurrency_bootstrap` changes

### 3.1 Does Sandbox work with non-`public` schemas? — Yes, with caveats

`Ecto.Adapters.SQL.Sandbox` is prefix-agnostic at the connection level: it wraps each checked-out connection in a transaction and isolates it. The *prefix* is a property of the **query/DDL**, not the sandbox. So checkout, ownership/`allow`, manual mode, and `unboxed_run` all keep working unchanged. What changes is that **every table reference must be schema-qualified** (or the connection's `search_path` must include the schema). Two viable strategies:

- **Strategy S1 (recommended): hard-qualify everything.** Make `ConcurrencyBootstrap` emit `parapet.parapet_incidents` etc., gated on the compiled prefix. No reliance on `search_path`. Most explicit, matches how Ecto emits prefixed SQL (`"parapet"."parapet_incidents"`), and makes the bootstrap DDL and the schemas' `@schema_prefix` agree by construction.
- **Strategy S2 (avoid): set `search_path`.** You *can* `ALTER ROLE … SET search_path` or issue `SET search_path` per checkout, but with the Sandbox transaction wrapper and pooled connections this is fragile (the `SET` must run inside the owned transaction every checkout, and it leaks across the prefix/no-prefix matrix). **Reject** in favor of explicit qualification.

**Caveat C1 (TRUNCATE inside the Sandbox transaction):** `reset!/0` currently runs `TRUNCATE … RESTART IDENTITY CASCADE`. `TRUNCATE` is transactional in Postgres, so it works inside the Sandbox's wrapping transaction — this is already how the suite operates today, so moving the qualified table names doesn't change the semantics. Just qualify the names.

**Caveat C2 (CREATE SCHEMA must exist before bootstrap):** `bootstrap!/0` runs once at `test_helper.exs` startup, **before** any sandbox checkout, on the raw `ConcurrencyRepo` pool. Add a `CREATE SCHEMA IF NOT EXISTS parapet` as the first DDL statement (only when prefixed). This is the right place — it's outside per-test transactions and idempotent.

**Caveat C3 (search_path & unqualified app code):** because we qualify via `@schema_prefix` on the schemas (Ecto emits the prefix), app code does **not** rely on `search_path`. Good. But any *raw* `SQL.query!` in `lib/` that names a bare table (grep for these!) will silently hit `public` and break under the prefix. Part of TEST-INFRA is to grep `lib/` for raw table names in SQL strings and route them through the prefix. (The migration backfill test uses raw SQL but it's test-only / Track B.)

### 3.2 `concurrency_bootstrap.ex` diff (conceptual)

Introduce a compile-time prefix and qualify all DDL. Sketch:

```elixir
defmodule Parapet.TestSupport.ConcurrencyBootstrap do
  @moduledoc false
  alias Ecto.Adapters.SQL
  alias Parapet.TestSupport.ConcurrencyRepo

  # Same seam the spine schemas read, so bootstrap DDL and @schema_prefix agree.
  @schema_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")
  # Normalize "" / "public" => nil (unprefixed). Keep identical to config.exs +
  # Parapet.Internal.SchemaPrefix.normalize/1 (asserted equal by a unit test).
  @prefix (case @schema_prefix do
             p when p in [nil, "", "public"] -> nil
             p -> p
           end)

  @base_tables ~w(
    parapet_action_claims parapet_tool_audits parapet_timeline_entries
    parapet_action_items parapet_system_events parapet_incidents
  )

  # Fully-qualified names for DDL + TRUNCATE.
  defp q(table), do: if(@prefix, do: ~s("#{@prefix}"."#{table}"), else: ~s("#{table}"))

  def bootstrap! do
    if @prefix, do: SQL.query!(ConcurrencyRepo, ~s(CREATE SCHEMA IF NOT EXISTS "#{@prefix}"), [])
    Enum.each(ddl_statements(), &SQL.query!(ConcurrencyRepo, &1, []))
  end

  def reset! do
    truncatable = Enum.map_join(@base_tables, ", ", &q/1)
    SQL.query!(ConcurrencyRepo, "TRUNCATE #{truncatable} RESTART IDENTITY CASCADE", [])
  end

  def table_names, do: @base_tables           # logical names unchanged
  def qualified_table_names, do: Enum.map(@base_tables, &q/1)

  defp ddl_statements do
    [
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_incidents")} (
        id uuid PRIMARY KEY,
        ...
      )
      """,
      # Index names are NOT schema-qualified in CREATE INDEX (the index lives in
      # the table's schema automatically), but the ON clause table IS:
      ~s(CREATE UNIQUE INDEX IF NOT EXISTS parapet_incidents_correlation_key_open_index
         ON #{q("parapet_incidents")} (correlation_key) WHERE state = 'open'),
      ...
      # FK REFERENCES must point at the qualified parent:
      """
      CREATE TABLE IF NOT EXISTS #{q("parapet_action_items")} (
        ...
        incident_id uuid REFERENCES #{q("parapet_incidents")}(id) ON DELETE SET NULL,
        ...
      )
      """,
      ...
    ]
  end
end
```

**Bootstrap-specific footguns:**
- **F4 (index naming):** `CREATE INDEX … ON parapet."parapet_incidents"` — qualify the *table* in the `ON` clause, do **not** prefix the index *name* (`parapet.idx_name` in `CREATE INDEX` is invalid; an index is implicitly created in its table's schema). All the existing partial indexes (`WHERE state = 'open'`, etc.) carry over verbatim except for the `ON` target.
- **F5 (REFERENCES):** every `REFERENCES parapet_incidents(id)` / `REFERENCES parapet_timeline_entries(id)` must become `REFERENCES parapet."parapet_…"(id)`, else the FK points at a (nonexistent) `public` parent and `CREATE TABLE` fails.
- **F6 (`schema_migrations`):** the migration backfill test creates `schema_migrations` in the concurrency DB. Ecto's migration source table is itself prefixable (`migration_source`/`--prefix`). Decide: does `schema_migrations` move into `parapet` too? For the *test* DB it can stay in `public` (it's infra, not a spine table) — but the Track B migration (§6) and the demo app's real `mix ecto.migrate` must be consistent. Recommend: **keep `schema_migrations` in `public`** (Ecto default) and only move the 6 spine tables; document this explicitly so adopters running `ecto.migrate --prefix parapet` don't get a second migrations table.

### 3.3 Test DB setup / `mix ecto.create` / dev DB

- **Concurrency suite:** there is **no `mix ecto.create`/migrate** for the main suite — `test_helper.exs` does `storage_up` + manual DDL. So the only change is the `CREATE SCHEMA IF NOT EXISTS` added to `bootstrap!/0`. Good — minimal blast radius.
- **Demo app (`examples/demo_app`):** uses real `mix ecto.create && mix ecto.migrate`. `mix ecto.create` creates the database with only the `public` schema. **`mix ecto.migrate` will NOT auto-create a `parapet` schema** unless a migration does `execute "CREATE SCHEMA IF NOT EXISTS parapet"` (or the migration uses `prefix:` and you run `mix ecto.migrate --prefix parapet`, which *does* create the schema). The generator dimension must emit a migration whose first step creates the schema, OR the demo CI step must run `mix ecto.migrate --prefix parapet`. **Constraint for the generator dimension: the create-schema step must be self-contained in the default-on migration** (adopters won't pass `--prefix`).

---

## 4. Propagation tests + runtime-`prefix:`-ban guard

### 4.1 `to_sql` propagation assertions (cheap, per-leg)

`Ecto.Adapters.SQL.to_sql/3` renders the schema-qualified table name into the SQL string, so we can assert the *compiled* prefix appears (or is absent) without touching the DB. This module runs in **every** matrix leg, so it validates whichever prefix that leg compiled.

```elixir
defmodule Parapet.SchemaPrefixPropagationTest do
  use ExUnit.Case, async: true
  import Ecto.Query
  alias Parapet.TestSupport.ConcurrencyRepo
  alias Parapet.Spine.{Incident, ActionClaim, TimelineEntry}

  # The prefix this build compiled with. Tests branch on it so the SAME module
  # asserts the correct shape under both matrix legs.
  @prefix (case Application.compile_env(:parapet, :schema_prefix, "parapet") do
             p when p in [nil, "", "public"] -> nil
             p -> p
           end)

  defp sql(query), do: Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query) |> elem(0)

  defp assert_prefixed(sql, table) do
    if @prefix do
      assert sql =~ ~s("#{@prefix}"."#{table}"),
             "expected #{table} qualified with #{@prefix} in: #{sql}"
    else
      assert sql =~ ~s("#{table}")
      refute sql =~ ~s("parapet"."#{table}"), "leaked parapet prefix in: #{sql}"
    end
  end

  test "select emits configured prefix" do
    assert_prefixed(sql(from(i in Incident)), "parapet_incidents")
  end

  test "join across two spine schemas carries prefix on both sides" do
    q = from(t in TimelineEntry, join: i in Incident, on: t.incident_id == i.id)
    s = sql(q)
    assert_prefixed(s, "parapet_timeline_entries")
    assert_prefixed(s, "parapet_incidents")
  end

  test "insert_all carries prefix" do
    # to_sql supports :insert_all queries; assert the INTO target is qualified.
    {s, _} =
      Ecto.Adapters.SQL.to_sql(
        :all,
        ConcurrencyRepo,
        from(i in Incident, select: %{id: i.id})
      )
    assert_prefixed(s, "parapet_incidents")
  end

  test "schema struct meta exposes the prefix" do
    meta = Ecto.get_meta(%Incident{}, :prefix)
    assert meta == @prefix
  end
end
```

**Notes / caveats:**
- `to_sql` for `:insert_all`/`:update_all`/`:delete_all` is supported; for plain struct `insert`/`update` you cannot `to_sql` directly — assert via `Ecto.get_meta(struct, :prefix)` instead (shown above), which is the authoritative source Ecto uses to qualify single-row ops. **(MEDIUM confidence on exact `to_sql` arity coverage across Ecto 3.13; verify which operation kinds `to_sql/3` accepts in this version — `:all`, `:update_all`, `:delete_all` are guaranteed.)**
- **Multi:** assert prefix on each operation's struct/query meta the same way; a `Multi` is just a list of ops. A representative `Multi.insert` + `Multi.update` whose changesets you inspect via `changeset.data |> Ecto.get_meta(:prefix)` is sufficient.
- **F7 (negative assertion under prefix):** under the `parapet` leg, also `refute` that any query emits a *bare* `"parapet_incidents"` without the schema qualifier — catches a schema that lost its `@schema_prefix`.

### 4.2 Runtime-`prefix:`-ban guard (static, no DB)

The requirement bans runtime `prefix:`. Because Ecto's precedence is "from/join prefixes, schema prefixes, **the `:prefix` option**, connection prefixes" ([Ecto multi-tenancy guide](https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html)), a stray runtime `prefix:` would *override* nothing above schema prefix for queries but **would override schema prefix for `insert`/`update`** (precedence "the `:prefix` option, changeset prefixes, schema prefixes, …"). So a runtime `prefix:` on a write is a real correctness hazard. Guard it statically:

```elixir
defmodule Parapet.RuntimePrefixBanTest do
  use ExUnit.Case, async: true

  @lib_glob "lib/**/*.ex"
  # Match a `prefix:` keyword passed to Repo/Multi/insert_all/query calls.
  # Allow @schema_prefix (module attr) and `:prefix` in get_meta/strings.
  @forbidden ~r/\bprefix:\s/

  test "no source file threads a runtime prefix: option" do
    offenders =
      @lib_glob
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _} ->
          Regex.match?(@forbidden, line) and
            not String.contains?(line, "@schema_prefix") and
            not String.contains?(line, "# allow-prefix")  # explicit escape hatch
        end)
        |> Enum.map(fn {line, n} -> "#{path}:#{n}: #{String.trim(line)}" end)
      end)

    assert offenders == [],
           "runtime prefix: is banned in v1.7. Offenders:\n" <> Enum.join(offenders, "\n")
  end
end
```

**Caveats:**
- **F8 (regex false positives):** `prefix:` appears in legitimate non-query contexts (logger metadata, struct fields). The `# allow-prefix` escape hatch + `@schema_prefix` exclusion handle that; review each exclusion in code review. An AST-walk (via `Code.string_to_quoted/1` + traversal looking for `prefix:` inside calls to `Repo`/`Ecto.Multi`/`insert_all`) is more precise but heavier — start with the grep test; upgrade to AST only if false positives bite.
- This guard runs in any leg (no DB), so put it in the fast `async: true` set.

---

## 5. Contract-frozen regression gates (CONTRACT-SAFETY)

The v1.7 contracts are FROZEN. Concretely, prove no movement with the **existing** gates, augmented:

| Gate | What it proves | Already exists? | v1.7 action |
|---|---|---|---|
| `mix verify.public_api` (CI `lint`) | No public module/function/struct-key/callback added, removed, or re-tiered; `priv/parapet/public_api_stable.json` byte-stable | **Yes** | Must stay green with **zero `--write`**. `@schema_prefix` is a module attribute, not an export, so it won't appear in the manifest — confirm by running locally that the diff is empty after adding prefixes. |
| `test/telemetry_contract_test.exs` | The 6 AsyncDelivery + 8 RecoveryAction + ~21 documented families unchanged | **Yes** | Schema prefix touches storage, not telemetry event names. Assert green unchanged. **F9:** if any `[:parapet, :ecto, :query]` passthrough metadata includes a table/source name, confirm the prefix change doesn't alter emitted measurements/metadata keys (it shouldn't — Ecto's telemetry uses `:source`, which is the bare table name, not the prefixed one — **MEDIUM confidence, verify**). |
| Compile-out-clean | `mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors` (CI `lint`) | **Yes** | Adding `@schema_prefix unquote(compile_env(...))` must not introduce unused-attr/`compile_env` warnings. Run both legs' compile under `--warnings-as-errors`. |
| Dialyzer | No new type errors from prefix plumbing | **Yes** | Keep green. |
| Demo smoke | App boots, migrates **into `parapet`**, `mix test --only smoke` passes | **Partially** (smoke exists; migrate-into-parapet is new) | Add: after `mix ecto.migrate`, assert `parapet.parapet_incidents` exists (e.g. a `--only smoke` test that `SELECT … information_schema.tables WHERE table_schema = 'parapet'` returns the 6 tables), then exercise one evidence write/read. This is the **closure-grade proof** that default-on schema isolation works end-to-end through the real migration path, not just the hand-bootstrapped suite. |

**Demo smoke assertion sketch (add to demo app's smoke-tagged test):**

```elixir
@tag :smoke
test "spine tables live in the parapet schema after migrate" do
  %{rows: rows} =
    DemoApp.Repo.query!(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'parapet' ORDER BY 1"
    )
  names = List.flatten(rows)
  for t <- ~w(parapet_incidents parapet_action_items parapet_timeline_entries
              parapet_tool_audits parapet_system_events parapet_action_claims) do
    assert t in names, "#{t} not found in parapet schema; got #{inspect(names)}"
  end

  # And a real round-trip through the prefixed schema:
  {:ok, inc} = Parapet.Evidence.open_incident(%{title: "smoke"})  # whatever the public API is
  assert Ecto.get_meta(inc, :prefix) == "parapet"
end
```

**F10 (manifest false-negative):** `verify.public_api` is a *manual* snapshot — it can't detect a *behavioral* change that keeps the same signatures. The prefix change is exactly that kind (same functions, different SQL). So the public-API gate proves "shape frozen" but the **demo smoke + propagation tests are what prove "behavior correct."** Don't over-trust the manifest.

---

## 6. Track B round-trip upgrade test design

**Goal:** prove the `SET SCHEMA` migration that moves an *existing* `public`-resident install into `parapet`: create tables in `public`, run the Track B migration, assert resolution under `parapet` + FKs intact, then `down` restores to `public`.

**Where it lives:** `test/parapet/repo/migrations/move_spine_to_parapet_schema_test.exs`, modeled **directly on `add_lease_until_backfill_test.exs`** (which already solves every hard problem here).

**Why it must escape the Sandbox (verbatim from the existing pattern):**
1. **DDL + `Ecto.Migrator` need ≥2 simultaneous connections** (lock `schema_migrations` + execute DDL) — the ownership-based Sandbox pool cannot provide them across processes. Use a dedicated `DBConnection.ConnectionPool` repo (`MigrationTestRepo` pattern).
2. **`ALTER TABLE … SET SCHEMA` is DDL** and must not run inside the Sandbox's wrapping transaction; tag `@tag :unboxed` and use a bare `Postgrex` connection for the pre/post setup, exactly like the lease test.
3. **Avoid polluting the shared `parapet_concurrency_test` DB:** the existing test's `on_exit` restores canonical bootstrap state. For the `SET SCHEMA` test this is **much riskier** — moving the 6 tables out of `public` and back affects every subsequent module. **Recommendation: use a dedicated throwaway database** (e.g. `parapet_migration_roundtrip_test`) created/dropped within the test's `setup_all`, NOT the shared concurrency DB. This fully isolates the destructive schema move. Create it via `Ecto.Adapters.Postgres.storage_up/1` with a distinct `database:` name; `storage_down/1` in `on_exit`.

**Test skeleton:**

```elixir
defmodule Parapet.Repo.Migrations.MoveSpineToParapetSchemaTest do
  use ExUnit.Case, async: false
  alias Parapet.TestSupport.ConcurrencyRepo

  @migration_version 20_270_101_000_000
  @migration_module Parapet.Repo.Migrations.MoveSpineToParapetSchema

  Code.require_file(
    "../../../../priv/repo/migrations/20270101000000_move_spine_to_parapet_schema.exs",
    __DIR__
  )

  defmodule RoundtripRepo do
    use Ecto.Repo, otp_app: :parapet, adapter: Ecto.Adapters.Postgres
  end

  setup_all do
    base = ConcurrencyRepo.database_config()
    cfg =
      base
      |> Keyword.put(:database, "parapet_migration_roundtrip_test")
      |> Keyword.put(:pool, DBConnection.ConnectionPool)
      |> Keyword.put(:pool_size, 5)
      |> Keyword.delete(:ownership_timeout)

    _ = Ecto.Adapters.Postgres.storage_up(cfg)   # dedicated, throwaway DB
    {:ok, _} = RoundtripRepo.start_link(cfg)

    {:ok, conn} = Postgrex.start_link(Keyword.take(cfg, [:hostname, :port, :database, :username, :password]))

    # 1. Stand up the spine in PUBLIC (pre-v1.7 install) via the canonical DDL.
    #    Reuse ConcurrencyBootstrap-style DDL but FORCED unprefixed.
    create_public_spine!(conn)

    # schema_migrations for the migrator
    RoundtripRepo.query!(
      "CREATE TABLE IF NOT EXISTS schema_migrations (version bigint PRIMARY KEY, inserted_at timestamp(0) without time zone)", [])

    on_exit(fn ->
      GenServer.stop(conn)
      Ecto.Adapters.Postgres.storage_down(cfg)   # nuke the throwaway DB
    end)

    {:ok, conn: conn}
  end

  @tag :unboxed
  test "SET SCHEMA moves spine to parapet, preserves FKs, and down restores", %{conn: conn} do
    # seed a parent+child in public to prove FK survival
    {inc_id, item_id} = seed_incident_with_item!(conn)

    # UP: move the 6 tables into parapet
    assert Ecto.Migrator.up(RoundtripRepo, @migration_version, @migration_module, log: false)
           in [:ok, :already_up]

    # tables now resolve under parapet, gone from public
    assert table_in_schema?(conn, "parapet", "parapet_incidents")
    refute table_in_schema?(conn, "public", "parapet_incidents")

    # FK intact: deleting the incident cascades to the action_item (ON DELETE CASCADE/SET NULL)
    assert fk_present?(conn, "parapet", "parapet_action_items", "incident_id")
    # row data survived the move
    assert row_exists?(conn, ~s("parapet"."parapet_incidents"), inc_id)

    # DOWN: restore to public
    assert Ecto.Migrator.down(RoundtripRepo, @migration_version, @migration_module, log: false) == :ok
    assert table_in_schema?(conn, "public", "parapet_incidents")
    refute table_in_schema?(conn, "parapet", "parapet_incidents")
    assert fk_present?(conn, "public", "parapet_action_items", "incident_id")
  end
end
```

**Track-B-specific footguns:**
- **F11 (`ALTER TABLE … SET SCHEMA` and FKs):** Postgres preserves FK constraints across `SET SCHEMA` automatically — the constraint follows the table. But **the order matters if you also rename the schema-qualified references in a partial index predicate**; the 6 spine tables have several partial indexes (e.g. `parapet_action_claims_lease_until_claimed_index WHERE status='claimed'`). `SET SCHEMA` moves indexes with their table, so no manual index work — **assert the partial indexes still exist post-move** to be safe.
- **F12 (`SET SCHEMA` is per-table):** the migration must `ALTER TABLE public.parapet_incidents SET SCHEMA parapet` for **each** of the 6 tables, **parent-before-child is NOT required** for `SET SCHEMA` (unlike DROP), but do create the schema first: `execute "CREATE SCHEMA IF NOT EXISTS parapet"`. The `down/0` must `SET SCHEMA public` for each and optionally `DROP SCHEMA parapet` (only if empty — guard with `DROP SCHEMA IF EXISTS parapet RESTRICT`, never `CASCADE`).
- **F13 (`schema_migrations` location):** keep it in `public` (see F6). The Track B migration must NOT move `schema_migrations`.
- **F14 (don't reuse the shared DB):** if you skip the dedicated-DB recommendation and run against `parapet_concurrency_test`, a mid-test failure leaves the spine half-moved and **every later test module breaks**. The existing lease test gets away with column-level mutation + careful `on_exit`; a whole-schema move is too destructive to risk. Use the throwaway DB.

---

## 7. Prior-art lessons (cited)

1. **Oban is the gold-standard model for "prefix as a first-class, default-`public` option."** `use Oban.Testing, repo: MyApp.Repo, prefix: "business"` and `Oban.Migrations.up(prefix: "private")` show the canonical shape: the migration *creates the schema and all objects within it*, and the test helper takes the prefix explicitly. Lesson for Parapet: the generator-emitted migration should `CREATE SCHEMA` then create tables in it, and any test helper that needs the prefix should read the *compiled* constant rather than take a runtime arg (since v1.7 bans runtime prefix). ([Oban.Testing](https://oban.hexdocs.pm/Oban.Testing.html), [Oban.Migration](https://hexdocs.pm/oban/2.16.3/Oban.Migration.html))

2. **Ecto's own multi-tenancy guide: `@schema_prefix` + `CREATE SCHEMA` are the two halves.** `@schema_prefix "main"` on the schema module and `CREATE SCHEMA connection_prefix` before migrating. Prefix info rides on every struct via `Ecto.get_meta(sample, :prefix)` — which is exactly the cheap assertion seam for §4. ([Ecto multi-tenancy with query prefixes](https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html))

3. **Prefix precedence is a correctness trap.** Ecto resolves query prefixes as "from/join, schema, `:prefix` option, connection"; writes as "`:prefix` option, changeset, schema, connection." A runtime `:prefix` **outranks `@schema_prefix` on writes** — which is precisely why TEST-02 bans it and why the §4.2 guard targets writes especially. ([Ecto multi-tenancy guide](https://ecto.hexdocs.pm/multi-tenancy-with-query-prefixes.html))

4. **`compile_env` cannot be flipped at runtime — universal consensus.** ElixirForum + Phoenix's own migration to `Application.compile_env` for endpoint config confirm: the value is frozen at compile time, `recompile/1` won't reload config, and Elixir *raises* on compile-vs-runtime mismatch. The community's recommended escape for "test both values" is **separate compiled runs / `MIX_ENV`-style switches**, which is exactly the CI matrix axis chosen here. ([ElixirForum: change compile_env in ExUnit](https://elixirforum.com/t/change-config-compile-env-variables-during-exunit-test/53526), [Phoenix PR #4801 — compile_env for endpoint](https://github.com/phoenixframework/phoenix/pull/4801))

5. **Sandbox truncate-vs-transaction discussions** confirm `TRUNCATE` works inside the sandbox's wrapping transaction (it's transactional in Postgres), so qualifying the names in `reset!/0` is the *only* change needed there. ([Ecto.Adapters.SQL.Sandbox](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html), [commanded#226](https://github.com/commanded/commanded/issues/226))

6. **Migrating data with raw connections, not the Sandbox, is the established Parapet pattern** — the existing `add_lease_until_backfill_test.exs` already encodes "dedicated `DBConnection.ConnectionPool` repo + bare Postgrex for out-of-transaction DDL + idempotent `on_exit`." Track B should clone it (plus a throwaway DB). ([livinginthepast: migrating data with Ecto](https://www.livinginthepast.org/blog/migrating-data-with-ecto/))

---

## 8. Constraints imposed on the generator / upgrade dimensions

The test matrix and gates above impose these hard requirements on the other v1.7 dimensions:

1. **Config seam name is fixed:** `Application.compile_env(:parapet, :schema_prefix, "parapet")` with normalization `"" | "public" | nil ⇒ unprefixed`. Generator, spine schemas, and `ConcurrencyBootstrap` must all read this exact key and apply the **same** normalization (one shared pure helper + a unit test asserting `config.exs`'s copy agrees).
2. **CI needs `PARAPET_SCHEMA_PREFIX` to drive `config/config.exs`.** A `config/config.exs` must be added to the lib root (NOT shipped in the Hex package). Matrix values: `parapet` (default-on) and `public`/`""` (unprefixed).
3. **The default-on migration must self-create the schema** (`execute "CREATE SCHEMA IF NOT EXISTS parapet"` as its first step) so adopters' plain `mix ecto.migrate` works without `--prefix`. The demo CI job proves this.
4. **`schema_migrations` stays in `public`** — generator/Track B must not move it; document for adopters.
5. **No runtime `prefix:` anywhere in `lib/`** — the generator's emitted code and any internal query helpers must rely solely on `@schema_prefix`. The §4.2 guard will fail the build otherwise.
6. **Track B `SET SCHEMA` migration** must be per-table, create-schema-first, `down`-restorable, and leave FKs/partial-indexes intact (Postgres handles FK/index follow automatically, but the migration must not touch `schema_migrations`).
7. **`_build` cache must be prefix-namespaced in CI** or the matrix silently tests one prefix twice (F1) — this is a release-gate-integrity requirement, not a nicety.

---

## Summary (6–8 lines)

The library has **no `config/` dir today** and the main suite uses hand-written DDL via `ConcurrencyBootstrap` (no migrations), so `compile_env(:parapet, :schema_prefix, "parapet")` currently always resolves to the default — we must add a `config/config.exs` (env-driven, unshipped) to make dual-prefix testing possible at all. **TEST-02 cannot be met at runtime**: `@schema_prefix` is a compile-time constant, so the only honest proof is a **CI matrix axis (`schema_prefix: ['parapet','public']`) that recompiles and reruns the full suite per value**, with the `_build` cache key namespaced by prefix + `mix compile --force` to avoid a silent false-green (the #1 footgun). Riding every leg: cheap **`to_sql`/`Ecto.get_meta` propagation assertions** (validate the leg's compiled prefix on selects/joins/insert_all/Multi) and a **static runtime-`prefix:`-ban guard** (writes especially, since a runtime `:prefix` outranks `@schema_prefix`). `ConcurrencyBootstrap` changes are surgical: add `CREATE SCHEMA IF NOT EXISTS`, qualify all `CREATE TABLE`/`REFERENCES`/`ON`/`TRUNCATE` to `"parapet"."table"` (qualify index *targets*, not index *names*). Frozen-contract proof = existing `mix verify.public_api` + `telemetry_contract_test.exs` + `--warnings-as-errors`, plus a new **demo-smoke assertion** that `mix ecto.migrate` lands the 6 tables in `parapet` and an evidence round-trip carries `prefix == "parapet"`. The **Track B `SET SCHEMA` round-trip test** clones the existing `add_lease_until_backfill_test.exs` pattern (dedicated `DBConnection.ConnectionPool` repo + bare Postgrex + `@tag :unboxed`) but must run against a **throwaway DB**, not the shared concurrency DB, because a half-completed schema move would poison every later module.
