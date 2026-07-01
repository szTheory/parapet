# Phase 54: Upgrade Path & Doctor - Context

**Gathered:** 2026-07-01 (assumptions mode + deep decision-fork research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Existing adopters get two tested, opt-in upgrade tracks — **stay on `public`** (Track A) or a
**reversible single-transaction `SET SCHEMA` move** (Track B via `mix parapet.gen.schema.move`) —
plus a `mix parapet.doctor` preflight that catches the compile-time recompile footgun (runtime
config vs compiled `@schema_prefix` drift + schema existence).

**Requirements:** UPG-01, UPG-02, UPG-03, UPG-04, UPG-05, DOCTOR-01.

**In scope:** the move generator + its emitted migration; the migrate-time pre-flight guard; the
Track B round-trip test; the Track A pin test; the UPG-05 fitness function; the new doctor `schema`
check. **Out of scope (later phases):** the full `docs/upgrade-1.x.md` prose (Phase 55); the
CHANGELOG/release framing (Phase 56); the demo-app smoke lane (Phase 55). The *truth* those docs
must tell is fixed here (D-18).
</domain>

<decisions>
## Implementation Decisions

> Derived from 5 parallel deep-research forks (one per gray area), each applying idiomatic
> Elixir/Ecto/Igniter practice, peer-library lessons (Oban, ash_postgres, strong_migrations,
> Django, Rails), DBA/SRE, and adopter-DX/least-surprise lenses. All five are mutually coherent.

### A. Doctor schema check — DOCTOR-01
- **D-01:** Add **one** new static check named `"schema"` to `@static_checks` in
  `lib/mix/tasks/parapet.doctor.ex` — NOT a new mix task, NOT two checks (`schema_drift` +
  `schema_exists`), NOT folded into the opt-in `cluster` mode. It honors the existing
  `%{status: :info|:warn|:error|:skip, messages: [...]}` contract, so it inherits `--ci`
  threshold-flip, `findings_exit_code/2`, JSON output, and `parse_requested_checks` allow-listing
  with zero framework changes. Rationale: drift + existence answer one operator question ("will my
  spine reads/writes land where I think?"); Django's single graded `check` surface is the precedent.
  Drift must stay in the **default static suite** (not `cluster`) so `mix parapet.doctor --ci` in CI
  catches it without a live DB.
- **D-02:** The check folds two signals into one finding (status = max severity, `cond` rollup like
  `check_cluster_static`): **(1) drift** — compare
  `Parapet.Spine.Schema.normalize(Application.get_env(:parapet, :schema_prefix))` against compiled
  `Parapet.Spine.Schema.__prefix__()`; disagreement → `:error` (order 2 ≥ `--ci` warn threshold ⇒
  exit 1). BOTH sides MUST run through `normalize/1` so `nil`/`""`/`"public"` collapse equal (else
  compiled `nil` vs runtime `"public"` false-positives). **(2) schema existence** — probe the live
  repo with parameterized `SELECT to_regnamespace($1) IS NOT NULL` (injection-safe; returns NULL
  rather than erroring on an absent schema); schema positively absent → `:error`.
- **D-03:** The existence half **degrades to `:skip`, never `:error`**, when the repo isn't running —
  guard via `repo = Application.get_env(:parapet, :repo); is_nil(repo) or Process.whereis(repo) == nil`
  (the exact `check_recovery` idiom at `parapet.doctor.ex:357`), and wrap the probe in `try/rescue`
  so a mid-run DB error also degrades to `:skip`. This prevents spurious CI failures in a DB-less
  doctor run **while drift still fails**. Exit code 2 stays reserved for probe execution failure; the
  schema check introduces no new exit code. (Reject the `doctor_cluster_probe` injection/exit-2
  pattern — too heavyweight and wrong severity for existence.)
- **D-04:** Remediation microcopy names the exact fix inline (strong_migrations DX). Drift:
  `"Config drift: runtime :schema_prefix is <X> but Parapet was compiled with <Y>. Spine reads/writes
  may target the wrong schema. Recompile the library: mix deps.compile parapet --force"`. Missing
  schema: `"Schema <X> does not exist in the configured repo (<repo>). Create it before migrating:
  run the CREATE SCHEMA step from mix parapet.gen.spine, then mix ecto.migrate"`. Skip:
  `"Schema-existence check skipped: the Parapet repo is not running. Start the OTP app (or run
  mix parapet.doctor cluster) to verify schema <X> exists."`
- **D-05 (load-bearing):** This doctor check is **REQUIRED, not optional** — it is the primary
  detection backstop for the UPG-05 upgrade footgun (D-17). It moves the compiled-vs-data split
  *left*, from "loud failure at first prod query" to "caught by `mix parapet.doctor --ci` in the
  upgrade branch." `docs/migration-v1.md` already tells adopters to run doctor on upgrade — this
  check makes that step meaningful.

### B. Move task & emitted migration — UPG-02
- **D-06:** New `mix parapet.gen.schema.move` as `use Igniter.Mix.Task`, `info/2` mirroring
  `gen.spine` **verbatim**: `schema: [schema: :string, create_schema: :boolean]`, defaults
  `[schema: "parapet", create_schema: true]`, `aliases: [s: :schema]`, `group: :parapet`; target
  prefix via `Parapet.Spine.Schema.resolve_prefix(igniter)` interpolated as a **generate-time
  literal** into the heredoc (Ph53 D-01/D-09 — never a runtime `__prefix__/0` call in adopter
  output). Nil/legacy leg (`--schema public` → `resolved == nil`) emits **nothing** + a "tables
  already in public; no move needed" notice (Ph53 D-04 zero-diff principle).
- **D-07:** Emit exactly ONE migration via `Igniter.Libs.Ecto.gen_migration/4` with a **real current
  timestamp** (do NOT override `:timestamp`) — NOT the sentinel `"00000000000000"` (reserved for
  schema *creation*, sorts first). A move must sort AFTER the adopter's existing spine-table
  migrations or `SET SCHEMA` hits not-yet-created tables. Fixed deterministic module/name
  `move_parapet_spine_to_schema` so the second-move guard (D-11) can find it.
- **D-08:** Migration body:
  - `after_begin/0` sets `SET LOCAL lock_timeout TO '5s'` (Ecto-blessed idiom; one transaction-scoped
    setting bounds every `SET SCHEMA`'s ACCESS EXCLUSIVE lock *acquisition* so a blocked move fails
    fast instead of queuing prod traffic behind the FIFO lock queue).
  - Do **NOT** set `@disable_ddl_transaction` / `@disable_migration_lock` — both would break the
    single-transaction atomicity guarantee and no-op `SET LOCAL`.
  - `up`: [migrate-time abort guard, D-10] → [inbound-FK/view advisory NOTICE, D-10] → conditional
    `execute("CREATE SCHEMA IF NOT EXISTS <resolved>")` (first, so the target exists; omitted under
    `--no-create-schema`, D-12b) → **six explicit, fully-qualified** lines
    `execute("ALTER TABLE public.<t> SET SCHEMA <resolved>")`.
  - `down`: six explicit `execute("ALTER TABLE <resolved>.<t> SET SCHEMA public")` in reverse (LIFO)
    order, and **NEVER `DROP SCHEMA`** (fail-closed, matches Ph53 D-14; the possibly-empty schema is
    the sentinel migration's `down` — or a DBA — to remove; other Parapet objects may live there).
  - **Six explicit lines, not a `for`-comprehension:** the generated migration is read/audited in a
    prod PR; `grep parapet_incidents migration.exs` must return the moved line. (The abort guard's
    `DO`-block still lists all six in a SQL `ARRAY`.)
- **D-09:** **Fully-qualify** source tables — `public.<t>` on up, `<resolved>.<t>` on down — never
  rely on `search_path`. A migration outlives its authoring env; a bare name is silently wrong under
  an operator whose `search_path` already lists `parapet` first (Rails SET-SCHEMA playbook confirms
  this up/down asymmetry). The six tables: `parapet_action_items`, `parapet_incidents`,
  `parapet_timeline_entries`, `parapet_tool_audits`, `parapet_system_events`, `parapet_action_claims`.

### C. Pre-flight catalog detection — UPG-03
- **D-10:** The **missing/renamed spine-table ABORT is authoritative at MIGRATE time**, emitted INTO
  the migration body as a leading `DO $$ ... RAISE EXCEPTION ... $$` guard using
  `to_regclass('public.' || quote_ident(t))` over the six tables; it raises **before** any
  `SET SCHEMA`, inside the migration transaction (nothing moves on failure). Rationale: the DB that
  matters is the *target* (prod) at migrate time, not the dev laptop at generate time — a generated
  file runs weeks later in CI→staging→prod, possibly by another operator (peer precedent: Oban's
  migrate-time version guard). **Inbound app FK / view detection is a non-blocking WARN** (PG keeps
  cross-schema FKs valid and auto-moves FKs where both endpoints move; only views/rules referencing
  spine tables by unqualified name may silently rebind) — emitted as a `RAISE NOTICE` DO-block over
  `information_schema.view_table_usage`, mirrored by a best-effort generate-time `Igniter.add_warning`.
- **D-11:** The **"refuse a second move migration" guard is at GENERATE time** via Igniter's built-in
  mechanism — the fixed module name (D-07) + `on_exists: {:error, "<points at existing file>"}`
  (`gen_migration` already pulls existing migrations into the source set via `include_glob` and
  checks `module_exists`). Chosen over catalog-state detection because file/module detection is
  **rollback-invariant**: after `ecto.rollback` the tables are back in `public` but the file
  correctly still exists (tracked history); a catalog check would false-positive and permit a
  duplicate. Safe to fail-hard at generate time because it reads tracked *source files* (identical in
  every environment — no dev/prod mismatch).
- **D-12:** **(a)** A **best-effort, non-fatal** generate-time probe via `Ecto.Migrator.with_repo/2`
  MAY check the dev DB for the six tables and `add_notice`/`add_warning` for fast laptop feedback —
  but it **NEVER aborts generation** (a dev-DB-vs-prod-DB mismatch makes a wrong generate-time abort
  the single worst outcome). The authoritative gate is always the migrate-time guard (D-10);
  generate-time is an advisory lint layer only. **(b) `--no-create-schema` composition:** omit the
  `CREATE SCHEMA` line from `up` and emit the shared Ph53-D-15 DBA least-privilege notice
  (`USAGE` + `CREATE ON SCHEMA`, `AUTHORIZATION` happy-path; note `SET SCHEMA` into a target needs
  `CREATE` *on the target schema*) via `Igniter.add_notice`, reworded for the move context. Extract
  the shared notice body into ONE private helper both `gen.spine` and `gen.schema.move` call (D-00
  single-source spirit).

### D. Round-trip test — UPG-04
- **D-13:** Clone `test/parapet/repo/migrations/add_lease_until_backfill_test.exs`:
  `use ExUnit.Case, async: false`, `@tag :unboxed`, a private non-sandbox `MigrationTestRepo` on
  `DBConnection.ConnectionPool` (Ecto.Migrator needs ≥2 connections; the sandbox can't provide them)
  + a bare `Postgrex` conn for out-of-transaction assertions, driven by `Code.require_file` of a
  **committed migration fixture** + `Ecto.Migrator.up/4`/`down/4`. Do **NOT** generate the migration
  live in this test (couples the DB test to file-writing + pre-flight, adds flakiness). Generated
  *output* correctness is a **separate, DB-less generator golden test** that snapshots the SAME
  fixture file — so the mechanics test and the output test cannot drift.
- **D-14:** Use a **dedicated throwaway DB** `parapet_schema_move_roundtrip_test` created/dropped via
  `Ecto.Adapters.Postgres.storage_up/1` + `storage_down/1` in `setup_all` (same PG server/port as
  `ConcurrencyRepo.database_config()` — no Docker, no extra service, sub-second, respects the
  no-extra-infra constraint). NOT the shared `parapet_concurrency_test`: a whole-schema move is too
  destructive; a mid-test failure (e.g. `lock_timeout` abort) would leave the spine in `parapet` and
  poison every later `:unboxed` module. A dedicated DB makes teardown a single `storage_down`
  (obviously-correct — the DX/SRE win).
- **D-15:** The test stands up its **OWN isolated fixture spine in `public`** (a small hand-written
  DDL fragment mirroring the FK + partial-index shape — `parapet_incidents` parent +
  `parapet_action_claims` child with an `ON DELETE CASCADE` FK and the `WHERE status = 'claimed'`
  partial index) and moves **those** — never the canonical bootstrap tables. Because the fixture is
  always built in `public` and the migration uses literal schema names, the test runs
  **byte-identically on BOTH CI legs** (`parapet` + `public`/nil) and touches zero shared state.
- **D-16:** Assertions query the catalog and **re-create nothing** (PG moves indexes/constraints/FKs
  with byte-identical names — established research): **(a)** table membership via `pg_class` +
  `pg_namespace` (`parapet` after up, `public` after down); **(b)** FK cascade *behavior* — insert
  parent + child, delete parent, assert the child cascaded (beats a pure-catalog FK check);
  **(c)** partial index byte-identical name + `pg_get_expr(indpred, indrelid)` still renders the
  predicate, under `parapet` after up; **(d)** after down, all six back in `public` AND the `parapet`
  schema still exists but is empty of spine tables (proves the deliberate no-`DROP SCHEMA`).
  `@tag :unboxed`, `async: false`, runs in the normal `mix test` lane on both legs — no new CI wiring
  (`:unboxed` is only a sandbox marker, excluded nowhere).

### E. Track A pin + UPG-05 — UPG-01, UPG-05 (the honest truth)
- **D-17 (TRUTH, load-bearing):** There is **no runtime install-detection and there must not be one**
  — the default is `Application.compile_env(:parapet, :schema_prefix, "parapet")` (`schema.ex:81`),
  unconditionally `"parapet"`. "Default flips for new installs only" describes **who benefits**, not
  a code gate. UPG-05's literal promise is true ONLY as **"no data migration is ever auto-run"**; it
  is FALSE if read as "a do-nothing upgrader is unaffected." **Track A REQUIRES the existing adopter
  to explicitly set `config :parapet, schema_prefix: nil` + `mix deps.compile parapet --force`.** A
  do-nothing upgrader gets compiled `@prefix == "parapet"` pointed at `public` data → **loud
  `relation "parapet.parapet_incidents" does not exist` on first spine query** (NOT silent
  corruption — the `parapet` schema simply won't exist). The Elixir `compile_env` boot-check does
  **not** catch this (it fires only for *explicitly-set* config that drifts, never an unset key whose
  library default changed) — which is exactly why the doctor check (D-05) is load-bearing.
- **D-18:** Honest upgrade framing (truth fixed here; Phase 55 doc + Phase 56 CHANGELOG own final
  copy): **additive minor**, lead with **"your data never moves automatically"** (true, reassuring),
  immediately followed by **"action required for existing adopters: add
  `config :parapet, schema_prefix: nil` + recompile to stay on `public`, then run
  `mix parapet.doctor`."** NOT "no action required." Because Parapet inverts the ecosystem norm
  (non-`public` default + compile-time config, unlike Oban's public-default runtime config), it owes
  adopters a **louder** upgrade story than Oban ever needed.
- **D-19:** UPG-01 Track A pin — a named `describe "UPG-01 Track A"` block guarded by
  `if is_nil(@prefix)` (riding the existing nil CI leg) in
  `test/parapet/spine/prefix_propagation_test.exs`, asserting **both**: (1) a legible
  `Ecto.Adapters.SQL.to_sql/3` assertion that the generated SQL carries a **bare unqualified** table
  name and **no** schema qualifier (the load-bearing "proving unprefixed" artifact UPG-01's wording
  demands — the green suite alone is not legible proof); (2) a live write-path round-trip asserting
  `Ecto.get_meta(record, :prefix) == nil` + green read-back (covers `Multi`/`insert_all` paths
  `to_sql` structurally can't reach). Do NOT build a new repo-booting integration test — the
  concurrency harness + dual-prefix matrix already exist.
- **D-20:** UPG-05 pin — a **regex fitness function** `test/parapet/upgrade_never_forces_move_test.exs`
  scanning `parapet.install.ex` / `parapet.gen.spine.ex` / `parapet.gen.archive_indexes.ex` and
  asserting they NEVER reference `parapet.(gen.)?schema.move` or the move module — statically proving
  the installer path can never auto-chain a data migration (mirrors the existing PROP-02
  `schema_prefix_guard_test.exs` pattern; goes red with a teaching message the day someone wires it
  up). Plus one explicit named test that `Parapet.Spine.Schema.resolve_prefix(nil, nil) ==
  {:ok, "parapet"}` pins the "default = parapet for new installs" literal.

### Claude's Discretion
- Exact `check_schema/0` message strings/format and whether existence additionally verifies the six
  spine tables *resolve under* the compiled prefix (stronger than schema-existence alone; D-02 covers
  the DOCTOR-01 literal requirement — table-location is a discretionary strengthening).
- The `up`/`down` two-arg `execute/2` symmetric form vs separate `up`/`down` blocks (D-08 shows
  separate blocks so the "no DROP SCHEMA" comment lands where a reviewer looks; planner's call).
- Fixture-spine table count in the round-trip test (2–3 representative tables covering parent+child
  FK + partial index is sufficient; all six is acceptable but heavier).
- Whether the generate-time best-effort probe (D-12a) ships in v1.7 or is deferred (the migrate-time
  guard D-10 is the requirement; D-12a is a DX nicety).
- Exact `RAISE NOTICE` / `add_warning` wording for the inbound-FK/view advisory.

### Folded Todos
None — `todo.match-phase 54` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

**v1.7 milestone research (authoritative design docs — the forks cited these directly):**
- `.planning/research/v1.7/00-SYNTHESIS.md`
- `.planning/research/v1.7/01-PREFIX-MECHANISM.md`
- `.planning/research/v1.7/02-GENERATOR-DX.md`
- `.planning/research/v1.7/03-UPGRADE-PATH.md` (§3 = the move-migration body this phase emits)
- `.planning/research/v1.7/04-TEST-STRATEGY.md` (§6 = Track B round-trip skeleton + F11–F14 footguns)
- `.planning/research/v1.7/05-ECOSYSTEM-DX-COHERENCE.md`

**Prior locked phase context (composition constraints):**
- `.planning/phases/53-generators-library-migrations/53-CONTEXT.md` — D-13/D-14 sentinel + non-cascading
  DROP; D-15 `--no-create-schema` + DBA notice; D-01/D-04/D-09 generate-time literal + nil-leg zero-diff.
- `.planning/phases/52-propagation-proof-guards-ci-dual-prefix-matrix/52-CONTEXT.md` — dual-prefix CI
  matrix; Oban/Triplex/apartment lessons; why Parapet's compile-time prefix needs louder guards.
- `.planning/phases/51-prefix-core-test-seam/51-CONTEXT.md` — default + `normalize/1` contract;
  D-08 reserved the doctor drift check for this phase.

**Requirements & roadmap:**
- `.planning/ROADMAP.md` — Phase 54 goal + Success Criteria (lines ~123–135).
- `.planning/REQUIREMENTS.md` — UPG-01…UPG-05, DOCTOR-01.

**Source integration points:**
- `lib/mix/tasks/parapet.doctor.ex` — the check framework the `schema` check joins (`@static_checks:22`,
  `check_recovery:357` skip idiom, `findings_exit_code:516`, `--ci` at `:54`).
- `lib/mix/tasks/parapet.gen.spine.ex` — the Igniter task template + migration-body heredoc + DBA notice.
- `lib/parapet/spine/schema.ex` — `__prefix__/0` (compiled), `normalize/1`, `resolve_prefix/1,2`.
- `test/parapet/repo/migrations/add_lease_until_backfill_test.exs` — round-trip clone target.
- `test/parapet/spine/prefix_propagation_test.exs` — where the Track A pin lands.
- `test/parapet/schema_prefix_guard_test.exs` — the fitness-function pattern for the UPG-05 pin.
- `test/support/concurrency_bootstrap.ex`, `test/support/concurrency_repo.ex` — DB config + fixture DDL source.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Doctor check framework** (`parapet.doctor.ex`): mature `@static_checks` + `run_static_check/1`
  dispatch + `%{status:, messages:}` contract + `@severity_order` + `--ci`/`--threshold` +
  `findings_exit_code/2` + JSON/colorized printers. The `schema` check is a drop-in (~40 lines, no
  framework change). The `check_recovery` `Process.whereis == nil → :skip` guard is the exact
  degrade pattern for the DB-needed existence probe.
- **`gen.spine` Igniter task**: `info/2` flag block, `resolve_prefix(igniter)`, `gen_migration/4`
  with `on_exists:` + `body:` heredoc, `maybe_emit_dba_notice`. The move task is a sibling; the DBA
  notice becomes a shared helper.
- **`add_lease_until_backfill_test.exs`**: solves Ecto.Migrator's 2-connection non-sandbox need +
  out-of-transaction DDL via bare Postgrex + idempotent teardown. The round-trip test clones it.
- **`resolve_prefix/2` + `normalize/1` + `__prefix__/0`** (`schema.ex`): the single prefix source;
  the doctor drift check and Track A test read straight through it.

### Established Patterns
- **Compile-time prefix, generate-time literal:** adopter migrations bake a literal (Ph53 D-01);
  Parapet's own migrations reference `__prefix__()` (Ph53 D-11). The move task bakes a literal.
- **Dual-prefix CI matrix (Ph52):** the whole suite recompiles + runs under both `parapet` and nil
  legs. The Track A test rides the nil leg; the round-trip test is engineered to be leg-agnostic.
- **Fail-closed schema teardown (Ph53 D-14):** non-cascading `DROP SCHEMA` only in the sentinel's
  `down`; the move's `down` never drops the schema.
- **Fitness functions:** `schema_prefix_guard_test.exs` (PROP-02) greps source for banned patterns —
  the UPG-05 pin reuses this shape.

### Integration Points
- `parapet.doctor.ex` gains a `schema` entry in `@static_checks` + `check_schema*/1` privates.
- New `lib/mix/tasks/parapet.gen.schema.move.ex` (Igniter task) + a committed migration fixture under
  `priv/repo/migrations/` for the round-trip test to `Code.require_file`.
- New tests: round-trip (`test/parapet/repo/migrations/`), Track A pin (extend
  `prefix_propagation_test.exs`), UPG-05 fitness function, generator golden test.
- Shared DBA-notice helper reused by `gen.spine` + `gen.schema.move`.
</code_context>

<specifics>
## Specific Ideas

- **Doctor existence probe:** `SELECT to_regnamespace($1) IS NOT NULL` — the idiomatic, injection-safe,
  single-round-trip Postgres schema-existence test.
- **Migrate-time abort guard** (emitted into the migration): `DO $$ ... to_regclass('public.'||quote_ident(t))
  IS NULL ... RAISE EXCEPTION ... $$` over the six tables, before any `SET SCHEMA`.
- **Second-move refuse:** `on_exists: {:error, "...run mix ecto.migrate to apply it, or delete it to
  regenerate. Refusing to emit a second move migration."}`.
- **Track A proof:** `Ecto.Adapters.SQL.to_sql(:all, ConcurrencyRepo, query)` then `refute sql =~
  ~s("parapet".)` + `assert Ecto.get_meta(record, :prefix) == nil`.
- **`lock_timeout` via `after_begin/0`:** `def after_begin, do: repo().query!("SET LOCAL lock_timeout TO '5s'")`.
</specifics>

<deferred>
## Deferred Ideas

- **Full `docs/upgrade-1.x.md` prose + demo-app smoke lane** → Phase 55 (this phase fixes the *truth*
  the doc must tell: D-17/D-18).
- **CHANGELOG "action-required" banner + release framing** → Phase 56 (truth fixed here: D-18).
- **Doctor existence check strengthening** (verify the six spine tables resolve under the compiled
  prefix, not just that the schema exists) — discretionary; DOCTOR-01's literal requirement is met by
  schema-existence (D-02).
- **Generate-time best-effort pre-flight probe (D-12a)** — may ship in v1.7 or defer; the migrate-time
  guard (D-10) is the actual requirement.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 54.
</deferred>
