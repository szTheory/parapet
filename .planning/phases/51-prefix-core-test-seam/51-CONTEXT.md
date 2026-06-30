# Phase 51: Prefix Core & Test Seam - Context

**Gathered:** 2026-06-29 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the compile-time schema-prefix **core** and the **test seam** that lets the suite run
under the prefix — nothing more. In scope: the shared `use Parapet.Spine.Schema` macro, switching
all six spine schemas to it, the single-sourced normalization (`nil`/`""`/`"public"` ⇒ unprefixed),
the runtime `schema_prefix/0` helper, the net-new `config/config.exs` env seam, and hand-qualifying
`test/support/concurrency_bootstrap.ex` so the full suite is green under `schema_prefix: parapet`.

**Out of scope (later phases):** propagation regression tests + runtime-`prefix:` ban guard +
dual-prefix CI matrix (Phase 52); generators, the `CREATE SCHEMA` migration, and **prefixing the
five committed `priv/repo/migrations/*.exs` library migrations** (Phase 53, GEN-06); upgrade
tracks + doctor (Phase 54); demo/docs (Phase 55); contract/release hardening (Phase 56).

Requirements: PREFIX-01, PREFIX-02, PREFIX-03, PREFIX-04, TEST-01, TEST-02.
</domain>

<decisions>
## Implementation Decisions

### Shared schema macro (PREFIX-01)
- **D-01:** Create `Parapet.Spine.Schema` with a `__using__/1` macro that `use Ecto.Schema`,
  `import Ecto.Changeset`, and sets `@primary_key {:id, :binary_id, autogenerate: true}`,
  `@foreign_key_type :binary_id`, `@schema_prefix Parapet.Spine.Schema.__prefix__()`. Mirror the
  `defmacro __using__` mechanics already used in `runbook.ex`/`recovery.ex`/`probe.ex` (house style);
  the schema-base concept itself is net-new (no existing macro wraps `Ecto.Schema`).
- **D-02:** Switch all six spine schemas from `use Ecto.Schema` → `use Parapet.Spine.Schema`, deleting
  the now-duplicated `@primary_key`/`@foreign_key_type`/`import Ecto.Changeset` lines from each. The six:
  `Incident` (`lib/parapet/spine/incident.ex`, `parapet_incidents`), `ActionItem` (`parapet_action_items`),
  `SystemEvent` (`parapet_system_events`), `ToolAudit` (`parapet_tool_audits`), `TimelineEntry`
  (`parapet_timeline_entries`), `ActionClaim` (`parapet_action_claims`). This is pure subtraction —
  all six already declare the identical four lines, so behavior is unchanged.
- **D-03:** Do **not** apply the macro to `lib/parapet/operator/action_payload.ex` — it is a non-table
  operator schema, not one of the six spine tables. Scope the change to `lib/parapet/spine/` only.

### Prefix source + normalization (PREFIX-02, PREFIX-03)
- **D-04:** `__prefix__/0` reads `Application.compile_env(:parapet, :schema_prefix, "parapet")` and normalizes:
  `p in [nil, "", "public"] -> nil`; binary -> itself; atom -> `Atom.to_string/1`. `nil`/`""`/`"public"`
  all yield byte-identical legacy (unprefixed) SQL.
- **D-05:** The normalization rule is **single-sourced in intent but physically duplicated**: it lives in
  `__prefix__/0` AND (necessarily, because it runs pre-compile) in `config/config.exs`. A unit test asserts
  the two copies agree on `["parapet","","public",nil,"custom"]`. `__schema__(:prefix)` must return `"parapet"`
  for all six schemas under the default config.

### Config seam (TEST-01)
- **D-06:** `config/` does not exist today — create a net-new `config/config.exs` that reads
  `PARAPET_SCHEMA_PREFIX` (default-on `"parapet"`) so `compile_env` has a real override source. Apply the
  same `nil|""|"public" ⇒ nil` normalization at the config layer.
- **D-07:** Do **not** add `config` to `mix.exs` `package.files` (`mix.exs:42-44`). The whitelist already omits
  it, so the dev config never ships to adopters — confirm this stays true (the only required action is the
  negative one of not touching the list).

### Runtime prefix helper (PREFIX-04)
- **D-08:** Add a runtime `schema_prefix/0` helper colocated with `repo/0` in `Parapet.Evidence`
  (`lib/parapet/evidence.ex:22`), reading runtime config (mirrors `repo/0`'s `Application.get_env` shape).
  This is distinct from the compile-time `__prefix__/0`; the two must agree (the agreement is what the
  Phase-54 doctor drift check later verifies). Used by runtime-only sites (generators, raw SQL) in later phases.

### Test bootstrap qualification (TEST-02)
- **D-09:** Hand-qualify `test/support/concurrency_bootstrap.ex`: prepend `CREATE SCHEMA IF NOT EXISTS`,
  qualify every `CREATE TABLE` (6), inline `REFERENCES` (4), `CREATE INDEX ... ON <target>` (11 — qualify the
  *target table*, not the index name), and the `@tables`-driven `TRUNCATE` to the prefixed schema. Parameterize
  qualification by the **same resolved prefix the macro uses** (not a hardcoded `"parapet"`), so the `public`
  leg stays unprefixed. Leave `schema_migrations` in `public`.
- **D-10:** Done-criterion for this phase: the full suite is green under `schema_prefix: parapet`. (The honest
  dual-leg proof — green under both `parapet` AND `public` via a recompiling CI matrix — is Phase 52 / TEST-03,
  not here.)

### Claude's Discretion
- Exact module/function placement of the macro file (`lib/parapet/spine/schema.ex` is the natural home).
- Whether `__prefix__/0` exposes the compiled value publicly now or in Phase 54 (the doctor check needs it;
  exposing it here is harmless and avoids a later edit — planner's call).

### Boundary call (resolved, not a question for the user)
- **D-11:** **Library-migration prefixing is OUT of Phase 51.** The five committed `priv/repo/migrations/*.exs`
  get their `prefix:` in **Phase 53 (GEN-06)** per the authoritative REQUIREMENTS/ROADMAP mapping. The
  synthesis §7 phase-sketch listed "library migrations prefixed" under phase 1, but that predates the refined
  requirement mapping; the roadmap wins. (User confirmed "Yes, proceed" on 2026-06-29.)
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.7/00-SYNTHESIS.md` — §1 (locked decisions), §2 (the mechanism + the exact
  `Parapet.Spine.Schema` macro code), §6 (testing prerequisites, bootstrap qualification rule).
- `.planning/research/v1.7/01-PREFIX-MECHANISM.md` — full prefix-mechanism dimension (compile-time rationale,
  zero-call-site propagation).
- `.planning/research/v1.7/04-TEST-STRATEGY.md` — test-infra/contract-safety dimension (config seam,
  bootstrap qualification, the `_build` cache-namespacing footgun for Phase 52).
- `.planning/REQUIREMENTS.md` — v1.7 §"Schema Prefix Core (PREFIX)" + "Test Infrastructure (TEST)"; the
  traceability table fixes which requirement belongs to which phase.

No external specs beyond these — requirements fully captured in decisions above.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The six spine schemas all share identical PK/FK/import declarations — the macro is pure dedup
  (`lib/parapet/spine/{incident,action_item,system_event,tool_audit,timeline_entry,action_claim}.ex`).
- `defmacro __using__/1` precedent exists in `lib/parapet/runbook.ex`, `recovery.ex`, `probe.ex`,
  `metrics/validator.ex` — copy the mechanics (none wrap `Ecto.Schema`, so the schema-base is new).
- `Parapet.Evidence.repo/0` (`evidence.ex:22-26`, `Application.get_env`-based) is the colocation home and
  shape template for `schema_prefix/0`.

### Established Patterns
- All reads/writes already route through schema **modules/structs** (`from(t in TimelineEntry, ...)`,
  `insert_all(ActionClaim, ...)`), so `@schema_prefix` will propagate with zero call-site edits — but that
  proof is Phase 52, not 51.
- The only raw `parapet_*` identifiers in `lib/` are `:parapet_exemplar_store` (an ETS table, not DB) and
  generator-task DDL (`gen.spine.ex`, `gen.archive_indexes.ex` — Phase 53). No runtime string-literal table
  writes exist to break propagation.

### Integration Points
- `config/config.exs` (net-new) ↔ `Parapet.Spine.Schema.__prefix__/0` — joined by the normalization
  agreement test.
- `test/support/concurrency_bootstrap.ex` ↔ the resolved prefix — must read the same value, not a literal.
- `mix.exs` `package.files` (`:42-44`) — must continue to exclude `config`.
</code_context>

<specifics>
## Specific Ideas

- The exact macro body to implement is given verbatim in `00-SYNTHESIS.md` §2 — use it as the reference
  implementation (including the `@primary_key`/`@foreign_key_type` dedup comment).
- `schema_migrations` must remain in `public` in the bootstrap (Ecto migration infra, not a spine table).
- Qualify index **targets**, never index **names** (an index lives in its table's schema).
</specifics>

<deferred>
## Deferred Ideas

- Prefixing the five committed `priv/repo/migrations/*.exs` library migrations → **Phase 53 (GEN-06)**.
- Propagation regression tests + `to_sql`/`get_meta` per-leg assertions + runtime-`prefix:` static ban guard
  + dual-prefix recompiling CI matrix → **Phase 52 (PROP-01..03, TEST-03)**.
- `mix parapet.doctor` drift check comparing runtime `schema_prefix/0` vs compiled `__prefix__/0` → **Phase 54
  (DOCTOR-01)**.

### Reviewed Todos (not folded)
None — `todo.match-phase 51` returned zero matches.
</deferred>
