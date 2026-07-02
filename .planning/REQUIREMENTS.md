# Requirements: Parapet — v1.7 Postgres Schema Isolation & Upgrade Path

**Defined:** 2026-06-29 (refined after 5-dimension design research — see `.planning/research/v1.7/00-SYNTHESIS.md`)
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## v1.7 Requirements

Requirements for the v1.7 milestone. Each maps to exactly one roadmap phase. Research-grounded decisions
(naming, mechanism, gates) are locked in `00-SYNTHESIS.md` §1.

### Schema Prefix Core (`PREFIX`)

- [x] **PREFIX-01**: All six spine schemas use a shared `use Parapet.Spine.Schema` macro that sets a compile-time `@schema_prefix` (also dedups the repeated `@primary_key`/`@foreign_key_type` declarations).
- [x] **PREFIX-02**: The prefix defaults to `parapet`, read via `Application.compile_env(:parapet, :schema_prefix, "parapet")`.
- [x] **PREFIX-03**: `nil`, `""`, and `"public"` all normalize to unprefixed (byte-identical legacy SQL), via a single shared normalization helper used by the macro; a unit test asserts the macro's copy and the `config/config.exs` copy agree on `["parapet","","public",nil,"custom"]`.
- [x] **PREFIX-04**: A runtime resolution helper (`schema_prefix/0`, colocated with `Parapet.Evidence.repo/0`) supplies the prefix to runtime-only sites (generators, raw SQL).

### Prefix Propagation (`PROP`)

- [x] **PROP-01**: The prefix auto-propagates with zero call-site changes across `Repo.*`, `insert_all(SchemaModule, …)`, `Ecto.Multi`, and the two spine↔spine joins (`mcp/server.ex`, `circuit_breaker.ex`) — pinned by regression tests on those join sites, the `claim_service` `insert_all`, and the `evidence.ex` Multi.
- [x] **PROP-02**: Runtime `prefix:` is banned by a static guard test over `lib/` that also flags string-literal-table `insert_all`/`update_all`/`delete_all`, `search_path` usage, and raw SQL naming a `parapet_` table; if a runtime `prefix:` is ever introduced it fails the build with a structured, actionable message.
- [x] **PROP-03**: `to_sql`/`Ecto.get_meta(struct, :prefix)` assertions ride every test leg, proving the compiled prefix appears on selects/joins/`insert_all`/Multi (with a negative "no bare `parapet_incidents`" assertion under the prefixed leg) and `__schema__(:prefix)` matches across all six schemas.

### Generators & Library Migrations (`GEN`)

- [x] **GEN-01**: A dedicated, first-ordered `*_create_parapet_schema` migration emits reversible `CREATE SCHEMA IF NOT EXISTS parapet` / `DROP SCHEMA IF EXISTS parapet` (non-cascading).
- [x] **GEN-02**: `mix parapet.gen.spine` and `gen.archive_indexes` stamp a literal `prefix:` on every `create table`, each `references/2` (its own prefix), and every index; FK constraint names stay unchanged (asserted).
- [x] **GEN-03**: Generators write `config :parapet, :schema_prefix, "parapet"` via Igniter `configure_new/5` (never clobber an adopter's value); a `--schema` vs existing-config conflict warns rather than crashes.
- [x] **GEN-04**: `--schema parapet` and `--no-create-schema` flags (Oban-verbatim); `--no-create-schema` omits the schema migration, keeps tables prefixed, and prints the exact `CREATE SCHEMA` + `GRANT` remediation for the DBA.
- [x] **GEN-05**: One shared prefix resolver (precedence `flag > existing config > default`) is used by `gen.spine`, `gen.archive_indexes`, and the `install` orchestrator.
- [x] **GEN-06**: Parapet's five committed library migrations and the demo migrations create their tables under the schema; the demo's plain `mix ecto.migrate` self-creates the schema (no `--prefix` needed).
- [x] **GEN-07**: Generator-output tests extend the AST substring asserts with a `prefix:` count-guard, add one small golden file for the schema migration only, and cover the `--no-create-schema` / existing-config branches.

### Upgrade Path (`UPG`)

- [x] **UPG-01**: Track A (stay on `public`) is documented and pinned by a test proving `schema_prefix: nil` emits unprefixed SQL with green queries.
- [x] **UPG-02**: `mix parapet.gen.schema.move` generates a reversible migration: `SET LOCAL lock_timeout = '5s'`, `CREATE SCHEMA IF NOT EXISTS parapet` (omitted under `--no-create-schema`), and `ALTER TABLE … SET SCHEMA` for all six tables in one transaction; `down` restores `public` and never `DROP SCHEMA`.
- [x] **UPG-03**: The move task runs pre-flight catalog detections — abort on missing/renamed spine tables, warn on inbound app FKs/views, and refuse to emit a second move migration if one exists.
- [x] **UPG-04**: A Track B round-trip test (against a throwaway DB, cloning the `add_lease_until_backfill_test.exs` pattern) proves: created in `public` → up → resolves under `parapet` with FK cascade + partial indexes intact → down → restored to `public`.
- [x] **UPG-05**: Upgrading an existing adopter never forces a schema migration — the default flips for new installs only.

### Doctor / Diagnostics (`DOCTOR`)

- [x] **DOCTOR-01**: A `mix parapet.doctor` check compares the runtime `:schema_prefix` config against the compiled `@schema_prefix` and fails (CI-grade under `--ci`) on drift with the `mix deps.compile parapet --force` remediation; it also verifies the configured schema exists.

### Test Infrastructure (`TEST`)

- [x] **TEST-01**: Add an env-driven `config/config.exs` (reading `PARAPET_SCHEMA_PREFIX`, default-on `parapet`) so `compile_env` has a source; confirm `config/` is excluded from the Hex `package.files`.
- [x] **TEST-02**: Hand-qualify `test/support/concurrency_bootstrap.ex` — add `CREATE SCHEMA IF NOT EXISTS`, qualify every `CREATE TABLE`/`REFERENCES`/`ON`/`TRUNCATE` to the prefixed schema (index *targets*, not index *names*); keep `schema_migrations` in `public`.
- [x] **TEST-03**: A CI matrix axis `schema_prefix: ['parapet','public']` recompiles (`mix compile --force`) and reruns the full suite per value, with the `_build` cache key namespaced by prefix to prevent a silent false-green. This is the honest proof of "green under `parapet` AND under `nil`."

### Documentation (`DOC`)

- [x] **DOC-01**: New `docs/upgrade-1.x.md` — TL;DR "your data does not move unless you choose", Track A/B copy-paste (each config block followed by the `--force` recompile line), least-privilege GRANTs, recompile-order, rollback incl. half-migrated recovery, FAQ.
- [x] **DOC-02**: `docs/deployment.md` schema subsection, a `README.md` note, and a routing pointer from `docs/migration-v1.md` (the audited #1 gap).

### Contract Safety (`SAFE`)

- [x] **SAFE-01**: `mix verify.public_api` stays green with zero `--write` — the prefix is a module attribute, not an export.
- [x] **SAFE-02**: The telemetry contract test stays green and no `[:parapet, :schema, …]` event is added; confirm Ecto query telemetry `:source` (bare table name) is unaffected.
- [x] **SAFE-03**: Compile-out-clean (`--warnings-as-errors`, `--no-optional-deps`) holds, and the demo smoke lane asserts `mix ecto.migrate` lands all six tables in `parapet` and an evidence round-trip carries `Ecto.get_meta(record, :prefix) == "parapet"`.
- [ ] **SAFE-04**: A `feat` CHANGELOG entry frames the change as additive with a "No action required for existing installs" banner (semver minor) plus a matching release-note callout.

## Future Requirements

Deferred to later milestones (the approved v1.7→v1.9 roadmap).

### CI/CD (v1.8)

- **CI-01**: Dialyzer PLT caching, `concurrency: cancel-in-progress` (PR), lint-once, `mix ci` alias, `Process.sleep` removal, 3-OTP matrix → main+nightly. *(Note: v1.7's dual-prefix matrix interacts with the v1.8 pipeline reshape — sequence accordingly.)*

### Quality Hardening (v1.9)

- **TELEM-01**: Telemetry drift gate (`telemetry_stable.json` mirroring `public_api_stable.json`).
- **REFACTOR-01**: Decompose `operator.ex` god-module behind the frozen Stable surface.
- **A11Y-01**: Playwright + axe-core a11y lane; ExUnit-pin v1.6 `override_closeout` gaps; failure-injection tests.

## Out of Scope

Explicitly excluded for v1.7. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Runtime `prefix:` repo option | Read/write precedence asymmetry causes split-brain — compile-time `@schema_prefix` only |
| Connection `search_path` switching | Would break `public`-resident extensions (`citext`, `uuid-ossp`, `pg_trgm`); Rails Apartment abandoned it over leak/pooling bugs |
| Forced schema migration on upgrade | Existing adopters stay opt-in; default flips for new installs only |
| Schema-per-tenant multitenancy | Multi-tenant scoping remains deferred (PROJECT.md Out of Scope) — this is single fixed-schema isolation, not per-org |
| Renaming spine tables (`parapet_*` → unprefixed) | Needless breaking change; the table name stays `parapet_incidents` inside the `parapet` schema |
| Moving `schema_migrations` into `parapet` | It's migration infra, not a spine table; keep Ecto's default in `public` |
| Public API / telemetry contract changes | The prefix is an internal DB detail; both contracts stay frozen as a done-criterion |
| A `[:parapet, :schema, …]` telemetry event for the move | Telemetry is frozen; the move is a one-shot migration, not a runtime operation |

## Traceability

One phase per requirement. v1.7 phases continue from v1.6 (which ended at Phase 50), so v1.7 spans Phases 51–56.

| Requirement | Phase | Status |
|-------------|----------|---------|
| PREFIX-01 | Phase 51 | Complete |
| PREFIX-02 | Phase 51 | Complete |
| PREFIX-03 | Phase 51 | Complete |
| PREFIX-04 | Phase 51 | Complete |
| TEST-01 | Phase 51 | Complete |
| TEST-02 | Phase 51 | Complete |
| PROP-01 | Phase 52 | Complete |
| PROP-02 | Phase 52 | Complete |
| PROP-03 | Phase 52 | Complete |
| TEST-03 | Phase 52 | Complete |
| GEN-01 | Phase 53 | Complete |
| GEN-02 | Phase 53 | Complete |
| GEN-03 | Phase 53 | Complete |
| GEN-04 | Phase 53 | Complete |
| GEN-05 | Phase 53 | Complete |
| GEN-06 | Phase 53 | Complete |
| GEN-07 | Phase 53 | Complete |
| UPG-01 | Phase 54 | Complete |
| UPG-02 | Phase 54 | Complete |
| UPG-03 | Phase 54 | Complete |
| UPG-04 | Phase 54 | Complete |
| UPG-05 | Phase 54 | Complete |
| DOCTOR-01 | Phase 54 | Complete |
| DOC-01 | Phase 55 | Complete |
| DOC-02 | Phase 55 | Complete |
| SAFE-03 | Phase 55 | Complete |
| SAFE-01 | Phase 56 | Complete |
| SAFE-02 | Phase 56 | Complete |
| SAFE-04 | Phase 56 | Pending |

**Coverage:**

- v1.7 requirements: 29 total
- Mapped to phases: 29 ✓ (Phases 51–56)
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-29*
*Last updated: 2026-06-29 after roadmap creation (Phases 51–56, 29/29 mapped)*
