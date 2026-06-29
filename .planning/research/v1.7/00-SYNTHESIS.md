# v1.7 Schema Isolation — Synthesis & Decisive Recommendations

> One coherent recommendation set distilled from five parallel research dimensions
> (`01`–`05` in this dir). Every fork is decided; rationale and prior-art are in the
> source docs. This is the spec the roadmap/phases execute against. **Reading order
> for implementers:** this doc → the dimension doc for the phase you're in.

**Verdict up front:** the locked design is *correct and confirmed* on every axis. This is
"easy-mode" schema isolation — **one fixed, library-owned schema**, not per-tenant sprawl —
so the Apartment/django-tenants/Triplex horror stories don't apply. The only true precedent is
**Oban**, and Parapet matches its shapes *and beats it* by shipping the one thing Oban lacks:
a documented, tested, reversible schema-**move** path. Fully on-brand with Parapet DNA
(host-owned generated migrations, library owns runtime, frozen public/telemetry contracts).

---

## 1. Locked decisions (naming, semantics, posture)

| Surface | Decision | Why (one line) |
|---|---|---|
| Config key | `config :parapet, :schema_prefix, "parapet"` | Matches Ecto's own `@schema_prefix`; **never bare `:prefix`** — collides with frozen telemetry "event prefix" (`docs/stability.md`: "No configurable `:event_prefix`"). |
| Default | `"parapet"` for new installs; existing adopters **opt-in only** | Additive, not breaking — upgraders never auto-migrated. |
| Opt-out | `nil` canonical; `""` and `"public"` are aliases → **identical unprefixed SQL** | `nil` = "no `@schema_prefix`" = exact Ecto semantics; `"public"` is a kindness alias. |
| Mechanism | Compile-time `@schema_prefix` via a shared `use Parapet.Spine.Schema` macro; **runtime `prefix:` banned** | Only mechanism where reads & writes agree by construction; runtime `prefix:` is a read/write precedence split-brain. |
| No `search_path` | Query-prefix only | Keeps `public`-resident extensions (`citext`/`uuid-ossp`/`pg_trgm`) resolving; Rails Apartment abandoned `search_path` over leak/pooling bugs. |
| Generator flags | `--schema parapet` · `--no-create-schema` | `--no-create-schema` is Oban-verbatim least-privilege parlance. |
| Move task | `mix parapet.gen.schema.move` (dotted, under `gen`) | It *emits a host-owned reversible migration*; not `gen.schema_move`, not `parapet.schema.move`. |
| Upgrade doc | `docs/upgrade-1.x.md` | Sits beside `docs/migration-v1.md`; "upgrade" avoids overloading "migration". |
| CHANGELOG | `feat` + **"No action required for existing installs"** banner | Default inversion is for *new installs only*; never say "breaking". |

---

## 2. The mechanism (PREFIX-CORE + PREFIX-PROP)

**`Parapet.Spine.Schema` base macro** — the single place the prefix is ever named:

```elixir
defmodule Parapet.Spine.Schema do
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:id, :binary_id, autogenerate: true}   # dedup: all 6 already declare this
      @foreign_key_type :binary_id
      @schema_prefix Parapet.Spine.Schema.__prefix__()
    end
  end

  def __prefix__ do
    case Application.compile_env(:parapet, :schema_prefix, "parapet") do
      p when p in [nil, "", "public"] -> nil
      other when is_binary(other) -> other
      other when is_atom(other) -> Atom.to_string(other)
    end
  end
end
```

All 6 spine schemas switch `use Ecto.Schema` → `use Parapet.Spine.Schema` (a net *simplification* —
removes the repeated `@primary_key`/`@foreign_key_type`).

**Propagation is proven with ZERO call-site edits** (dimension 01): all reads/writes go through
schema *modules*/structs, so `@schema_prefix` rides everything — `Repo.all/get/insert/update/delete`,
`insert_all(ActionClaim, …)` (claim_service), every `evidence.ex`/`alert_processor.ex` `Ecto.Multi`
step, and both spine↔spine joins (`mcp/server.ex`, `circuit_breaker.ex`). All six carry the *same*
prefix, so no join ever spans `parapet`+`public`. The Oban escalation-job insert in the Multi correctly
keeps the *host's* Oban prefix (not a spine schema).

**Guards (must stay green forever):** a static ban test over `lib/` fails on (a) any `prefix:` threaded
into a `Repo`/`repo` call, (b) `insert_all`/`update_all`/`delete_all` with a **string-literal table name**
(drops the prefix), (c) `search_path`, (d) raw SQL naming a `parapet_` table. Plus a positive
`__schema__(:prefix)` assertion across all 6. **Zero offenders today** — green from day one.

**Normalization is single-sourced:** the `nil|""|"public" ⇒ nil` rule lives in `__prefix__/0` AND
(necessarily duplicated, since it runs pre-compile) in `config/config.exs`; a unit test asserts the two
copies agree on `["parapet","","public",nil,"custom"]`.

---

## 3. Generators & migrations (GEN-MIGRATIONS)

- **Dedicated, first-ordered schema migration** `*_create_parapet_schema.exs` — reversible
  `execute "CREATE SCHEMA IF NOT EXISTS parapet"` / `execute "DROP SCHEMA IF EXISTS parapet"` (no `CASCADE`).
  Standalone so `--no-create-schema` is a clean omit-one-file decision.
- **Prefix is a baked literal** interpolated at gen time (never a runtime config read in a migration).
  Stamp `prefix:` on every `create table`, **each `references/2` (own prefix — Ecto won't inherit it)**,
  and every index. FK *constraint names* stay `parapet_<t>_..._fkey` (computed from the unprefixed table
  name — assert they don't drift).
- **Config write via Igniter `configure_new/5`** for `:schema_prefix` (never clobber an adopter's value;
  flag-vs-config conflict warns, doesn't crash); `configure/6` only for `:repo`.
- **One shared resolver** (`flag > existing config > default`) called by `gen.spine`, `gen.archive_indexes`,
  and forwarded through `install` — the load-bearing consistency guarantee.
- **`--no-create-schema`** omits the schema migration, keeps tables fully prefixed, and prints the exact
  `CREATE SCHEMA parapet;` + `GRANT USAGE, CREATE ON SCHEMA parapet TO <user>;` the DBA must run.
- **Generator tests:** extend the existing AST-normalized substring asserts + a `prefix:` **count-guard**
  (catches a future index that forgets the prefix); **one small golden** for the tiny schema migration only
  (never golden the full spine migration — trains blind-accept); 3 hatch/config branch tests, path-gated to
  the installer-golden lane.

---

## 4. Upgrade path (UPGRADE-PATH + DOCS)

**Track B `SET SCHEMA` is safe to recommend** — catalog-only (no heap rewrite), sub-second
`ACCESS EXCLUSIVE` lock regardless of table size; indexes/constraints/partial-indexes/FKs follow
automatically; **all-UUID PKs ⇒ zero sequences to orphan** (the django-tenants `setval()` footgun is
non-applicable — say so in docs to reassure the bitten-elsewhere reader). FKs stay valid because they bind
by **OID**, not schema text, and all 6 move in **one transaction** (all-or-nothing keeps the app's uniform
`@schema_prefix` correct).

**Generated move migration** (`mix parapet.gen.schema.move`):

```elixir
def up do
  execute "SET LOCAL lock_timeout = '5s'"          # the ONE real risk is lock QUEUEING, not hold time
  execute "CREATE SCHEMA IF NOT EXISTS parapet"    # omitted under --no-create-schema
  for t <- @tables, do: execute "ALTER TABLE public.#{t} SET SCHEMA parapet"
end
def down do                                        # reversible; intentionally does NOT DROP SCHEMA
  execute "SET LOCAL lock_timeout = '5s'"
  for t <- @tables, do: execute "ALTER TABLE parapet.#{t} SET SCHEMA public"
end
```

Keep it in ONE transaction (do **not** `@disable_ddl_transaction`). The task runs **pre-flight catalog
detections**: **abort** if an expected `public.parapet_<t>` is missing (renamed tables); **warn** (don't
abort) on inbound app FKs / views into spine tables; refuse to emit a second move migration if one exists.

**The one sharp edge — the compile-time recompile.** Flipping `:schema_prefix` requires
`mix deps.compile parapet --force` (it's a *dependency*; `mix compile` alone won't re-bake it). Safe orders:
- **Track A (stay on public):** `config :schema_prefix, nil` → `mix deps.compile parapet --force`. No DB step.
- **Track B (move):** **`migrate → config → deps.compile --force → restart`** — migrate *first* so the app
  keeps querying `public` until the recompiled release cuts over (recompiling first = querying a not-yet-moved
  `parapet.*` = self-inflicted outage). Releases: migrate at deploy-time, config+recompile at build-time.

**`docs/upgrade-1.x.md`** leads with "your data does not move unless you choose"; copy-paste Track A/B
(every config block immediately followed by the `--force` line), least-privilege GRANTs, recompile-order,
rollback (incl. half-migrated recovery — "no data is ever lost; `SET SCHEMA` never touches rows"), FAQ.
Plus a schema subsection in `docs/deployment.md`, a short note + link in `README.md`, and a routing pointer
from `docs/migration-v1.md` (the audited #1 gap).

---

## 5. Doctor drift check (DOCTOR) — new, cross-dimension

Add a `mix parapet.doctor` check comparing the **runtime** `:schema_prefix` config against the
**compiled** `@schema_prefix` baked into the spine schemas. On mismatch → fail (CI-grade `--ci`) with
"run `mix deps.compile parapet --force` and restart." Also check the `parapet` schema exists. This converts
the recompile footgun and the least-privilege "schema missing" error into a preflight failure — squarely
on-brand with Parapet's diagnostics-first DNA. Requires `Parapet.Spine.Schema` to expose the compiled value.

---

## 6. Testing & contract safety (TEST-INFRA + CONTRACT-SAFETY)

**Two prerequisites the original requirements assumed away (dimension 04):**
1. **The library has NO `config/` dir** — so `compile_env` always resolves to the default today. Add an
   **env-driven `config/config.exs`** reading `PARAPET_SCHEMA_PREFIX` (default-on `"parapet"`; `""`/`"public"`
   ⇒ unprefixed). It is **NOT** added to the Hex `package.files` (adopters supply their own config).
2. **The main suite uses hand-written DDL** (`ConcurrencyBootstrap`), not migrations. Hand-qualify it:
   add `CREATE SCHEMA IF NOT EXISTS`, qualify every `CREATE TABLE`/`REFERENCES`/`ON`/`TRUNCATE` to
   `"parapet"."table"` — **qualify index *targets*, not index *names*** (an index lives in its table's schema).
   Keep `schema_migrations` in `public`.

**TEST-02 cannot be met at runtime** — `@schema_prefix` is a compile-time constant; the only honest proof is
a **CI matrix axis `schema_prefix: ['parapet','public']` that recompiles and reruns the full suite per value**.
Critical footgun: the `_build` cache is keyed by `mix.lock` only — **namespace the cache key with the prefix**
(+ `mix compile --force`) or the `public` leg silently reuses the `parapet` build and false-greens.

**Riding every leg (cheap):** `to_sql`/`Ecto.get_meta(struct, :prefix)` assertions proving the *compiled*
prefix appears on selects/joins/`insert_all`/Multi (with a negative "no bare `parapet_incidents`" assertion
under the prefixed leg) + the static runtime-`prefix:`-ban guard.

**Track B round-trip test:** clone `add_lease_until_backfill_test.exs` (dedicated `DBConnection.ConnectionPool`
repo + bare Postgrex + `@tag :unboxed`) but run against a **throwaway DB** (`storage_up`/`storage_down` in
`setup_all`) — a half-completed schema move would poison every later module. Assert: created in `public` → up
→ resolves under `parapet`, FK cascade + partial indexes intact → down → restored to `public`.

**Frozen-contract gates (done-criteria):** `mix verify.public_api` green with zero `--write` (the prefix is a
module attribute, not an export); `telemetry_contract_test.exs` green (confirm Ecto query telemetry `:source`
is the bare table name, unaffected); `--warnings-as-errors` + `--no-optional-deps` clean; **demo smoke** asserts
`mix ecto.migrate` lands all 6 tables in `parapet` (via `information_schema.tables`) and an evidence round-trip
carries `Ecto.get_meta(record, :prefix) == "parapet"`. The manifest proves "shape frozen"; the demo smoke +
propagation tests prove "behavior correct" — don't over-trust the manifest for a same-signature behavior change.

---

## 7. Phase shape (≈6, continuing from Phase 51)

Cross-dimension dependency: the **config seam + bootstrap qualification** must land with/before the prefix core
so the suite can even run under the prefix; the **CI dual-prefix matrix** validates it; generators, upgrade
path, demo+docs, and release hardening follow.

1. **Prefix core + test seam** — `Parapet.Spine.Schema` macro, all 6 schemas, `schema_prefix/0` helper,
   shared normalization + agreement test, `config/config.exs` seam, `ConcurrencyBootstrap` qualification,
   library migrations prefixed. (PREFIX-CORE, TEST-INFRA core)
2. **Propagation proof + guards + CI matrix** — `to_sql`/`get_meta` tests, join/Multi/insert_all regression,
   runtime-prefix ban guard, dual-prefix CI axis (prefix-namespaced cache + `--force`). (PREFIX-PROP, TEST-03)
3. **Generators + fixtures** — schema migration, prefix-stamped DDL, `configure_new`, `--schema`/
   `--no-create-schema`, shared resolver, generator tests. (GEN-MIGRATIONS)
4. **Upgrade path + doctor** — `mix parapet.gen.schema.move` (lock_timeout, pre-flight detections), Track A,
   round-trip test (throwaway DB), `parapet.doctor` drift+existence check. (UPGRADE-PATH, DOCTOR)
5. **Demo app + docs** — demo end-to-end into `parapet`, `docs/upgrade-1.x.md`, deployment/README/migration-v1
   deltas. (DOCS, demo smoke)
6. **Contract & release hardening** — `verify.public_api` + telemetry + compile-out gates, CHANGELOG `feat`
   "no action required" banner, semver/release note. (CONTRACT-SAFETY)

---

## 8. Risk register (decisive mitigations)

| Risk | Mitigation | Owner phase |
|---|---|---|
| Runtime `prefix:` split-brain | Compile-time `@schema_prefix` only + static ban guard (raises if introduced) | 1–2 |
| `compile_env` recompile surprise | Document `deps.compile --force` everywhere; `parapet.doctor` drift check | 4–5 |
| CI false-green (cache reuse) | `_build` cache key namespaced by prefix + `mix compile --force` | 2 |
| Lock queueing on `SET SCHEMA` | `SET LOCAL lock_timeout = '5s'` in generated migration; off-peak note | 4 |
| Renamed tables / inbound FKs break move | Pre-flight catalog detection (abort / warn) | 4 |
| Raw SQL bypasses prefix | Hand-qualify bootstrap; ban-guard flags raw `parapet_` SQL; string-table `insert_all` banned | 1–2 |
| `string-table` `insert_all` regression | Ban guard (zero offenders today) | 2 |
| Frozen contract drift | `verify.public_api` + telemetry test + demo behavior smoke in done-criteria | 6 |
| `config/` shipped to adopters | Confirm `package.files` excludes `config/` | 1 |

---

## 9. Sources
Dimension docs `01`–`05` in this directory carry full citations (Ecto multi-tenancy guide, Oban.Migration,
Triplex, Ash, Rails Apartment, django-tenants, Postgres ALTER TABLE / lock-queue lore, ElixirForum on
`compile_env` immutability, Parapet `prompts/` engineering DNA + `docs/stability.md`).
