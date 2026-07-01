# Phase 55: Demo App & Upgrade Docs - Context

**Gathered:** 2026-07-01 (assumptions mode + deep-research decision forks)
**Status:** Ready for planning

<domain>
## Phase Boundary

**Goal (ROADMAP Phase 55):** The demo app proves the schema-prefix end-to-end on a
real Phoenix host, and adopters have a copy-paste upgrade story that closes the audited
#1 documentation gap (no adopter-facing DB-schema upgrade story).

**Requirements in scope:** DOC-01, DOC-02, SAFE-03.

**In scope:** demo smoke-lane assertions proving the prefix lands data; the new
`docs/upgrade-1.x.md`; deployment.md schema subsection, README note, and a
migration-v1.md route to the upgrade doc; the demo-scoped compile-out-clean proof.

**Out of scope (Phase 56):** `mix verify.public_api` freeze assertion (SAFE-01),
telemetry contract test (SAFE-02), the additive-framing CHANGELOG/release note (SAFE-04).
Phase 55 must stay *compatible* with these but does not assert them.

**Not in scope at all:** any change to the prefix mechanism, generators, move task, or
doctor check (all landed Phases 51–54); any new demo migration (the six spine tables
already exist across the three committed demo migrations).
</domain>

<decisions>
## Implementation Decisions

> The four "Confident" areas are locked from Phase-54 decisions + codebase evidence.
> The three genuine forks (SAFE-03 assertion style, compile-out-clean home, migration-v1
> routing) were each resolved by a dedicated deep-research subagent applying the
> idiomatic-Elixir / test-correctness / DX / least-surprise / peer-library lenses. All
> decisions below are mutually coherent.

### A. SAFE-03 — demo smoke-lane assertions
- **D-01:** Add both new assertions to the **existing**
  `examples/demo_app/test/demo_app/operator_smoke_test.exs` (already `@moduletag :smoke`),
  so the CI `demo` job's `mix test --only smoke` step (`ci.yml:167`) picks them up with
  **zero workflow change**. Do NOT create a new test file (an untagged new file would pass
  the smoke lane green while the schema proof is dead code).
- **D-02 (leg-agnostic — FORK A → A1):** The round-trip assertion is
  `Ecto.get_meta(record, :prefix) == Parapet.Evidence.schema_prefix()` on a record produced
  by the real spine write path `Parapet.Evidence.create_incident/1`, seeded **inline** in the
  sandboxed test (mirroring `operator_smoke_test.exs:57-68`) — NOT off `mix run seeds.exs`.
  **Never** assert `== "parapet"` literally. Rationale: the library's own proof already uses
  this exact pattern — `test/parapet/spine/prefix_propagation_test.exs:77` asserts against the
  compiled mirror and `:138` expects `nil` on the unprefixed leg. A hardcoded literal goes
  **red-but-correct** the moment the demo runs on the `public` CI matrix leg (`ci.yml:70-77`)
  and encodes a "default-on only" claim that D-17/D-18 forbid. On the unprefixed leg
  `schema_prefix()` returns `nil`, so the assertion naturally reads `== nil` there.
- **D-03:** The six-table existence assertion queries
  `information_schema.tables WHERE table_schema = Parapet.Evidence.schema_prefix()` through
  `DemoApp.Repo` (the sandboxed connection), asserting all six spine tables are present:
  `parapet_action_items`, `parapet_incidents`, `parapet_timeline_entries`,
  `parapet_tool_audits`, `parapet_system_events`, `parapet_action_claims`. `information_schema`
  is catalog-level and independent of sandbox transaction rollback, so migrated tables are
  visible regardless of the sandbox. Use `schema_prefix()`, not a re-derived literal, so the
  query filters `public` correctly on the unprefixed leg.
- **D-04 (compile-out-clean home — FORK B → B2):** Add a demo-scoped
  `mix compile --no-optional-deps --warnings-as-errors` step to the **existing** CI `demo` job
  (reuse its cached `_build`, placed before the smoke test), NOT a new job — so
  `release_gate`'s `needs` list is unchanged. Rationale: the `lint` job (`ci.yml:42-44`) only
  proves the *library* compiles clean; the demo is a separate mix project (path-dep, own
  `Bandit`/`esbuild`/`tailwind`/Phoenix deps and `config/*.exs`) exercising real-host concerns
  the library compile never touches (app-env wiring, protocol consolidation across the host
  dep set, parapet under a host that does not set `schema_prefix`). This is the canonical
  "example app catches a real-host break the lib compile missed" case. B1 (rely on lint only)
  would leave SAFE-03's "real host is compile-out-clean" claim asserted but unproven.

### B. DOC-01 — docs/upgrade-1.x.md
- **D-05 (single source of truth):** `docs/upgrade-1.x.md` is the **sole** home for Track A/B
  *mechanics* (the six `ALTER TABLE … SET SCHEMA` lines, least-privilege GRANTs, the doctor
  `schema`-check remediation microcopy, rollback incl. half-migrated recovery). Every other
  surface (migration-v1.md, deployment.md, README) routes here and never restates mechanics —
  this kills cross-doc drift.
- **D-06 (copy sourced verbatim from Phase 54):** Track A/B copy-paste blocks and the
  drift-remediation strings are lifted verbatim from Phase-54 locked decisions so doc, doctor
  output, and generated migration tell one identical story: Track A = `config :parapet,
  schema_prefix: nil` **followed by** `mix deps.compile parapet --force` (54-CONTEXT D-04, D-17);
  Track B = the `mix parapet.gen.schema.move` reversible move-migration (54-CONTEXT D-06/D-08).
  Each config block is immediately followed by its `--force` recompile line (DOC-01 requirement).
- **D-07 (section order + honest framing):** Lead with the TL;DR reassurance — **"your data
  does not move unless you choose"** — then the **"action required"** caveat (54-CONTEXT D-18;
  NOT "no action required" — a do-nothing upgrader who wants the new default hits
  `relation "parapet.parapet_incidents" does not exist`), then Track A (stay on `public`)
  before Track B (move), then least-privilege GRANTs → recompile-order guidance → rollback
  incl. half-migrated recovery → FAQ. This matches the DOC-01 requirement's own enumerated
  order and ROADMAP success-criterion 2. The canonical D-18 "action required for existing
  installs" sentence is defined **here** and quoted/routed to from all other surfaces.
- **D-08 (HexDocs registration):** Register `docs/upgrade-1.x.md` in **both** `mix.exs`
  `extras:` and the `Guides` `groups_for_extras` group (adjacent to `migration-v1.md` and
  `deployment.md`, `mix.exs:62-108`). Omission makes it invisible on HexDocs AND turns the
  DOC-02 cross-references into broken links that fail the `mix docs --warnings-as-errors`
  gate (`ci.yml:48`).

### C. DOC-02 — deployment.md + README + migration-v1.md routing
- **D-09 (migration-v1 routing — FORK C → C2-refined):** Add a new **dedicated early step
  "Step 3: Choose your schema location (v1.7+)"** to `docs/migration-v1.md` (renumber existing
  Steps 3–6 → 4–7). It reassures-then-instructs **inline** (data never moves automatically →
  action required, or the first spine query fails) and routes to `upgrade-1.x.md` for Track A/B
  mechanics. Do **NOT** bury a one-line pointer in the existing Step 6 checklist (rejected
  option C1): a bullet among six deploy-validation items is the exact D-17 "buried" failure
  mode — the do-nothing upgrader who most needs it skims past it. The schema-default flip is
  the one *behavioral* break in the 1.x line, making it a peer of "update the dependency," not
  a checklist tick (mirrors Oban/ash version-specific upgrade sections). Step 3 carries only
  the decision + the one Track-A config line + the route — mechanics stay single-sourced in
  upgrade-1.x.md (D-05). Step 6's existing `mix parapet.doctor --ci` line is unchanged (the
  doctor `schema` check is the enforcement backstop, 54-CONTEXT D-05).
- **D-10 (deployment.md):** Add a **net-new** schema subsection to `docs/deployment.md` (it
  currently has none), placed near the durable-evidence migration content, that states the
  default `parapet` schema and routes to `upgrade-1.x.md`. Same single-source rule — do not
  fork the Track A/B prose here.
- **D-11 (README):** Add a short note in the README Installation section (~L43-62, where
  `mix parapet.install`/config land) — one line: new installs default to the `parapet` schema;
  existing adopters see migration-v1.md Step 3. Reassure-then-route; never restate mechanics.

### D. Demo app config posture
- **D-12:** The demo app already runs under the **default `"parapet"` prefix with NO explicit
  `schema_prefix` config** (`examples/demo_app/config/config.exs` omits it), so it is *already*
  the real-host smoke proof for default-on. SAFE-03 only ADDS assertions — it does NOT add or
  change demo config, and does NOT add a demo migration. The demo is the proof precisely
  *because* it omits the config and inherits `Application.compile_env(:parapet, :schema_prefix,
  "parapet")`. Confirm during planning that the CI `demo` job does not leak the `test` job's
  `PARAPET_SCHEMA_PREFIX` env (`ci.yml:77`) into the demo build.

### Claude's Discretion
- Exact microcopy of the smoke-test failure messages and the FAQ question list (keep the
  reassure→instruct tone from D-07/D-18).
- Whether the six-table assertion uses one `information_schema` query returning a set compared
  to the expected six, or per-table — planner's call; both satisfy D-03.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/54-upgrade-path-doctor/54-CONTEXT.md` — D-04 (doctor drift-remediation
  microcopy), D-05 (doctor check as UPG-05 backstop), D-06/D-08 (gen.schema.move migration
  body), D-17 (Track A = nil + `--force`), D-18 (honest "action required" framing). **The docs
  must mirror these verbatim.**
- `.planning/ROADMAP.md` — Phase 55 section (goal, 3 success criteria).
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, SAFE-03 acceptance text (lines 54, 55, 61).
- `.github/workflows/ci.yml` — `lint` compile-out-clean steps (`:42-44`), dual-prefix matrix
  (`:70-77`), `demo` job migrate+seed+`--only smoke` (`:118-167`), `release_gate` `needs`.
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — smoke test to extend; existing
  `create_incident/1` in-sandbox write pattern (`:27-32`, `:57-68`).
- `examples/demo_app/config/config.exs`, `config/test.exs` — demo omits `schema_prefix`
  (default-on proof); sandbox config.
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` and
  `…20260525000002_add_parapet_action_claims.exs` — the six tables (5 + action_claims), all
  bake `@prefix Parapet.Spine.Schema.__prefix__()`.
- `lib/parapet/evidence.ex:41-43` — `Parapet.Evidence.schema_prefix/0` runtime mirror (the
  assertion target).
- `test/parapet/spine/prefix_propagation_test.exs:77,138` — house pattern precedent for the
  A1 leg-agnostic `get_meta` assertion.
- `mix.exs:62-108` — `docs:` `extras:` + `groups_for_extras` (register upgrade-1.x.md here).
- `docs/migration-v1.md` — linear Step 1-6; insert new Step 3, renumber 3-6 → 4-7.
- `docs/deployment.md` — no schema section yet (net-new subsection).
- `README.md:43-62` — Installation section (schema note home).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Evidence.schema_prefix/0` — compile-frozen runtime mirror; the single assertion
  target keeping the smoke test leg-agnostic.
- `Parapet.Evidence.create_incident/1` — demonstrated in-sandbox spine write in the existing
  smoke test; reuse for the `get_meta` round-trip.
- The `@moduletag :smoke` + `mix test --only smoke` seam already wired in CI — no workflow
  plumbing needed for D-01.
- `test/parapet/spine/prefix_propagation_test.exs` — copy its assertion idiom for consistency.
- Phase-54 gen.schema.move output + doctor `schema`-check remediation strings — copy verbatim
  into upgrade-1.x.md (single source, D-05/D-06).

### Established Patterns
- Compile-time `@schema_prefix` (default `parapet`; `nil`/`""`/`"public"` ⇒ unprefixed);
  runtime `prefix:` banned. Prefix is an internal DB detail — telemetry + public API frozen.
- Dual-prefix CI matrix (`parapet` + `public` legs) — every prefix-touching test must be
  truthful under both, forcing the leg-agnostic assertion (D-02/D-03).
- Docs published via HexDocs `extras:` + `groups_for_extras`; `mix docs --warnings-as-errors`
  gates cross-reference integrity.

### Integration Points
- CI `demo` job (`ci.yml:118-167`): migrate → seed → new compile-out-clean step (D-04) →
  `mix test --only smoke` (extended, D-01). Feeds `release_gate` (`needs`) — do not restructure.
- Docs graph: upgrade-1.x.md (new hub for mechanics) ← migration-v1.md Step 3 ← deployment.md
  subsection ← README note. All routes, single-sourced.
</code_context>

<specifics>
## Specific Ideas

- migration-v1.md Step 3 wording sketch (reassure → instruct → route), to be refined at write:
  "Parapet 1.7 changed the default schema for evidence tables from `public` to `parapet`. Your
  data never moves automatically — nothing runs behind your back. But existing adopters must
  choose, or the first spine query fails with `relation \"parapet.parapet_incidents\" does not
  exist`: [Track A one-liner] / [Track B → upgrade-1.x.md]. Either way, run `mix parapet.doctor`."
- The canonical D-18 "action required for existing installs" sentence is defined once in
  upgrade-1.x.md and quoted/routed elsewhere.
</specifics>

<deferred>
## Deferred Ideas

- SAFE-01/SAFE-02/SAFE-04 (public-API freeze assertion, telemetry contract test, additive
  CHANGELOG/release-note framing) — Phase 56.
- None of the demo/doc work introduces new capabilities; no scope creep surfaced.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
