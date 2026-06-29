# v1.7 — Ecosystem Prior-Art, Engineering-DNA & DX/Coherence

**Dimension:** Cross-cutting wisdom + coherence layer (library-product / DevEx / OSS-maintainer hat)
**Researched:** 2026-06-29
**Milestone:** v1.7 Postgres Schema Isolation
**Confidence:** HIGH on naming/posture (anchored to Oban + Ecto official docs + frozen Parapet contracts); MEDIUM on cross-language footgun applicability (most per-tenant footguns do **not** transfer to Parapet's single-schema case — that itself is the finding).

---

## 1. Summary — locked recommendations (decisive)

Parapet is doing the **easy mode** of Postgres schema isolation: **one fixed, library-owned schema** (`parapet`), not N per-tenant schemas. Almost every cross-language horror story (Apartment, django-tenants, Triplex) is about *per-tenant schema sprawl* — heterogeneous schemas, migration fan-out across hundreds of schemas, memory bloat. **None of those apply here.** The relevant precedent is **Oban**, which solved exactly this problem (a library that owns its own namespace) and is the gold standard. Match Oban's shapes wherever they don't collide with Parapet's existing vocabulary.

| Surface | LOCKED recommendation | One-line rationale |
|---|---|---|
| Config key | `config :parapet, :schema_prefix, "parapet"` | Keep `schema_prefix` — Ecto's own attribute is `@schema_prefix`; it is the precise, least-surprising name. Do **not** use bare `prefix` (collides with Parapet's frozen telemetry "event prefix" vocabulary). |
| Opt-out value | `nil` is canonical opt-out (unprefixed → resolves to `public`); accept `"public"` as an explicit synonym | `nil` = "no `@schema_prefix`" matches Ecto semantics exactly; `"public"` is a friendly alias so adopters needn't know Ecto internals. |
| Default | `"parapet"` for fresh installs; **existing adopters opt-in only** | Additive, not breaking. New installs get the clean namespace; upgraders are never force-migrated. |
| Generator schema flag | `--schema parapet` (value-taking; default `parapet`) | Mirrors the config key noun; lets least-privilege shops name it to a pre-provisioned schema. |
| Generator skip-create flag | `--no-create-schema` | Verbatim Oban parlance (`create_schema: false`); maximizes recognition for the least-privilege DBA. |
| Move task name | `mix parapet.gen.schema.move` | Dotted namespacing matches existing `parapet.gen.*` family; it **generates** a migration (host-owned), so it belongs under `gen`. Avoid `gen.schema_move` (underscore breaks the dotted tree) and `parapet.schema.move` (implies the lib mutates the DB itself — it does not; it emits a migration). |
| Upgrade doc filename | `docs/upgrade-1.x.md` | Coheres with existing `docs/migration-v1.md`; "upgrade" (not "migration") avoids overloading the Ecto-migration noun in a doc that is *about* migrations. |
| CHANGELOG posture | `feat` + an **"Additive — no action required for existing installs"** banner | It is opt-in; existing installs keep working untouched on recompile. Frame as opportunity, not breakage. |

**Coherence verdict:** the milestone shape is fully on-brand with Parapet DNA (host-owned generated migrations, library owns runtime behavior, compile-out-clean, frozen public/telemetry contracts untouched). One naming hazard to defend against (`prefix` collision) and one DX gap worth closing (`SET SCHEMA` brief lock → recommend `lock_timeout`). No incoherence flags.

---

## 2. Prior-art lessons (right / wrong / footguns — cited)

### 2.1 Oban — THE gold standard (a library that owns its own namespace)

Oban solved the identical problem Parapet faces: an installed library that wants its tables out of the host's `public` namespace. Treat it as the reference implementation.

**What makes it feel good:**
1. **Single noun, single knob.** Schema selection is one option — `prefix` — used identically in the migration (`Oban.Migrations.up(prefix: "private")`) and the runtime config (`config :my_app, Oban, prefix: "private"`). One word the adopter learns once. ([Oban.Migration docs](https://oban.hexdocs.pm/Oban.Migration.html))
2. **The least-privilege escape hatch is first-class, not a footnote.** `create_schema: false` (default `true`) explicitly exists for "your schema already exists and your DB user in production doesn't have permission to CREATE SCHEMA." This is exactly Parapet's least-privilege-DBA job. **Adopt the name verbatim.** ([Oban.Migration docs](https://oban.hexdocs.pm/Oban.Migration.html))
3. **Versioned, idempotent migrations.** `Oban.Migrations.up(version: N)` / `down(version: M)`, idempotent between versions, so upgrades are mechanical. ([Oban.Migration docs](https://oban.hexdocs.pm/Oban.Migration.html))

**Sharp edge to learn from:** Oban's docs give **no guidance whatsoever on renaming or moving an existing prefix** — adopters who picked the wrong prefix are on their own. **This is precisely the gap Parapet should turn into a strength:** ship `mix parapet.gen.schema.move` (the `SET SCHEMA` task) + `docs/upgrade-1.x.md` so the move is a paved road, not a forum question. This is a genuine differentiator over the gold standard.

**Naming divergence (deliberate):** Oban calls it `prefix`; Parapet must **not**, because `[:parapet, …]` telemetry already owns "event prefix" vocabulary and `docs/stability.md` explicitly promises "No configurable `:event_prefix`." Reusing bare `prefix` for the schema would create two unrelated "prefix" concepts in one library. Use `schema_prefix` (which is *also* Ecto's own attribute name `@schema_prefix`, so it's not a Parapet invention — it's the most authoritative name available).

### 2.2 Ecto `@schema_prefix` vs runtime `prefix:` — the central footgun (confirmed authoritative)

The seed's asymmetric-precedence finding is **confirmed by Ecto's official multi-tenancy guide**:
- For **queries** (`all`/`update_all`/`delete_all`): a `prefix` on `from`/`join` takes precedence over everything.
- For **schema operations** (`insert`/`update`/`delete`/`insert_all`): the `:prefix` *option* overrides both `@schema_prefix` and the struct/changeset prefix. ([Ecto multi-tenancy guide](https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html))

**Lesson:** runtime `prefix:` repo options can resolve reads and writes to different schemas (split-brain). **Decision stands: compile-time `@schema_prefix` only, runtime `prefix:` banned** with a guard test. Belt-and-suspenders DX: a `@schema_prefix`-stamping macro means the prefix auto-propagates through queries, `insert_all(SchemaModule, …)`, `Ecto.Multi`, and joins — the adopter never threads it manually.

### 2.3 Triplex — closest Elixir precedent for the *raw-SQL* gotcha

Triplex (per-tenant schemas, so its overall model is *not* Parapet's) still surfaces one directly-transferable lesson: **"Ecto auto-adds prefixes to standard migration functions; if you have custom SQL in your migrations, you must use Ecto's `prefix` function yourself."** ([Triplex README](https://github.com/ateliware/triplex)) — This is exactly Parapet's `test/support/concurrency_bootstrap.ex` situation: raw `CREATE SCHEMA` / `CREATE TABLE` / `REFERENCES` / `TRUNCATE` will **not** inherit `@schema_prefix` and must be hand-qualified. The TEST-INFRA dimension owns this; flagging it here so it isn't forgotten.

### 2.4 Ash multitenancy — what to *avoid* importing

Ash's `:context` strategy (AshPostgres → per-tenant schemas) and `:attribute` strategy are **runtime tenant-switching** machinery (`Ash.Query.set_tenant/2`). ([Ash multitenancy](https://hexdocs.pm/ash/multitenancy.html)) **Do not import any runtime tenant-switching surface** — Parapet has exactly one fixed schema. Importing a `set_tenant`-style API would be over-engineering and would re-introduce the runtime-`prefix:` split-brain. The single-schema constraint is a feature; keep it.

### 2.5 Cross-language vision — what to emulate / avoid

| Source | What to emulate | What to avoid (and why it mostly doesn't apply to Parapet) |
|---|---|---|
| **Rails Apartment** | The *one-schema* discipline. | Its pain — `schema.rb` contamination → **heterogeneous schemas across tenants**, migration time scaling with tenant count, memory bloat per tenant, and the original maintainers *abandoning* schema-per-tenant. ([Apartment retrospective, Influitive/Medium](https://medium.com/infinite-monkeys/our-multi-tenancy-journey-with-postgres-schemas-and-apartment-6ecda151a21f)) **All are per-tenant-sprawl problems. Parapet has ONE schema → none apply.** Worth a one-line note in the upgrade doc: "Parapet uses a single fixed schema, not schema-per-tenant; the well-known Apartment-style migration-fan-out costs do not apply." |
| **strong_migrations / Squawk (PG lock lore)** | `ALTER TABLE … SET SCHEMA` is **metadata-only** and carries indexes/constraints/sequences with it — but it still briefly takes an **`ACCESS EXCLUSIVE`** lock, and PG's lock queue is FIFO so a blocked DDL can stall reads behind it. ([Squawk PG locks](https://squawkhq.com/docs/postgres-locks), [PostgresAI lock_timeout](https://postgres.ai/blog/20210923-zero-downtime-postgres-schema-migrations-lock-timeout-and-retries)) | **DX touch worth shipping:** the generated `schema.move` migration should mention (comment) setting a `lock_timeout` and running off-peak. The move is fast (no data rewrite) but is not zero-lock; say so honestly. |
| **django-tenants** | Same single-vs-many lesson; its complexity is shared-vs-tenant app routing — not relevant. | Don't build a routing/middleware layer. |
| **Flyway/Hibernate** | Versioned, repeatable, idempotent migration philosophy (mirrors Oban's versioned migrations). | N/A. |

---

## 3. Config-knob & naming recommendations (table)

| Surface | Recommended name | Rationale | Ecosystem precedent |
|---|---|---|---|
| Config key | `config :parapet, :schema_prefix, "parapet"` | Precise; matches Ecto's own `@schema_prefix` attribute; avoids the frozen telemetry "event prefix" collision. | Ecto `@schema_prefix` ([Ecto](https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html)) |
| Default value | `"parapet"` | Library owns a namespace named after itself (same instinct as Oban defaulting tables under its own name). | Oban |
| Opt-out (canonical) | `nil` | "no `@schema_prefix`" → resolves to `public`; exact Ecto semantics, zero surprise for Ecto-literate adopters. | Ecto |
| Opt-out (alias) | `"public"` | Friendly synonym so adopters needn't know Ecto internals; treat `"public"` identically to `nil` (emit unprefixed SQL). | — (Parapet kindness) |
| Runtime resolver | `Parapet.<…>.schema_prefix/0` returning the configured value | One runtime read for generators + raw SQL; colocate with `Parapet.Evidence.repo/0` (`lib/parapet/evidence.ex`). | — |
| Stamping macro | `use Parapet.Spine.Schema` | Single place stamps `@schema_prefix` on all 6 spine schemas → auto-propagation; least-magic, most-DRY. | Carbonite/Oban-style schema base modules |
| Generator: schema name | `--schema parapet` (value-taking) | Noun matches the config key; lets a DBA point at a pre-provisioned schema. | Oban `prefix:` |
| Generator: skip create | `--no-create-schema` | Verbatim Oban; instant recognition for least-privilege DBs. | Oban `create_schema: false` (default `true`) ([Oban](https://oban.hexdocs.pm/Oban.Migration.html)) |
| Move task | `mix parapet.gen.schema.move` | Dotted, lives in the `parapet.gen.*` family; it *generates* a host-owned migration. | Phoenix `mix ecto.gen.migration` dotted convention |
| Upgrade doc | `docs/upgrade-1.x.md` | Sits beside `docs/migration-v1.md`; "upgrade" avoids overloading "migration". | Existing Parapet docs |
| CHANGELOG entry type | `feat` | New capability; additive. | Conventional Commits (Parapet DNA) |

**Naming rejections (explicit):**
- ❌ `config :parapet, :prefix` — collides with frozen telemetry event-prefix vocabulary (`docs/stability.md`: "No configurable `:event_prefix`"). Two "prefix" concepts in one lib = confusion.
- ❌ `config :parapet, :schema` — too generic; reads like "the Ecto schema module," not "the Postgres namespace."
- ❌ `mix parapet.gen.schema_move` — underscore detaches it from the dotted `gen` tree; tab-completion and the task index group it wrong.
- ❌ `mix parapet.schema.move` — drops `gen`, implying Parapet itself runs the `ALTER`. It does not; it **emits a host-owned, reviewable, reversible migration**. Keeping `gen` preserves the "library writes scaffolding, host owns runtime" DNA boundary.

---

## 4. Vision / coherence check vs Parapet engineering DNA

Checked against `prompts/parapet-engineering-dna-from-sibling-libs.md`, `docs/stability.md`, and `docs/migration-v1.md`. **The milestone coheres cleanly on every axis:**

| DNA principle | v1.7 alignment | Status |
|---|---|---|
| **Host-owned generated code, not opaque magic** (DNA §1 DX, §3) | `schema.move` and `gen.spine` *emit* migrations the host reviews/owns; the prefix literal is written into the migration so it's self-contained and inspectable. | ✅ |
| **Library owns runtime behavior** | The stamping macro + `@schema_prefix` own propagation at runtime; adopter never threads a prefix. | ✅ |
| **Optional deps / features compile out clean** (DNA §1, §6) | Schema isolation is pure DDL + a compile-time attribute; no new deps; `--no-create-schema` keeps least-privilege installs clean. | ✅ |
| **Frozen public API + telemetry contracts** (`docs/stability.md`) | Spine schemas are **Internal tier** (`Parapet.Spine.*` listed as Internal in stability.md). A namespace move is an internal DB detail — the Stable/Experimental surface and `[:parapet,…]` events are untouched. **Add the regression gate to done-criteria** (`mix verify.public_api` + telemetry contract test). | ✅ (gate it) |
| **Structured/actionable failures** (DNA §1) | The runtime-`prefix:` ban should `raise` with a structured "use `config :parapet, :schema_prefix` instead; runtime prefix causes read/write split-brain" message — not a silent ignore. | ✅ (design the error) |
| **Respectful guest in the host app** (DNA §2.3) | The whole milestone *is* this principle: stop polluting host `public`, behave like a clean Phoenix-context/DDD citizen. **This is the most on-brand milestone Parapet could ship.** | ✅✅ |
| **Docs a stranger can follow** (DNA §1) | `docs/upgrade-1.x.md` with copy-paste Track A / Track B; matches the step-numbered tone of `docs/migration-v1.md`. | ✅ |
| **Conventional Commits + Release Please** | `feat`, additive, minor bump; no manifest hand-edits. | ✅ |

**Flags / risks (none blocking):**
1. **`compile_env` recompile surprise (real, must document).** `Application.compile_env(:parapet, :schema_prefix, …)` is read at *compile* time. An adopter who flips the config but doesn't `mix deps.compile parapet --force` gets stale behavior — a classic confusing failure. **Mitigation:** make `docs/upgrade-1.x.md` Track A literally say "config change + `mix deps.compile parapet --force`," and consider a `runtime.exs`-vs-compiled divergence check in `mix parapet.doctor` (Parapet already ships a doctor — wiring a "your configured schema_prefix doesn't match what's compiled in" check is squarely on-brand with the "doctor/diagnostics first-class" DNA). **Cross-dimension constraint** for the prefix-mechanism dimension.
2. **Brand/UI: N/A** for this DB milestone. Only developer-facing surfaces (generator output comments, doc tone) matter, and they should match the existing terse, step-numbered, no-emoji house style of `docs/migration-v1.md`. (Per instructions: `prompts/` brand references that predate `brandbook/` were not consulted — not needed for a DB milestone.)
3. **No telemetry temptation.** Resist adding a `[:parapet, :schema, …]` event for the move — telemetry is frozen and the move is a one-shot migration, not a runtime operation. Keep it out of the event surface.

---

## 5. Adopter JTBD framing (keeps the other 4 dimensions user-centered)

Domain language to keep consistent across all dimensions: **noun = "schema" (the Postgres namespace `parapet`); verb = "move" (relocate existing tables via `SET SCHEMA`); knob = `schema_prefix`; hatch = `create_schema`.** Avoid "tenant," "migrate" (overloaded), and bare "prefix."

| # | Job (who → what → why) | What they need | What they get | Owning dimensions |
|---|---|---|---|---|
| **J1** | **Fresh installer** — new adopter runs `mix parapet.install` → wants Parapet's tables to *not* clutter `public`, just like Oban → because a clean DDD/Phoenix-context boundary is professional hygiene. | Zero extra steps; `parapet` schema "just happens." | Generator writes `config :parapet, :schema_prefix, "parapet"` + `CREATE SCHEMA IF NOT EXISTS parapet` + prefixed `create table`s. Done. | GEN-MIGRATIONS, PREFIX-CORE |
| **J2** | **Existing adopter, stay on public** — already on v1.6 with tables in `public` → wants the v1.7 upgrade to change *nothing* in their DB → because they have no appetite for a DB migration right now. | A one-line opt-out + a clear "no DB change" promise. | `config :parapet, :schema_prefix, nil` + `mix deps.compile parapet --force`. Tables untouched. **No forced migration.** | UPGRADE-PATH (Track A), DOCS |
| **J3** | **Existing adopter, move to schema** — wants the clean namespace retroactively → because they're tidying tech debt / aligning with new installs. | A safe, reversible, paved-road move; confidence FKs survive. | `mix parapet.gen.schema.move` → reviewable migration: `CREATE SCHEMA` + 6× `ALTER TABLE … SET SCHEMA` (metadata-only, carries indexes/constraints/sequences; FKs stay valid because all 6 move as a unit) + reversible `down`. | UPGRADE-PATH (Track B), TEST-INFRA, DOCS |
| **J4** | **Least-privilege DBA** — production DB user can't `CREATE SCHEMA` → wants to pre-provision `parapet` out-of-band and have Parapet *not* try to create it → because security policy forbids broad grants. | A flag to skip schema creation; ability to name a pre-existing schema. | `--no-create-schema` + `--schema <preprovisioned>`. Exactly Oban's least-privilege contract. | GEN-MIGRATIONS, DOCS |

**Emotional JTBD (the real bar):** "Help me upgrade **without fear** — prove my existing install keeps working untouched, and if I *choose* to move, prove the move is reversible and FK-safe." Every dimension's done-criteria should map to removing that fear (the stay-on-public test, the move round-trip test, the FK-intact assertion).

---

## 6. CHANGELOG / semver wording posture

**Posture: this is `feat` + additive, NOT breaking — and the wording must make existing adopters feel safe, not alarmed.** The default *for new installs* inverts (now `parapet`, was `public`), but **existing installs are never auto-migrated** — on upgrade they keep resolving to `public` until they opt in. That is the entire difference between "scary" and "additive."

Recommended CHANGELOG entry shape (Keep-a-Changelog under the version, Conventional `feat`):

```markdown
### Added
- **Dedicated `parapet` Postgres schema for spine tables.** New installs now place
  Parapet's six spine tables in a dedicated `parapet` schema instead of `public`,
  keeping the host's `public` namespace clean. Configurable via
  `config :parapet, :schema_prefix, "parapet"`.
- `mix parapet.gen.schema.move` — generates a reversible migration that relocates
  existing spine tables from `public` into the `parapet` schema (`ALTER TABLE … SET SCHEMA`).
- `--no-create-schema` generator flag for least-privilege databases that pre-provision
  the schema out-of-band.

> **Upgrading? No action required.** Existing installs keep their tables in `public`
> and are **not** auto-migrated. Opting into the new schema is entirely optional —
> see [docs/upgrade-1.x.md](docs/upgrade-1.x.md) for the stay-on-`public` (Track A)
> and move-to-`parapet` (Track B) paths.
```

**Wording rules:**
- Lead the human-facing note with **"No action required for existing installs."** This is the anxiety-killer; put it before any detail.
- Use **"new installs"** explicitly so upgraders self-identify as unaffected.
- Never use the word **"breaking"** — it is not breaking; it is a *default inversion for fresh installs only.* (Pre-1.0 semver allowed breaking-in-minor per `rulestead-release-engineering-and-ci.md` §15, but Parapet is post-1.0 and this change does **not** require that latitude — it's genuinely additive, so keep it a minor `feat`.)
- Pair the CHANGELOG with a one-paragraph release-note callout reusing the same "no action required" sentence verbatim — consistency reduces support questions.

---

## 7. Cross-dimension coherence constraints (the other 4 dimensions MUST honor)

These are the load-bearing constraints this coherence pass imposes so the milestone stays cohesive:

1. **Naming is LOCKED (§1 table).** All dimensions use `schema_prefix` (never bare `prefix`), `--schema` / `--no-create-schema`, `mix parapet.gen.schema.move`, `docs/upgrade-1.x.md`. The mechanism dimension must not introduce a second name.
2. **`nil` and `"public"` are both opt-out** and must emit *identical* unprefixed SQL. The stay-on-public test must cover at least one of them explicitly (prefer asserting on `nil`, the canonical form).
3. **Runtime `prefix:` is banned with a `raise`-ing guard + a guard test** (PREFIX-PROP dimension owns the test; the error message is structured/actionable per DNA).
4. **`compile_env` recompile is documented and ideally doctored.** Track A docs must include `mix deps.compile parapet --force`; a `parapet.doctor` divergence check is the on-brand bonus (prefix-mechanism dimension).
5. **Raw SQL must be hand-qualified** — `@schema_prefix` does not reach raw `CREATE SCHEMA`/`CREATE TABLE`/`REFERENCES`/`TRUNCATE` (Triplex's documented gotcha). TEST-INFRA dimension owns this; the generated library migrations must use literal-prefixed SQL too.
6. **Generated migrations are host-owned, self-contained, and reversible.** Prefix emitted as a literal (not a runtime call) so the migration is inspectable and re-runnable; `schema.move` ships a working `down`; least-privilege `--no-create-schema` path produces a migration that does *not* CREATE SCHEMA. (GEN-MIGRATIONS + UPGRADE-PATH.)
7. **Frozen-contract regression gate is in done-criteria.** `mix verify.public_api` + telemetry contract test must stay green; no `[:parapet, :schema, …]` event added. (CONTRACT-SAFETY.)
8. **`SET SCHEMA` is fast but not zero-lock.** The generated move migration should carry a comment about `lock_timeout` / off-peak execution — honest DX, not a silent footgun. (UPGRADE-PATH + DOCS.)

---

## Sources

- [Oban.Migration — `prefix`, `create_schema: false`, versioned `up`/`down`](https://oban.hexdocs.pm/Oban.Migration.html) (HIGH — official, curated)
- [Ecto — Multi tenancy with query prefixes (`@schema_prefix` vs `:prefix` precedence)](https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html) (HIGH — official, curated)
- [Triplex — custom-SQL migrations need explicit `prefix`](https://github.com/ateliware/triplex) (MEDIUM — README)
- [Ash — multitenancy strategies (`:attribute`, `:context`)](https://hexdocs.pm/ash/multitenancy.html) (MEDIUM — official)
- [Rails Apartment retrospective — schema-per-tenant footguns](https://medium.com/infinite-monkeys/our-multi-tenancy-journey-with-postgres-schemas-and-apartment-6ecda151a21f) (MEDIUM — practitioner post-mortem; cross-language, mostly *non-applicable* to single-schema)
- [Squawk — Postgres lock types](https://squawkhq.com/docs/postgres-locks) / [PostgresAI — `lock_timeout` for zero-downtime DDL](https://postgres.ai/blog/20210923-zero-downtime-postgres-schema-migrations-lock-timeout-and-retries) (MEDIUM — `SET SCHEMA` lock posture)
- Parapet internal: `prompts/parapet-engineering-dna-from-sibling-libs.md`, `prompts/prior-art/rulestead-release-engineering-and-ci.md`, `docs/stability.md` (Spine = Internal tier; "No configurable `:event_prefix`"), `docs/migration-v1.md` (upgrade-doc tone precedent), `.planning/research/V1.7-SCHEMA-ISOLATION.md` (seed) (HIGH — primary)
