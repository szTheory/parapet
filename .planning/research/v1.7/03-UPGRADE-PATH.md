# v1.7 — Upgrade Path & Adopter Migration UX (UPGRADE-PATH + DOCS)

**Hat:** DBA / zero-downtime migrations + adopter-upgrade UX
**Adopter JTBD:** "I run Parapet's 6 spine tables in `public`. v1.7 changes the *default* to a `parapet` schema. I want to upgrade my dependency without my incident/evidence data moving, breaking, or surprising me — and if I *do* want the cleaner `parapet` schema, I want a tested, reversible, copy-pasteable path that takes a sub-second lock."
**Confidence:** HIGH on Postgres/Ecto mechanics (primary-source verified), HIGH on recompile-order, MEDIUM-HIGH on docs structure (opinionated).

---

## 1. Summary recommendation (decisive)

1. **Ship the default inversion as a *no-op for existing adopters*.** The compile-time `@schema_prefix` defaults to `"parapet"` for *new* installs (generator writes `config :parapet, :schema_prefix, "parapet"` explicitly). Existing adopters who already have a config line keep whatever they have; adopters who have *no* config line are the only ones the default touches — and for them the doc's **first instruction** is to pin Track A (`schema_prefix, nil`) so nothing changes until they choose. The default change must never silently re-point an in-production app at an empty `parapet` schema.

2. **Track B (`SET SCHEMA`) is safe and is the recommended "I want the clean schema" path** because Parapet's data model makes the worst footguns inapplicable: all 6 tables move as one unit (FKs stay valid), all PKs are `binary_id`/UUID (no sequences to orphan), and `SET SCHEMA` is a **catalog-only metadata operation** — its `ACCESS EXCLUSIVE` lock is held for microseconds regardless of table size, unlike the `lease_until` backfill migration that scans/rewrites.

3. **Wrap Track B in a `lock_timeout`.** The only real production risk is *lock queueing*: `SET SCHEMA` itself is instant, but if a long-running query holds a conflicting lock, the migration waits behind it — and every new query then queues behind the migration. A short `SET lock_timeout` (e.g. `5s`) turns a potential stall into a clean, retryable failure. This is the single most important prior-art lesson (strong_migrations / pgroll / xata).

4. **Recompile order is `migrate → config → recompile` for Track B, and `config → recompile` (no migrate) for Track A.** Justified in §5. The compile-time `@schema_prefix` is the one genuine sharp edge; the docs must spell out the exact sequence and how to detect a stale compile.

5. **`mix parapet.gen.schema_move` generates the Track B migration** (not a runtime mover). It is idempotent, prints the recompile reminder, respects `create_schema: false`, and emits a fully reversible `up`/`down`. It must *detect and warn* about non-spine FKs pointing **into** parapet tables and renamed tables.

6. **One new doc, `docs/upgrade-1.x.md`,** owns the whole story (default-inversion explainer, Track A/B copy-paste, least-privilege, recompile, rollback, FAQ). `docs/deployment.md` gets a schema subsection; `README.md` gets a one-paragraph "schema isolation" note linking out. This closes the audited #1 gap (`migration-v1.md` never mentions schema).

---

## 2. `SET SCHEMA` safety analysis (locks / atomicity / FKs / edge objects)

### 2.1 Lock level & duration — **brief and acceptable for live SaaS**

`ALTER TABLE … SET SCHEMA` acquires **`ACCESS EXCLUSIVE`** (it is not in the documented set of lighter-lock forms like `SET STATISTICS` / `VALIDATE CONSTRAINT`, so it takes the default strongest lock). **However, it is a catalog-only operation** — it updates `pg_class.relnamespace` (and dependent objects' namespace), with **no heap rewrite and no table scan**. The lock is therefore held for **microseconds**, independent of row count.

This is categorically different from Parapet's existing `add_lease_until` migration (which holds `ACCESS EXCLUSIVE` across a full-table `UPDATE` + `SET NOT NULL` validation scan — see that migration's own adopter-warning moduledoc). For `SET SCHEMA`, **no maintenance window is required for typical adopter table sizes**; the only risk is lock *queueing* (§2.5), not lock *hold time*.

Verdict: **the brief `ACCESS EXCLUSIVE` is acceptable for a live SaaS**, provided the migration runs under a `lock_timeout` so it cannot queue indefinitely behind a long transaction.

### 2.2 Atomicity — **all 6 moves are one transaction**

Ecto wraps each migration in a transaction by default (Postgres has transactional DDL). Emitting all 6 `ALTER … SET SCHEMA` statements in a single `change/0` means **either all 6 tables move or none do** — there is no half-moved intermediate state visible to other sessions, and a failure (including a `lock_timeout` abort) rolls the whole thing back cleanly. **Do not** add `@disable_ddl_transaction true` here — atomicity is exactly what keeps the FK graph consistent (§2.4). (This is the opposite of the backfill case, where you'd *want* to disable the DDL transaction.)

### 2.3 What moves automatically

Per the PostgreSQL `ALTER TABLE` docs: *"Associated indexes, constraints, and sequences owned by table columns are moved as well."* So for each moved table, these follow automatically into `parapet`:

- **All indexes** — including the partial/conditional ones Parapet relies on:
  - `parapet_incidents` unique partial index `WHERE state = 'open'` (correlation_key dedup)
  - `parapet_incidents` queue/history cursor partial indexes (`WHERE state in (...)`, `WHERE state = 'resolved'`)
  - `parapet_action_claims` unique index `(incident_id, action_kind, action_key)` and the lease partial index `WHERE status = 'claimed'`
  - All move with their parent table; **partial-index predicates are unaffected** (they reference columns, not schema-qualified names).
- **All constraints** — PKs, NOT NULL, defaults, and **foreign keys** (FK definitions reference the *referenced table by OID*, not by a frozen schema string, so they follow correctly — see §2.4).
- **Column-owned sequences** — *not applicable to Parapet* (see §2.4 edge objects).

### 2.4 FK validity — **proven safe because all 6 move together**

Parapet's complete intra-spine FK graph (from the committed lib migrations + demo migrations):

| Child table | Column | → Referenced table | on_delete |
|---|---|---|---|
| `parapet_timeline_entries` | `incident_id` | `parapet_incidents` | delete_all |
| `parapet_tool_audits` | `timeline_entry_id` | `parapet_timeline_entries` | delete_all |
| `parapet_action_claims` | `incident_id` | `parapet_incidents` | delete_all |
| `parapet_action_items` | `incident_id` | `parapet_incidents` | nilify_all *(demo adds this; lib's `action_items` has no FK)* |
| `parapet_system_events` | — | *(standalone, no FK)* | — |

**Both ends of every FK are inside the 6-table set.** Postgres FK constraints bind the referenced relation by **OID**, not by a schema-qualified text reference — moving a table to a new schema does not change its OID, so existing FK constraints remain valid and enforced **without revalidation** regardless of which schema either end lives in. Moving all 6 in one transaction means there is never a window where a child sits in `parapet` while its parent sits in `public` (or vice-versa) *visible to other sessions* — and even transiently within the transaction the OID binding holds. **No FK is dropped, recreated, or re-validated; no `VALIDATE CONSTRAINT` scan occurs.** This is the core safety guarantee of the "move as a unit" decision.

> Contrast: if an adopter moved only *some* tables, FKs would *still* remain valid (OID binding is schema-agnostic), but Parapet's *application code* — which resolves every spine schema through the same `@schema_prefix` — would then be split-brained (querying `parapet.parapet_incidents` while `parapet_timeline_entries` is still in `public`). So "move as a unit" is required for **application correctness**, not for FK validity. The migration must therefore be all-or-nothing.

### 2.5 The real risk: lock **queueing** (not lock hold time)

`SET SCHEMA` needs `ACCESS EXCLUSIVE`, which conflicts with *every* other lock — including the `ACCESS SHARE` that any `SELECT` holds. If a long-running read/transaction is touching a spine table when the migration starts, the migration blocks; and because Postgres lock requests queue, **every subsequent query against that table now waits behind the migration.** A 1-second `SELECT` can thereby cause a multi-second stall across the table. (Documented thoroughly by xata "Schema changes and the Postgres lock queue", pgroll, and strong_migrations.)

**Mitigation (bake into the generated migration):** set a bounded `lock_timeout` at the top of `up`/`down`. If the lock can't be grabbed in time, the migration aborts cleanly and is simply retried — no stall, no queue pileup. This converts the only sharp operational edge into a safe, retryable failure.

### 2.6 Edge objects — what does NOT move (audited explicitly)

- **Independent sequences (not column-owned):** these would be left behind by `SET SCHEMA`. **Parapet is immune** — every spine table uses `id :binary_id, primary_key: true` (UUIDs), so there are **no sequences at all** (no `serial`/`bigserial`/identity columns). Nothing to orphan. *(This is the django-tenants `setval()` footgun — it simply does not exist for Parapet. Note it in docs so a stranger trusts the move.)*
- **Views / materialized views referencing the tables:** none ship with Parapet. If an adopter built their own view on a spine table, a schema move could break it (view stores the resolved reference). → Surface in FAQ.
- **Adopter-owned FKs pointing INTO parapet tables** (their app references `parapet_incidents`): these FKs *remain valid* (OID binding) but the adopter's own *migrations/schema dumps* may hard-code `public.parapet_incidents`. → The task must detect & warn (§3.4).
- **Extensions** (`citext`, `uuid-ossp`, `pg_trgm`): unaffected — they live in `public` and the query-prefix approach (no `search_path` change) keeps them resolving. Already a locked decision; reaffirmed here.
- **`search_path` / connection-level resolution:** not used. Resolution is purely query-prefix via `@schema_prefix`. So nothing in pooled-connection state needs touching.

---

## 3. Generated Track B migration (full `up`/`down`)

### 3.1 The migration emitted by `mix parapet.gen.schema_move`

```elixir
defmodule MyApp.Repo.Migrations.MoveParapetTablesToParapetSchema do
  @moduledoc """
  Moves Parapet's six spine tables from `public` into the dedicated
  `parapet` schema (Parapet v1.7 schema isolation, Track B).

  This is a CATALOG-ONLY move: `ALTER TABLE ... SET SCHEMA` rewrites no rows
  and scans no data, so the brief ACCESS EXCLUSIVE lock is held for
  microseconds regardless of table size. Indexes, constraints (including all
  foreign keys), and partial indexes move automatically with each table.
  All six tables move in ONE transaction, so the intra-spine FK graph stays
  valid and the move is all-or-nothing.

  The `lock_timeout` below ensures that if a long-running query is holding a
  conflicting lock, this migration aborts cleanly (and can be retried) rather
  than queueing — and blocking every query behind it.

  AFTER running this migration you MUST recompile Parapet so the compile-time
  `@schema_prefix` matches:

      # 1. (already done) mix ecto.migrate   # this migration
      # 2. config :parapet, :schema_prefix, "parapet"
      # 3. mix deps.compile parapet --force
      # 4. restart the app / cut the release

  See docs/upgrade-1.x.md for the full sequence and rollback.
  """
  use Ecto.Migration

  # Keep all six SET SCHEMA statements in ONE transaction (the default).
  # Do NOT add @disable_ddl_transaction — atomicity protects the FK graph.

  @tables ~w(
    parapet_incidents
    parapet_action_items
    parapet_timeline_entries
    parapet_tool_audits
    parapet_system_events
    parapet_action_claims
  )

  def up do
    # Bound the lock wait so we never queue behind a long transaction.
    execute "SET LOCAL lock_timeout = '5s'"

    # Idempotent: created with `create_schema: true` (default).
    # Generated with `create_schema: false` -> this line is omitted and the
    # DBA must create the `parapet` schema out of band beforehand.
    execute "CREATE SCHEMA IF NOT EXISTS parapet"

    for table <- @tables do
      execute "ALTER TABLE public.#{table} SET SCHEMA parapet"
    end
  end

  def down do
    execute "SET LOCAL lock_timeout = '5s'"

    for table <- @tables do
      execute "ALTER TABLE parapet.#{table} SET SCHEMA public"
    end

    # We intentionally DO NOT `DROP SCHEMA parapet` on rollback:
    # the adopter may have created it deliberately / via create_schema:false,
    # and dropping a schema the migration may not "own" is a surprise. Leaving
    # an empty `parapet` schema behind is harmless. (Documented in rollback.)
  end
end
```

**Why `up`/`down` instead of `change/0`:** although `execute/2` *can* be reversible inside `change/0`, the ordering matters here — on rollback you want the reverse `SET SCHEMA` direction, and you do **not** want `change/0` to auto-reverse `CREATE SCHEMA` into a `DROP SCHEMA` (which would be a destructive surprise on a least-privilege or shared schema). Explicit `up`/`down` makes the asymmetry (create on up, *don't* drop on down) obvious and intentional. This is itself a prior-art-informed choice (Oban never drops the schema on `down` either).

**Ordering of the 6 ALTERs is irrelevant to FK validity** (OID binding, single transaction) but the generated order lists parents before children purely for human readability. No reordering is needed for correctness.

**`create_schema: false` composition:** when the task is invoked with `--create-schema false` (least-privilege DBs where the migration role can't `CREATE SCHEMA`), the generated migration **omits** the `CREATE SCHEMA IF NOT EXISTS parapet` line and instead emits a comment instructing the DBA to create the schema (and grant `USAGE`/`CREATE` as needed) out of band first. This mirrors Oban's `create_schema: false` pattern exactly.

---

## 4. `mix parapet.gen.schema_move` task design

### 4.1 Shape & output

- **Generator, not a runtime mover.** It writes a timestamped migration into the host's `priv/repo/migrations/`, exactly like `parapet.gen.spine`. The adopter reviews the diff, then runs `mix ecto.migrate` themselves. (Host-owned, inspectable — engineering DNA: "prefer host-owned generated code over opaque magic.")
- **Igniter-based** (consistent with `gen.spine`), resolving the repo from `config :parapet, :repo` (already set during install).
- **Flags:**
  - `--create-schema false` → omit the `CREATE SCHEMA` line (least-privilege).
  - `--prefix parapet` (default `parapet`) → the target schema name, emitted as a **literal** into the migration so the migration is self-contained and doesn't depend on config at migrate-time.
  - `--repo MyApp.Repo` → override repo autodetection.
- **Output is a single migration file** + a printed post-gen notice that prints the exact recompile sequence (§5) and a one-line summary of what was generated (schema name, create_schema yes/no, table count).

### 4.2 Idempotency

- The **migration body** is idempotent at the schema level (`CREATE SCHEMA IF NOT EXISTS`).
- The **table moves are not individually idempotent** (`SET SCHEMA` on an already-moved table errors "relation does not exist in public"). This is *correct* and *desirable*: a half-applied migration that errors should not silently "succeed" on re-run. Because all 6 are in one transaction, a second `mix ecto.migrate` simply won't re-run an already-applied migration version (Ecto tracks `schema_migrations`). The only way to hit a partial state is `down` failing mid-way, which the single transaction prevents.
- **Re-running the generator** should detect an existing `*_move_parapet_tables_*` migration and refuse / warn rather than emit a duplicate (so the adopter doesn't accidentally run two move migrations). Print: "A schema-move migration already exists at <path>; not generating a second."

### 4.3 Composition with `create_schema: false`

`--create-schema false` is the seam to the least-privilege path. The task must also surface the **grant requirements** in its post-gen notice (the migration role needs `CREATE`/`USAGE` on `parapet`, and the *runtime* role needs `USAGE` + table privileges) so a stranger on a locked-down DB knows what to ask their DBA for. This is a known Oban-user footgun (schema exists but runtime role lacks `USAGE`).

### 4.4 Risk surfacing — renamed tables & inbound FKs (must-have)

The task should run **pre-flight detections against the connected DB** (or, if it can't connect at gen-time, emit prominent warnings in the migration + notice):

1. **Renamed spine tables.** If an adopter renamed e.g. `parapet_incidents`, the literal `ALTER TABLE public.parapet_incidents …` will fail. Detection: query `information_schema.tables` for the 6 expected names in `public`; if any are missing, **abort generation** with: "Expected table `public.parapet_incidents` not found. If you renamed Parapet tables, edit the generated migration's `@tables` list before migrating." (Don't silently emit a migration that will fail at 2am.)
2. **Inbound FKs from the adopter's own app.** If the adopter's app has a table with a FK referencing a parapet table (e.g. `my_tickets.incident_id → parapet_incidents`), the FK **stays valid** after the move (OID binding) — *but* the adopter's own schema dump / future migrations may hard-code `public.parapet_incidents`. Detection: query `pg_constraint` for FKs whose `confrelid` is one of the 6 tables but whose `conrelid` is **not** in the spine set. Emit a **warning** (not an abort): "Detected N foreign key(s) from your application into Parapet tables: <list>. These remain valid after the move, but update any of your own migrations or schema dumps that reference `public.parapet_<table>`."
3. **Views/matviews** on spine tables → same treatment: warn, list, don't abort.

These detections are the difference between "respectful guest" and "footgun." They are cheap catalog queries.

---

## 5. Recompile-order guidance (the compile-time surprise)

### 5.1 Why it bites

`@schema_prefix Application.compile_env(:parapet, :schema_prefix, "parapet")` is resolved **at compile time** and frozen into each spine schema's bytecode. Because Parapet is a **dependency** (compiled into `_build`, not the host app's own code), changing `config :parapet, :schema_prefix` and running `mix compile` is **not enough** — `mix compile` won't recompile an already-compiled dependency just because *config* changed. You must force it:

```bash
mix deps.compile parapet --force
```

**When it bites:** any time the adopter changes `:schema_prefix` (Track A pin to `nil`, or Track B flip to `"parapet"`) without forcing a dep recompile. Symptom: queries resolve to the *old* schema → "relation parapet_incidents does not exist" (if they moved data but app still queries `public`) or querying an empty `parapet` schema (if default flipped but data still in `public`).

### 5.2 Stale-compile detection

- **Ecto/`compile_env` mismatch warning is the built-in safety net.** `Application.compile_env` records the compile-time value; if the *runtime* value diverges, Mix emits a `compile_env` mismatch warning at boot ("the application :parapet has a different value … was set to X at compile time, but Y at runtime"). Document that **this warning is the canonical signal you forgot to recompile** — treat it as an error.
- **Reinforce in `mix parapet.doctor`:** add a check that compares `Application.get_env(:parapet, :schema_prefix)` (runtime) against the prefix actually baked into a spine schema's `@schema_prefix` (e.g. expose it via `Parapet.Spine.Schema.schema_prefix/0` reading the compiled value, vs. the runtime helper). If they differ, `doctor` fails with: "schema_prefix mismatch — run `mix deps.compile parapet --force` and restart." This turns a silent footgun into a CI/preflight failure. (Strongly recommended; cheap; high-leverage.)

### 5.3 The safe sequences (ORDER justified)

**Track A — stay on `public` (no data movement):**
```bash
# 1. Pin the prefix OFF so the default change can never re-point you.
#    config/config.exs:  config :parapet, :schema_prefix, nil
# 2. Force-recompile the dependency so the bytecode resolves to public.
mix deps.compile parapet --force
# 3. mix compile / restart. No migration. Tables never move.
```
Order rationale: there's no DB step, so it's just `config → recompile`. Pinning *before* recompiling is mandatory (recompile bakes in the value). **Do this even if you think you have no config line** — relying on the new default (`"parapet"`) while your data is in `public` is the failure mode.

**Track B — move to `parapet` (data movement). Order = `migrate → config → recompile → restart`:**
```bash
# 1. Generate + review the move migration.
mix parapet.gen.schema_move
git diff   # review the generated migration

# 2. MIGRATE FIRST — physically move the tables into `parapet`
#    while the app is still compiled to query `public`.
mix ecto.migrate

# 3. THEN flip config to point the app at the new schema.
#    config/config.exs:  config :parapet, :schema_prefix, "parapet"

# 4. THEN force-recompile so the bytecode resolves to `parapet`.
mix deps.compile parapet --force

# 5. Recompile the app + restart / cut the release.
mix compile
```

**Why `migrate` before `config`+`recompile` (and not the reverse):** During step 2 the running app is still compiled to query `public`. The `SET SCHEMA` move is catalog-only and the lock is sub-second, so there's a microsecond window where the table's namespace changes. If you instead recompiled to `parapet` *first* (steps 3–4 before 2), the app would query a not-yet-existing `parapet.parapet_incidents` and **every query would fail until the migration ran** — a self-inflicted outage. By migrating first, the *worst case* during the cutover is the brief lock from `SET SCHEMA` itself; the app keeps working against `public` until the very moment you deploy the recompiled release that points at `parapet`.

> Deploy-platform note (releases): in a release you typically run `mix ecto.migrate` (or the release migration task) as a **pre-deploy/pre-start step**, then start the new release image that was compiled with `schema_prefix: "parapet"`. The config flip + `deps.compile --force` happen at **build time** for the new image; the migration runs at **deploy time** against the DB before the new image takes traffic. This is the same `migrate → (new compiled code)` ordering, just split across build and deploy. Document both the dev-machine sequence and the release sequence.

**The recompile is the one thing most likely to trip a stranger.** Every code block that touches `:schema_prefix` in the docs must be immediately followed by the `mix deps.compile parapet --force` line — never assume the reader remembers it from an earlier section.

---

## 6. Rollback

### 6.1 Clean rollback (Track B fully applied)

```bash
mix ecto.rollback   # runs the migration's down/0: SET SCHEMA back to public
# then revert config + recompile:
#   config :parapet, :schema_prefix, nil   (or remove the line)
mix deps.compile parapet --force
mix compile
```
`down/0` moves all 6 tables back to `public` in one transaction (FKs/indexes follow, sub-second lock, same `lock_timeout` guard). It intentionally **does not** `DROP SCHEMA parapet` — an empty leftover schema is harmless and dropping a schema the migration may not own is a surprise. Document that the empty `parapet` schema can be dropped manually later (`DROP SCHEMA parapet;`) once confirmed empty.

**Critical rollback ordering:** roll the **DB back first** (`ecto.rollback`) while the app is still compiled for `parapet`? No — same logic as forward: the app must be querying whatever schema the data is in. Safest rollback for a live app is: **deploy the old (public-compiled) release / recompile to `public` is tricky because the data is still in `parapet`.** Therefore the documented rollback is: **(a) `ecto.rollback` to move data back to `public`, then (b) recompile to `public`, then restart.** During (a) the still-running `parapet`-compiled app would briefly query a moved-away table — so for zero-downtime rollback, do it as a deploy: ship the `public`-compiled image's migrate step (rollback) immediately before starting the `public` image. For a maintenance-window rollback, the simple `rollback → config → recompile → restart` is fine. State this tradeoff plainly.

### 6.2 Half-migrated adopter ("I ran the migration but not the recompile")

This is the most likely real-world support question. Symptom: data is in `parapet`, but app still compiled for `public` → "relation public.parapet_incidents does not exist." **Two ways out:**

- **Forward (recommended):** finish the cutover — `config :parapet, :schema_prefix, "parapet"` → `mix deps.compile parapet --force` → restart. Data's already where it should be.
- **Backward:** `mix ecto.rollback` (moves data back to `public`), leave config at `nil`, recompile. Back to square one, no data loss.

Either way **no data is lost** — `SET SCHEMA` never touches rows. The doc's FAQ must say this in the first sentence to defuse panic.

### 6.3 "I changed config but forgot to recompile"

Symptom: `compile_env` mismatch warning at boot (or `mix parapet.doctor` failure). Fix: `mix deps.compile parapet --force` + restart. No DB change involved. Make this the #1 FAQ entry.

---

## 7. `docs/upgrade-1.x.md` outline + deployment/README deltas

### 7.1 `docs/upgrade-1.x.md` (NEW) — structure & tone

**Tone:** calm, reassuring, stranger-followable. Lead with "your data does not move unless you choose." Every shell block is copy-pasteable and self-contained (includes the recompile line). No folklore — every claim ("the lock is sub-second", "no data is rewritten") stated plainly with the why.

```
# Upgrading to Parapet 1.7 (Postgres schema isolation)

## TL;DR (read this first)
- New in 1.7: Parapet's 6 spine tables DEFAULT to a dedicated `parapet`
  schema for NEW installs.
- EXISTING adopters: nothing moves automatically. Pick a track below.
- No forced migration. No data is ever rewritten. Both tracks are reversible.

## What changed and why
- One paragraph: default inversion (respectful-guest framing — own a
  schema instead of squatting `public`), and that it's opt-in for you.
- Note: resolution is query-prefix only (no search_path), so your
  citext/uuid-ossp/pg_trgm extensions in `public` keep working.

## Decide: Track A or Track B
- Small decision table:
  | You want... | Track |
  | keep tables exactly where they are, minimal change | A |
  | the clean `parapet` schema, willing to run 1 migration | B |

## Track A — stay on `public` (copy-paste)
- config :parapet, :schema_prefix, nil
- mix deps.compile parapet --force
- "Why the --force recompile?" callout (compile-time @schema_prefix)
- Done. Tables untouched. (Reassure: even if you had no config line, pin it.)

## Track B — move to the `parapet` schema (copy-paste)
- The exact migrate → config → recompile → restart sequence from §5.3.
- Show the generated migration (annotated): lock_timeout, CREATE SCHEMA,
  6 SET SCHEMA, all-in-one-transaction note.
- Callout: "This is a metadata-only move. Sub-second lock. No rows rewritten.
  FKs stay valid because all 6 tables move together. UUID PKs = no sequences
  to worry about."
- Release-platform variant (migrate at deploy, compile at build).

## Least-privilege databases (create_schema: false)
- When your migration role can't CREATE SCHEMA.
- `mix parapet.gen.schema_move --create-schema false`
- The exact GRANTs the DBA must run (CREATE/USAGE for migrate role,
  USAGE + table privs for runtime role).

## The recompile requirement (don't skip this)
- Why `mix deps.compile parapet --force` is needed (dependency bytecode).
- How to detect you forgot: the compile_env mismatch boot warning +
  `mix parapet.doctor` schema_prefix check.

## Rollback
- Full down path (Track B). The half-migrated recovery (both directions).
- "No data is lost — SET SCHEMA never touches rows" up front.
- Note the empty `parapet` schema is left behind intentionally.

## FAQ
- "I changed config but my queries broke" → recompile (#1).
- "I ran the migration but app errors on public.parapet_incidents" → finish or roll back; no data lost.
- "I have my own FK / view into parapet tables" → still valid; update your dumps.
- "I renamed a parapet table" → edit the generated @tables list.
- "Do I need a maintenance window?" → no for typical sizes; lock is sub-second.
- "Can I move only some tables?" → no; move as a unit (app correctness).
```

### 7.2 `docs/deployment.md` deltas

Add a subsection under Step 4 ("Run durable-evidence migrations"):

- **"Schema placement"** paragraph: spine tables live in `parapet` (new installs) or `public` (legacy); resolution is compile-time `@schema_prefix`; **changing it requires `mix deps.compile parapet --force`** before the release is built. Cross-link `upgrade-1.x.md`.
- In the release/`ecto.migrate` guidance, add the build-time-vs-deploy-time split for a schema move (migrate before the new compiled image takes traffic).
- Add to the Step 7 validation checklist: "If you changed `:schema_prefix`, confirm no `compile_env` mismatch warning at boot and `mix parapet.doctor` passes its schema check."

### 7.3 `README.md` delta

One short subsection ("Database schema") near the install/migration mention: "By default Parapet keeps its 6 tables in a dedicated `parapet` schema (a respectful guest in your DB). Set `config :parapet, :schema_prefix, nil` to keep them in `public`. Existing adopters: nothing moves automatically — see the [1.7 upgrade guide](docs/upgrade-1.x.md)." Link out; don't duplicate the procedure.

### 7.4 `docs/migration-v1.md` delta

The audited #1 gap: it never mentions schema. Add a short pointer ("Upgrading to 1.7? See the [schema isolation upgrade guide](upgrade-1.x.md)") so the existing migration doc routes adopters correctly. Don't inline the whole thing.

---

## 8. Prior-art lessons (cited)

- **Oban** — the gold standard for this exact pattern. (1) Migrations are versioned and `up`/`down` based, never `change/0`, and **never `DROP SCHEMA` on down** — mirror this. (2) `Oban.Migrations.up(prefix: "private", create_schema: false)` is the precedent for the least-privilege escape hatch; copy the option name and semantics. (3) Oban documents that you set the prefix in **config** *after* migrating — same ordering lesson. Footgun Oban users hit: schema exists but runtime role lacks `USAGE` → surface GRANTs in our task notice. [Oban.Migration docs](https://hexdocs.pm/oban/Oban.Migration.html)
- **Postgres `ALTER TABLE` docs** — "Associated indexes, constraints, and sequences owned by table columns are moved as well." `SET SCHEMA` is excluded from the multi-alteration list (special-cased) and is catalog-only (no rewrite). [PostgreSQL ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html)
- **xata "Schema changes and the Postgres lock queue" / pgroll** — the lock-*queue* footgun: a fast `ACCESS EXCLUSIVE` op still stalls everything if it queues behind a long transaction. → mandate `lock_timeout`. [xata](https://xata.io/blog/migrations-and-exclusive-locks) · [pgroll](https://pgroll.com/blog/schema-changes-and-the-postgres-lock-queue)
- **strong_migrations / safe-pg-migrations (Rails)** — set `lock_timeout` on the migration role; abort-and-retry beats stall; backfills go *outside* the DDL transaction. The `SET SCHEMA` move needs the `lock_timeout` lesson but is the *opposite* of the backfill case (keep it *in* one transaction for atomicity). [strong_migrations](https://github.com/ankane/strong_migrations) · [Doctolib: stop worrying about PG locks](https://medium.com/doctolib/stop-worrying-about-postgresql-locks-in-your-rails-migrations-3426027e9cc9)
- **django-tenants** — the canonical schema-move pain is **orphaned sequences** requiring manual `setval()` after a move. Parapet's all-UUID PKs make this **non-applicable** — call that out in docs as a reassurance, because adopters who've been bitten by this elsewhere will expect it. [django-tenants migrations guide](https://medium.com/thirty3hq/migrations-with-django-tenants-d2a6e702a130)
- **Ecto.Migration** — `execute/2` is reversible in `change/0`, but explicit `up`/`down` is correct here so `CREATE SCHEMA` is *not* auto-reversed into a destructive `DROP SCHEMA`. [Ecto.Migration](https://hexdocs.pm/ecto_sql/Ecto.Migration.html)

---

## 9. Constraints imposed on other dimensions

- **On PREFIX-CORE / GEN-MIGRATIONS:** the prefix must be emitted into generated migrations as a **literal string** (default `"parapet"`), not a config lookup, so the move/spine migrations are self-contained and don't change behavior if config is edited after generation. The `mix parapet.gen.schema_move` task needs the resolved prefix from the same `schema_prefix/0` runtime helper, but writes it as a literal.
- **On TEST-INFRA:** there must be a **Track B round-trip test** (create in `public` → run move migration → assert tables resolve under `parapet` AND a FK insert/delete still cascades → `down` → assert back in `public`). Also a **half-migrated** test (data in `parapet`, app compiled for `public`) is hard to express in one VM (compile-time), so verify the *mechanics* (raw SQL: table is in `parapet`, FKs valid) rather than the recompile itself. The lock_timeout statement must not break the sandbox (`SET LOCAL` inside the migration transaction is fine).
- **On `parapet.doctor` (CONTRACT-SAFETY):** add the **schema_prefix runtime-vs-compiled mismatch check** — this is the primary stale-compile detector and should be a `--ci` failure. Requires `Parapet.Spine.Schema` to expose the compiled `@schema_prefix` value for comparison.
- **On the gen task itself:** it must run (or degrade gracefully without) live catalog detections for renamed tables / inbound FKs / views. If it can't connect at gen-time, emit the warnings as comments in the migration so they're not lost.
- **On docs/CHANGELOG (DOCS/CONTRACT-SAFETY):** the default inversion is a behavior change for *brand-new* installs only; existing adopters are unaffected if they pin. Frame the CHANGELOG entry accordingly (minor bump, opt-in, no forced migration) and link `upgrade-1.x.md`.

---

### Sources
- [PostgreSQL: ALTER TABLE](https://www.postgresql.org/docs/current/sql-altertable.html)
- [PostgreSQL: Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
- [Oban.Migration docs](https://hexdocs.pm/oban/Oban.Migration.html)
- [Ecto.Migration docs](https://hexdocs.pm/ecto_sql/Ecto.Migration.html)
- [xata: Schema changes and the Postgres lock queue](https://xata.io/blog/migrations-and-exclusive-locks)
- [pgroll: Schema changes and the Postgres lock queue](https://pgroll.com/blog/schema-changes-and-the-postgres-lock-queue)
- [strong_migrations (ankane)](https://github.com/ankane/strong_migrations)
- [Doctolib: Stop worrying about PostgreSQL locks in your Rails migrations](https://medium.com/doctolib/stop-worrying-about-postgresql-locks-in-your-rails-migrations-3426027e9cc9)
- [django-tenants migrations guide](https://medium.com/thirty3hq/migrations-with-django-tenants-d2a6e702a130)
