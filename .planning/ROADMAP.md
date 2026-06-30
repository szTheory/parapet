# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)
- [x] **v1.5 Brand Book & Logo System** — Phases 40-43, 11 plans, shipped 2026-06-24. Archive: [v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)
- [x] **v1.6 Operator UI Brand & Design-System Audit** — Phases 44-50, 25 plans, shipped 2026-06-29. Archive: [v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)
- [ ] **v1.7 Postgres Schema Isolation & Upgrade Path** — Phases 51-56 (in progress)

## Phases

<details>
<summary>✅ v1.5 Brand Book & Logo System (Phases 40-43) — SHIPPED 2026-06-24</summary>

- [x] Phase 40: Brand Pressure-Test & Critique Gate (1/1 plans) — completed 2026-06-23
- [x] Phase 41: Logo Exploration & User Selection Gate (6/6 rounds) — completed 2026-06-24
- [x] Phase 42: Token System & HTML Brand Book (3/3 plans) — completed 2026-06-24
- [x] Phase 43: Collateral, Wiring & QA/Audit Gate (3/3 plans) — completed 2026-06-24

Full detail: [milestones/v1.5-ROADMAP.md](milestones/v1.5-ROADMAP.md)

</details>

<details>
<summary>✅ v1.6 Operator UI Brand & Design-System Audit (Phases 44-50) — SHIPPED 2026-06-29</summary>

- [x] Phase 44: Foundations — token re-skin, fonts & audit apparatus (4/4 plans) — completed 2026-06-25
- [x] Phase 45: Primitive components (4/4 plans) — completed 2026-06-25
- [x] Phase 46: Navigation, shell & data-display (4/4 plans) — completed 2026-06-26
- [x] Phase 47: Component groups / meta-components (3/3 plans) — completed 2026-06-26
- [x] Phase 48: Pages, flows & microcopy (4/4 plans) — completed 2026-06-28
- [x] Phase 49: Stress fixtures & seed coverage (3/3 plans) — completed 2026-06-28
- [x] Phase 50: Guardrails, parity & idempotence gate (3/3 plans) — completed 2026-06-28

Full detail: [milestones/v1.6-ROADMAP.md](milestones/v1.6-ROADMAP.md)

</details>

### 🚧 v1.7 Postgres Schema Isolation & Upgrade Path (In Progress)

**Milestone Goal:** Parapet's six spine tables live in a dedicated, configurable `parapet` Postgres schema by default (compile-time `@schema_prefix`, no runtime `prefix:`), existing adopters get a documented, tested, opt-in upgrade path (stay-on-`public` or a reversible `SET SCHEMA` move), and both the public API and telemetry contracts stay provably frozen. Closes the audited #1 quality weakness: no adopter-facing DB-schema upgrade story.

- [x] **Phase 51: Prefix Core & Test Seam** - Shared `use Parapet.Spine.Schema` compile-time `@schema_prefix` macro across all six spine schemas, single-sourced normalization, the `config/config.exs` env seam, and the hand-qualified concurrency bootstrap so the suite can run under the prefix at all. (completed 2026-06-30)
- [ ] **Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix** - Prove the compiled prefix rides every read/write (selects, joins, `insert_all`, Multi) with zero call-site edits, ban runtime `prefix:`/string-table writes via a static guard, and validate both legs with a `schema_prefix: ['parapet','public']` CI matrix that recompiles per value.
- [ ] **Phase 53: Generators & Library Migrations** - A first-ordered `CREATE SCHEMA` migration, prefix-stamped DDL on every table/reference/index, non-clobbering config writes, the `--schema`/`--no-create-schema` hatch, and a shared resolver consumed by `gen.spine`, `gen.archive_indexes`, and `install`.
- [ ] **Phase 54: Upgrade Path & Doctor** - `mix parapet.gen.schema.move` emitting a reversible single-transaction `SET SCHEMA` move with pre-flight catalog detection, the documented stay-on-`public` Track A, a throwaway-DB round-trip test, and a `parapet.doctor` config↔compiled drift + schema-existence check.
- [ ] **Phase 55: Demo App & Upgrade Docs** - The demo migrates end-to-end into `parapet` as the real-host smoke proof, plus `docs/upgrade-1.x.md` and deployment/README/migration-v1 deltas that give adopters a copy-paste upgrade story.
- [ ] **Phase 56: Contract & Release Hardening** - Assert the frozen-contract regression gate (`verify.public_api` + telemetry + compile-out all green, no new events), ship the `feat` "No action required for existing installs" CHANGELOG/release-note framing, and close the milestone done-criteria.

## Phase Details

### Phase 51: Prefix Core & Test Seam

**Goal**: All six spine schemas resolve a single compile-time `@schema_prefix` (default `parapet`, `nil`/`""`/`"public"` ⇒ unprefixed) through a shared macro, and the existing test infrastructure can run under that prefix.
**Depends on**: Phase 50 (v1.6 close — first phase of v1.7)
**Requirements**: PREFIX-01, PREFIX-02, PREFIX-03, PREFIX-04, TEST-01, TEST-02
**Success Criteria** (what must be TRUE):

  1. All six spine schemas `use Parapet.Spine.Schema` and carry the same `@schema_prefix`; `__schema__(:prefix)` returns `"parapet"` for all six under the default config (and the repeated `@primary_key`/`@foreign_key_type` declarations are deduped into the macro).
  2. The shared normalization helper maps `["parapet","","public",nil,"custom"]` identically in the macro's `__prefix__/0` and the `config/config.exs` copy — a unit test asserts the two copies agree; `nil`/`""`/`"public"` all yield byte-identical legacy (unprefixed) SQL.
  3. `config/config.exs` reads `PARAPET_SCHEMA_PREFIX` (default-on `parapet`) so `compile_env` has a real source, and `config/` is confirmed excluded from the Hex `package.files` whitelist.
  4. `test/support/concurrency_bootstrap.ex` is hand-qualified — `CREATE SCHEMA IF NOT EXISTS`, every `CREATE TABLE`/`REFERENCES`/`ON`/`TRUNCATE` qualified to the prefixed schema (index *targets*, not names), `schema_migrations` left in `public` — and the full suite is green under `schema_prefix: parapet`.

**Plans**: 3/3 plans complete

- [x] 51-01-PLAN.md — Prefix core seam: `Parapet.Spine.Schema` macro + `config/config.exs` + `Evidence.schema_prefix/0` + Wave 0 test scaffold
- [x] 51-02-PLAN.md — Switch all six spine schemas to `use Parapet.Spine.Schema` (pure subtraction); `__schema__(:prefix) == "parapet"`
- [x] 51-03-PLAN.md — Hand-qualify the concurrency bootstrap; full suite green under `schema_prefix: parapet`

### Phase 52: Propagation Proof, Guards & CI Dual-Prefix Matrix

**Goal**: Prove the compiled prefix propagates across every read/write path with zero call-site changes, make runtime `prefix:` and prefix-dropping writes impossible to reintroduce, and validate both `parapet` and `public` legs honestly in CI.
**Depends on**: Phase 51
**Requirements**: PROP-01, PROP-02, PROP-03, TEST-03
**Success Criteria** (what must be TRUE):

  1. Regression tests on the two spine↔spine joins (`mcp/server.ex`, `circuit_breaker.ex`), the `claim_service` `insert_all`, and the `evidence.ex` `Ecto.Multi` prove the prefix rides each with no call-site edits, and no join spans `parapet`+`public`.
  2. `to_sql`/`Ecto.get_meta(struct, :prefix)` assertions ride every test leg showing the compiled prefix on selects/joins/`insert_all`/Multi, with a negative "no bare `parapet_incidents`" assertion under the prefixed leg and `__schema__(:prefix)` matching across all six schemas.
  3. A static guard test over `lib/` fails the build with a structured, actionable message if any runtime `prefix:` is threaded into a repo call, any `insert_all`/`update_all`/`delete_all` uses a string-literal table name, or any `search_path`/raw `parapet_` SQL appears — green from day one (zero offenders today).
  4. A CI matrix axis `schema_prefix: ['parapet','public']` recompiles (`mix compile --force`) and reruns the full suite per value, with the `_build` cache key namespaced by prefix so the `public` leg cannot silently reuse the `parapet` build (no false-green).

**Plans**: TBD

### Phase 53: Generators & Library Migrations

**Goal**: Generators and Parapet's committed library migrations create the spine under the configured schema, stamping `prefix:` everywhere and writing config without clobbering adopters, with a least-privilege `--no-create-schema` hatch.
**Depends on**: Phase 51 (prefix core), Phase 52 (guards green)
**Requirements**: GEN-01, GEN-02, GEN-03, GEN-04, GEN-05, GEN-06, GEN-07
**Success Criteria** (what must be TRUE):

  1. A dedicated, first-ordered `*_create_parapet_schema` migration emits reversible `CREATE SCHEMA IF NOT EXISTS parapet` / `DROP SCHEMA IF EXISTS parapet` (non-cascading), and `mix parapet.gen.spine`/`gen.archive_indexes` stamp a literal `prefix:` on every `create table`, each `references/2`, and every index — with FK constraint names asserted unchanged.
  2. Generators write `config :parapet, :schema_prefix, "parapet"` via Igniter `configure_new/5` (never clobbering an adopter's value), and a `--schema` vs existing-config conflict warns rather than crashes.
  3. `--schema parapet` and `--no-create-schema` flags work Oban-verbatim: `--no-create-schema` omits the schema migration, keeps tables fully prefixed, and prints the exact `CREATE SCHEMA` + `GRANT` remediation for the DBA; one shared resolver (`flag > existing config > default`) drives `gen.spine`, `gen.archive_indexes`, and `install`.
  4. Parapet's five committed library migrations and the demo migrations create their tables under the schema (demo's plain `mix ecto.migrate` self-creates it), and generator-output tests pass: AST substring asserts plus a `prefix:` count-guard, one small golden for the schema migration only, and `--no-create-schema`/existing-config branch coverage.

**Plans**: TBD

### Phase 54: Upgrade Path & Doctor

**Goal**: Existing adopters have two tested, opt-in upgrade tracks — stay on `public`, or a reversible single-transaction `SET SCHEMA` move — plus a doctor preflight that catches the compile-time recompile footgun.
**Depends on**: Phase 53 (generator/migration machinery), Phase 52 (round-trip rides the propagation proof)
**Requirements**: UPG-01, UPG-02, UPG-03, UPG-04, UPG-05, DOCTOR-01
**Success Criteria** (what must be TRUE):

  1. Track A is pinned by a test proving `schema_prefix: nil` emits unprefixed SQL with green queries, and upgrading an existing adopter never forces a schema migration — the default flips for new installs only.
  2. `mix parapet.gen.schema.move` generates a reversible migration (`SET LOCAL lock_timeout = '5s'`, `CREATE SCHEMA IF NOT EXISTS parapet` omitted under `--no-create-schema`, `ALTER TABLE … SET SCHEMA` for all six tables in one transaction; `down` restores `public` and never `DROP SCHEMA`), and the task runs pre-flight catalog detections (abort on missing/renamed spine tables, warn on inbound app FKs/views, refuse a second move migration).
  3. A Track B round-trip test against a throwaway DB proves: created in `public` → up → resolves under `parapet` with FK cascade + partial indexes intact → down → restored to `public`.
  4. A `mix parapet.doctor` check compares runtime `:schema_prefix` against the compiled `@schema_prefix`, fails (CI-grade under `--ci`) on drift with the `mix deps.compile parapet --force` remediation, and verifies the configured schema exists.

**Plans**: TBD

### Phase 55: Demo App & Upgrade Docs

**Goal**: The demo app proves the prefix end-to-end on a real Phoenix host, and adopters have a copy-paste upgrade story that closes the audited #1 documentation gap.
**Depends on**: Phase 54 (move task + tracks must exist to be documented), Phase 53 (demo migrations land in the schema)
**Requirements**: DOC-01, DOC-02, SAFE-03
**Success Criteria** (what must be TRUE):

  1. The demo smoke lane asserts `mix ecto.migrate` lands all six tables in the `parapet` schema (via `information_schema.tables`) and an evidence round-trip carries `Ecto.get_meta(record, :prefix) == "parapet"`; compile-out-clean (`--warnings-as-errors`, `--no-optional-deps`) holds.
  2. `docs/upgrade-1.x.md` exists and leads with "your data does not move unless you choose", with copy-paste Track A/B blocks (each config block followed by the `--force` recompile line), least-privilege GRANTs, recompile-order guidance, rollback incl. half-migrated recovery, and an FAQ.
  3. `docs/deployment.md` has a schema subsection, `README.md` carries a note, and `docs/migration-v1.md` routes to the new upgrade doc (the audited #1 gap).

**Plans**: TBD
**UI hint**: yes

### Phase 56: Contract & Release Hardening

**Goal**: The milestone closes with the public API and telemetry contracts provably frozen and the change framed honestly as additive for existing installs.
**Depends on**: Phase 55 (full feature surface landed; demo proves behavior)
**Requirements**: SAFE-01, SAFE-02, SAFE-04
**Success Criteria** (what must be TRUE):

  1. `mix verify.public_api` is green with zero `--write` — the prefix is a module attribute, not an export — and this frozen-contract regression check is asserted as a milestone done-criterion.
  2. The telemetry contract test stays green, no `[:parapet, :schema, …]` event is added, and Ecto query telemetry `:source` (the bare table name) is confirmed unaffected.
  3. A `feat` CHANGELOG entry frames the change as additive (semver minor) with a "No action required for existing installs" banner, plus a matching release-note callout.

**Plans**: TBD

## Next Milestone

After v1.7 ships, the approved v1.7→v1.9 roadmap continues:

- **v1.8 CI/CD performance & DX** — Dialyzer PLT caching, `concurrency: cancel-in-progress`, lint-once, `mix ci` alias, `Process.sleep` removal, 3-OTP matrix → main+nightly (CI-01). Note: v1.7's dual-prefix matrix interacts with this pipeline reshape — sequence accordingly.
- **v1.9 Quality hardening** — telemetry drift gate `telemetry_stable.json` (TELEM-01), decompose the `operator.ex` god-module behind the frozen Stable surface (REFACTOR-01), Playwright + axe-core a11y lane and ExUnit-pin the v1.6 `override_closeout` gaps (A11Y-01).

## Progress Table

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 51. Prefix Core & Test Seam | v1.7 | 3/3 | Complete    | 2026-06-30 |
| 52. Propagation Proof, Guards & CI Dual-Prefix Matrix | v1.7 | 0/TBD | Not started | - |
| 53. Generators & Library Migrations | v1.7 | 0/TBD | Not started | - |
| 54. Upgrade Path & Doctor | v1.7 | 0/TBD | Not started | - |
| 55. Demo App & Upgrade Docs | v1.7 | 0/TBD | Not started | - |
| 56. Contract & Release Hardening | v1.7 | 0/TBD | Not started | - |
