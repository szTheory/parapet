# Phase 55: Demo App & Upgrade Docs — Research

**Researched:** 2026-07-01
**Domain:** Elixir/Ecto demo app schema-prefix smoke assertions + HexDocs upgrade documentation
**Confidence:** HIGH

---

## Summary

Phase 55 is a documentation + test-assertion phase that closes the #1 adopter documentation gap
(no schema-upgrade story) and adds SAFE-03 smoke assertions to the demo CI job. All design forks
were resolved in 55-CONTEXT.md (D-01 through D-12). The research task was to verify every locked
decision against live code and surface concrete mechanics, exact line numbers, and landmines for
the planner.

**Primary finding:** One real DRIFT FLAG exists: the demo app does NOT have a sentinel schema-creation
migration (`00000000000000_create_parapet_schema.exs`). The three committed demo migrations all use
`@prefix Parapet.Spine.Schema.__prefix__()` = `"parapet"`, meaning `mix ecto.create && mix ecto.migrate`
(the CI demo job) will fail with `ERROR 3F000: schema "parapet" does not exist` on the very first
migration. Phase 55 must add this sentinel as its first task — it is NOT contradicted by D-12 (which
prohibits new spine-table migrations, not schema-infrastructure migrations).

All other locked decisions (D-01 through D-12) check out against live code. CI line numbers diverge
slightly from CONTEXT references (lines shifted); exact verified lines are documented below.

**Primary recommendation:** Add the sentinel migration to the demo app first, then extend the smoke
test, then write docs — in that order. The CI demo job cannot prove anything until the schema exists.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
All 12 decisions (D-01 through D-12) from `.planning/phases/55-demo-app-upgrade-docs/55-CONTEXT.md`
are locked. Key ones for the planner:

- **D-01:** Add assertions to the EXISTING `examples/demo_app/test/demo_app/operator_smoke_test.exs`
  (tagged `@moduletag :smoke`). Do NOT create a new test file.
- **D-02:** Assert `Ecto.get_meta(record, :prefix) == Parapet.Evidence.schema_prefix()` — never
  `== "parapet"` literally.
- **D-03:** Six-table existence check via `information_schema.tables WHERE table_schema = schema_prefix()`.
- **D-04:** Add `mix compile --no-optional-deps --warnings-as-errors` to the EXISTING CI `demo` job
  (before the smoke test step), NOT a new CI job.
- **D-05:** `docs/upgrade-1.x.md` is the sole home for Track A/B mechanics.
- **D-06:** Track A/B copy lifted verbatim from 54-CONTEXT D-04/D-17/D-06/D-08.
- **D-07:** Section order: TL;DR reassurance → "action required" caveat → Track A → Track B →
  GRANTs → recompile-order → rollback → FAQ.
- **D-08:** Register `docs/upgrade-1.x.md` in BOTH `extras:` AND `groups_for_extras` in `mix.exs`.
- **D-09:** Insert new Step 3 in `docs/migration-v1.md`; renumber existing Steps 3–6 → 4–7.
- **D-10:** Add net-new schema subsection to `docs/deployment.md` near the durable-evidence
  migration content (Step 4).
- **D-11:** Add schema note to README Installation section (~L43–62).
- **D-12:** Demo app config omits `schema_prefix` by design — do NOT add it. Do NOT add a spine
  table migration.

### Claude's Discretion
- Exact failure messages for smoke-test assertions.
- FAQ question list (tone: reassure → instruct).
- Whether six-table assertion uses one `information_schema` query or six per-table assertions.

### Deferred Ideas (OUT OF SCOPE)
- SAFE-01 (`mix verify.public_api` freeze), SAFE-02 (telemetry contract), SAFE-04 (CHANGELOG framing)
  — Phase 56.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOC-01 | New `docs/upgrade-1.x.md` — TL;DR, Track A/B copy-paste blocks (each followed by `--force` recompile), least-privilege GRANTs, recompile-order, rollback incl. half-migrated recovery, FAQ | D-05/D-06/D-07 locked; Track A/B verbatim text extracted from 54-CONTEXT below |
| DOC-02 | `docs/deployment.md` schema subsection, `README.md` note, `docs/migration-v1.md` routing pointer | Confirmed: deployment.md has no schema section yet; migration-v1.md has 6 steps (new Step 3 inserts, 3–6 → 4–7); README Installation L43–62 |
| SAFE-03 | Compile-out-clean holds; smoke lane asserts six tables in `parapet` and round-trip `Ecto.get_meta(record, :prefix) == schema_prefix()` | CI demo job at L118–167; smoke test file verified; D-01/D-02/D-03/D-04 locked |
</phase_requirements>

---

## Drift / Flags

> **CRITICAL — Sentinel migration missing from demo app.**

**D-12 assumption "The demo app already runs under the default `parapet` prefix"** is NOT verifiable
in the current state. The demo app has zero schema-creation logic:

- `examples/demo_app/priv/repo/migrations/` contains exactly three files:
  - `20260525000000_add_parapet_spine_tables.exs` — creates 5 tables with `prefix: @prefix` where
    `@prefix = Parapet.Spine.Schema.__prefix__() = "parapet"` at compile time.
  - `20260525000001_add_action_item_kind_and_incident_id.exs` — alters tables with `prefix: @prefix`.
  - `20260525000002_add_parapet_action_claims.exs` — creates the sixth table with `prefix: @prefix`.
- None of these files contains `CREATE SCHEMA` or any equivalent.
- Ecto's Postgres adapter does NOT auto-create schemas when `prefix:` is set.

**Consequence:** The CI demo job step `mix ecto.create && mix ecto.migrate` will fail with
`ERROR 3F000 (invalid_schema_name): schema "parapet" does not exist` on the very first migration
(line 163 of ci.yml).

**Resolution:** Phase 55 must add `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs`
as its first task (Wave 0 / Task 0). The body matches what `gen.spine` generates (confirmed from
`lib/mix/tasks/parapet.gen.spine.ex:187-200`):

```elixir
defmodule DemoApp.Repo.Migrations.CreateParapetSchema do
  use Ecto.Migration

  def up do
    execute("CREATE SCHEMA IF NOT EXISTS parapet")
  end

  def down do
    execute("DROP SCHEMA IF EXISTS parapet")
    # Non-cascading — fail-closed safety (53-CONTEXT D-14). If spine tables still
    # exist, this raises 2BP01 rather than deleting data silently.
  end
end
```

**Why D-12 does not prohibit this:** D-12 says "does NOT add a demo migration" in the context of
not adding new *spine-table* migrations for SAFE-03 assertions. The sentinel schema-creation
migration is prerequisite infrastructure, not a spine migration. D-12 protects the purity of
"demo omits `schema_prefix` config and inherits the default" — it does not mean "demo CI is already
functional". The Phase 53 verification (53-VERIFICATION.md) ran `PARAPET_SCHEMA_PREFIX=parapet mix test`
against the library root, NOT the demo CI job — this gap was never caught.

**Evidence:** `find /Users/jon/projects/parapet -name "00000000000000*"` returns no results.
`find /Users/jon/projects/parapet/examples/demo_app/priv/repo/migrations/ -name "*schema*"` returns
no results. The 53-04-SUMMARY.md explicitly documents this was never run: verification was "PARAPET_SCHEMA_PREFIX=parapet mix test — 647 tests".

---

**Minor drift: CI line numbers shifted from CONTEXT references.**

The 55-CONTEXT canonical_refs cite approximate lines. Verified actuals:

| CONTEXT citation | Verified actual |
|----------------|-----------------|
| `lint` compile-out-clean steps `:42-44` | Line 42: `run: mix compile --warnings-as-errors`, Line 44: `run: mix compile --no-optional-deps --warnings-as-errors` — **CONFIRMED** |
| `mix docs --warnings-as-errors` `:48` | Line 48: `run: mix docs --warnings-as-errors` — **CONFIRMED** |
| dual-prefix matrix `:70-77` | Lines 70–77: `schema_prefix: ['parapet']` matrix + `include: …'public'` — **CONFIRMED** |
| `PARAPET_SCHEMA_PREFIX` env `:77` | Line 77: `PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}` — **CONFIRMED** |
| demo job migrate→seed→smoke `:118-167` | Lines 163–167: `mix ecto.create && mix ecto.migrate` (163), `mix run priv/repo/seeds.exs` (165), `mix test --only smoke` (167) — **CONFIRMED** |
| smoke test `create_incident/1` `:27-32`, `:57-68` | Actual lines: L27–31 (first create_incident in history test), L57–68 (self-contained sandbox seed test) — **CONFIRMED, minor offset** |

**Demo CI `PARAPET_SCHEMA_PREFIX` leak check:** The `demo` job (L118–167) has no `PARAPET_SCHEMA_PREFIX`
env — its top-level `env:` block (L125–126) sets only `MIX_ENV: test`. The `test` job's `PARAPET_SCHEMA_PREFIX`
(L77) does NOT propagate to the `demo` job — GitHub Actions job environments are isolated. D-12's
concern is confirmed non-issue. [VERIFIED: ci.yml lines 118-170]

---

## Verification of Locked Decisions Against Live Code

### D-01: Extend existing smoke test, not a new file [VERIFIED]

File: `examples/demo_app/test/demo_app/operator_smoke_test.exs`

- `@moduletag :smoke` at L4 — confirmed.
- `use DemoAppWeb.ConnCase` at L2 — confirmed (provides sandbox, `conn` setup).
- CI step `mix test --only smoke` at ci.yml:167 — confirmed, picks up `@moduletag :smoke` tags.
- No new file needed. The new assertions slot at the end of `DemoApp.OperatorSmokeTest`.

### D-02: Leg-agnostic round-trip assertion [VERIFIED]

`Parapet.Evidence.schema_prefix/0` at `lib/parapet/evidence.ex:41-43`:
```elixir
def schema_prefix do
  Parapet.Spine.Schema.__prefix__()
end
```
`Parapet.Evidence.create_incident/1` at L75–86: takes `attrs \\ %{}` map, runs an `Ecto.Multi`,
returns `{:ok, incident}` or `{:error, reason}`. The returned `incident` struct has
`Ecto.get_meta(incident, :prefix)` equal to `Parapet.Spine.Schema.__prefix__()`.

House precedent in `test/parapet/spine/prefix_propagation_test.exs`:
- L77: `assert Ecto.get_meta(incident, :prefix) == @prefix` where `@prefix = Parapet.Spine.Schema.__prefix__()`
- L138: `assert Ecto.get_meta(incident, :prefix) == nil` (nil leg)

The smoke test must mirror this: assert `== Parapet.Evidence.schema_prefix()`, never `== "parapet"`.

### D-03: Six-table existence via information_schema [VERIFIED]

Tables confirmed across the three demo migrations (all with `prefix: @prefix`):
1. `parapet_action_items` — `20260525000000` L7
2. `parapet_incidents` — `20260525000000` L17
3. `parapet_timeline_entries` — `20260525000000` L44
4. `parapet_tool_audits` — `20260525000000` L58
5. `parapet_system_events` — `20260525000000` L74
6. `parapet_action_claims` — `20260525000002` L7

All six are in the `parapet` schema when `@prefix = "parapet"`.

`information_schema.tables` is catalog-level, independent of sandbox transaction rollback —
`information_schema.tables WHERE table_schema = <value>` returns migrated tables even inside
an Ecto Sandbox test. The query must use `Parapet.Evidence.schema_prefix()` as the value, not a
literal `"parapet"`, so it is leg-agnostic.

### D-04: Compile-out-clean in existing demo CI job [VERIFIED]

CI `demo` job at L118–167. Current step sequence before Phase 55:
1. L161: `mix deps.get`
2. L163: `mix ecto.create && mix ecto.migrate`
3. L165: `mix run priv/repo/seeds.exs`
4. L167: `mix test --only smoke`

Phase 55 adds one step between L161 and L163 (or between steps 2 and 3, before the smoke test):

```yaml
- name: Compile demo (warnings-as-errors, no-optional-deps)
  run: cd examples/demo_app && mix compile --no-optional-deps --warnings-as-errors
```

This reuses the cached `_build` from the `Cache demo _build` step at L154–159. No `release_gate`
`needs` change required — `release_gate` at L169–173 already `needs: [lint, test, demo]`.

**Important:** Place compile-out-clean AFTER `mix deps.get` (L161) but BEFORE the smoke test.
Placing it before `mix ecto.migrate` is fine — compile does not require DB.

### D-05: Single-source upgrade-1.x.md [VERIFIED]

`docs/upgrade-1.x.md` does not yet exist. It will be a new file.
`docs/migration-v1.md` (current 6 steps), `docs/deployment.md` (current 7 steps, no schema section),
and `README.md` Installation (~L43–62) will route to it.

### D-06: Copy from 54-CONTEXT [VERIFIED — see verbatim copy below]

### D-07: Section order [VERIFIED — matches DOC-01 requirement enumeration]

DOC-01 requirement text: "TL;DR 'your data does not move unless you choose', Track A/B copy-paste
(each config block followed by the `--force` recompile line), least-privilege GRANTs,
recompile-order, rollback incl. half-migrated recovery, FAQ."

### D-08: HexDocs registration double-requirement [VERIFIED]

`mix.exs:62–108` (confirmed):
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  "docs/stability.md",
  ...
  "docs/migration-v1.md",
  "docs/deployment.md",
  ...
],
groups_for_extras: [
  ...
  Guides: [
    ...
    "docs/migration-v1.md",
    "docs/deployment.md",
    ...
  ],
  ...
]
```

`docs/upgrade-1.x.md` must be added to BOTH lists:
1. In `extras:` list (after `"docs/migration-v1.md"` is a natural placement)
2. In `groups_for_extras` `Guides:` sublist (adjacent to `"docs/migration-v1.md"`)

Omitting either list causes `mix docs --warnings-as-errors` (ci.yml:48) to fail due to broken
cross-references from migration-v1.md Step 3 and deployment.md.

### D-09: migration-v1.md routing [VERIFIED]

Current `docs/migration-v1.md` structure (6 steps):
- **Step 1:** Read the stability boundary
- **Step 2:** Update the dependency
- **Step 3:** Move custom SLOs to providers (`Parapet.SLO.define/2` deprecated)
- **Step 4:** Re-check generated host surfaces
- **Step 5:** Review recovery and operator surfaces
- **Step 6:** Run the safe-upgrade checklist (contains `mix parapet.doctor --ci`)

Phase 55 inserts a new **"Step 3: Choose your schema location (v1.7+)"** BEFORE the current Step 3
and renumbers:
- Old Step 3 → **Step 4**: Move custom SLOs to providers
- Old Step 4 → **Step 5**: Re-check generated host surfaces
- Old Step 5 → **Step 6**: Review recovery and operator surfaces
- Old Step 6 → **Step 7**: Run the safe-upgrade checklist

The current Step 6 (`mix parapet.doctor --ci`) moves to Step 7 unchanged (D-09 "Step 6's existing
`mix parapet.doctor --ci` line is unchanged").

### D-10: deployment.md schema subsection [VERIFIED]

`docs/deployment.md` currently has 7 steps:
- Step 1: Expose metrics deliberately
- Step 2: Load generated Prometheus rules
- Step 3: Record deploy markers
- **Step 4: Run durable-evidence migrations** ← subsection goes here
- Step 5: Check optional dependency compile-out
- Step 6: Secure operator routes
- Step 7: Validate the deployed app

Step 4 already references `mix ecto.migrate` and the durable-evidence tables. The new schema
subsection belongs here — under Step 4 or as a **Step 4a** callout or a `> Note:` block
within Step 4 — confirming that `mix ecto.migrate` creates the `parapet` schema automatically
and existing adopters see `docs/upgrade-1.x.md` for the migration choice.

### D-11: README Installation section [VERIFIED]

README.md Installation section spans L43–79 (actual, not L43-62 as cited — the section continues
to L79 where `mix parapet.install --with-ui` options are shown). The note slots after the
`mix parapet.install` block (~L61) before the "Operator Loop" section.

Actual L45–61 content:
```markdown
## Installation

Add `parapet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:parapet, "~> 1.0"}
  ]
end
```

Then install and configure Parapet with the single Day-1 entrypoint:

```bash
mix deps.get
mix parapet.install
```
```

Schema note targets the paragraph after `mix parapet.install` at ~L62: new installs default to
the `parapet` schema; existing adopters follow migration-v1.md Step 3.

### D-12: Demo config posture [VERIFIED]

`examples/demo_app/config/config.exs` — confirmed ZERO `schema_prefix` config:
```elixir
config :parapet,
  repo: DemoApp.Repo,
  providers: [Parapet.SLO.StarterPack.WebSaaS]
```

No `schema_prefix:` key. The demo inherits `Application.compile_env(:parapet, :schema_prefix, "parapet")`
= `"parapet"` at compile time. This is the default-on proof.

`examples/demo_app/config/test.exs` — confirmed ZERO `schema_prefix` config. Only sets DB pool
to `Ecto.Adapters.SQL.Sandbox` and logging.

---

## Exact Current Content the Planner Will Edit

### operator_smoke_test.exs — Current skeleton

The file (`examples/demo_app/test/demo_app/operator_smoke_test.exs`) as it stands:

```
defmodule DemoApp.OperatorSmokeTest do
  use DemoAppWeb.ConnCase
  @moduletag :smoke

  # Tests L5–41: HTTP 200 smoke tests (GET /parapet, /parapet/actions, /ops/parapet, 
  #   /ops/parapet/actions, /parapet/history with create_incident L27-31, 
  #   /ops/parapet/history with create_incident L43-55)

  # "at least one seeded incident exists" test L57–68:
  #   {:ok, _} = Parapet.Evidence.create_incident(%{title: "smoke test incident", state: "open"})
  #   assert DemoApp.Repo.aggregate(Parapet.Spine.Incident, :count) > 0

  # "preferred and compatibility incident detail routes render" L70–84
  # "scoped preferred and compatibility incident detail routes render" L86–100
  # "resolved incident detail is read-only and retrospective friendly" L102–129

  describe "Phase 48 rendered-state gates (RED until wave-2/3)" do ... end  # L150–272

  describe "Phase 49 gallery + fixture coverage" do ... end  # L285–435

end
```

The two new SAFE-03 tests slot at the end of the top-level `DemoApp.OperatorSmokeTest` module,
BEFORE the `describe "Phase 48 ..."` block or AFTER it — but they must NOT be inside a `describe`
block (so `@moduletag :smoke` applies to them). They should go between the "resolved incident detail"
test (L102) and the Phase 48 describe block (L150).

**Insertion point:** After L129 (end of "resolved incident detail" test), before L131 (blank/comment
before Phase 48 block).

### migration-v1.md — Current step list

Exact current steps in `docs/migration-v1.md`:

1. **Step 1:** Read the stability boundary (stability contract, Stable vs Experimental vs Internal)
2. **Step 2:** Update the dependency (move to `~> 1.0`, `mix deps.get`, `mix compile --warnings-as-errors`)
3. **Step 3:** Move custom SLOs to providers (`Parapet.SLO.define/2` deprecated → `Parapet.SLO.Provider`)
4. **Step 4:** Re-check generated host surfaces (run `mix parapet.install`, `mix parapet.gen.prometheus`,
   `mix parapet.doctor`)
5. **Step 5:** Review recovery and operator surfaces (`Parapet.Recovery` four-callback contract)
6. **Step 6:** Run the safe-upgrade checklist (`mix compile --warnings-as-errors`, `mix test`,
   `mix parapet.doctor --ci`)

New Step 3 wording (from 55-CONTEXT specifics, to be refined at write):

> **Step 3: Choose your schema location (v1.7+)**
>
> Parapet 1.7 changed the default schema for evidence tables from `public` to `parapet`. Your
> data never moves automatically — nothing runs behind your back. But existing adopters must
> choose, or the first spine query fails with `relation "parapet.parapet_incidents" does not exist`:
>
> **Track A — stay on `public`:** Add to `config/config.exs`:
> ```elixir
> config :parapet, schema_prefix: nil
> ```
> Then recompile: `mix deps.compile parapet --force`
>
> **Track B — move to `parapet`:** See [Upgrade Guide (1.x)](upgrade-1.x.md) for the
> `mix parapet.gen.schema.move` reversible migration.
>
> Either way, run `mix parapet.doctor` after the change.

### mix.exs extras block — Current content

`mix.exs:62–86` (confirmed):
```elixir
extras: [
  "README.md",
  "CHANGELOG.md",
  "docs/HISTORY.md",
  "docs/stability.md",
  "docs/adopter-flows.md",
  "docs/operator-ui.md",
  "docs/slo-reference.md",
  "docs/telemetry.md",
  "docs/getting-started.md",
  "docs/migration-v1.md",
  "docs/deployment.md",
  "docs/troubleshooting.md",
  "docs/slo-authoring-guide.md",
  "docs/recovery-actions.md",
  "docs/release-policy.md",
  "docs/integrations/sigra.md",
  ...
],
```

Add `"docs/upgrade-1.x.md"` after `"docs/migration-v1.md"`:
```elixir
  "docs/migration-v1.md",
  "docs/upgrade-1.x.md",
  "docs/deployment.md",
```

`mix.exs:88–108` groups_for_extras `Guides:` sublist (confirmed):
```elixir
Guides: [
  "docs/adopter-flows.md",
  "docs/operator-ui.md",
  "docs/migration-v1.md",
  "docs/deployment.md",
  "docs/slo-authoring-guide.md",
  ...
],
```

Add `"docs/upgrade-1.x.md"` after `"docs/migration-v1.md"`:
```elixir
  "docs/migration-v1.md",
  "docs/upgrade-1.x.md",
  "docs/deployment.md",
```

### ci.yml demo job — Current step sequence

Lines 141–167:
```yaml
steps:
  - uses: actions/checkout@...              # L142
  - name: Setup Elixir                      # L143-148
  - name: Cache demo dependencies           # L149-153
  - name: Cache demo _build                 # L154-159
  - name: Install demo dependencies         # L160-161
    run: cd examples/demo_app && mix deps.get
  - name: Create and migrate demo database  # L162-163
    run: cd examples/demo_app && mix ecto.create && mix ecto.migrate
  - name: Seed demo database                # L164-165
    run: cd examples/demo_app && mix run priv/repo/seeds.exs
  - name: Run smoke test                    # L166-167
    run: cd examples/demo_app && mix test --only smoke
```

Phase 55 adds one step between L161 and L162 (after deps.get, before ecto.create):

```yaml
  - name: Compile demo (warnings-as-errors, no-optional-deps)
    run: cd examples/demo_app && mix compile --no-optional-deps --warnings-as-errors
```

---

## Verbatim Phase-54 Copy for upgrade-1.x.md

The following strings are pulled from 54-CONTEXT locked decisions (D-04, D-17, D-18):

### Track A (stay on `public`) — from 54-CONTEXT D-17

Exact config block:
```elixir
config :parapet, schema_prefix: nil
```

Exact recompile line (must follow every config block in the doc — DOC-01 requirement):
```bash
mix deps.compile parapet --force
```

Then run doctor:
```bash
mix parapet.doctor
```

### Track B (move to `parapet`) — from 54-CONTEXT D-06/D-08

```bash
mix parapet.gen.schema.move
mix ecto.migrate
```

The generated migration:
- Uses `SET LOCAL lock_timeout TO '5s'` (in `after_begin/0`)
- Runs `CREATE SCHEMA IF NOT EXISTS parapet` (omitted with `--no-create-schema`)
- Executes six explicit `ALTER TABLE public.<t> SET SCHEMA parapet` lines
- `down` reverses with six `ALTER TABLE parapet.<t> SET SCHEMA public` in LIFO order
- `down` never `DROP SCHEMA` (fail-closed)

For `--no-create-schema` users (DBA-managed schema), the least-privilege GRANTs from
54-CONTEXT D-12b / `lib/parapet/spine/schema_move_notice.ex`:

```sql
-- Run once as a privileged role (DBA / schema owner):
CREATE SCHEMA IF NOT EXISTS parapet AUTHORIZATION your_app_role;

-- Split-role fallback (schema owned by a separate role):
GRANT USAGE  ON SCHEMA parapet TO your_app_role;
GRANT CREATE ON SCHEMA parapet TO your_app_role;
-- then: mix ecto.migrate
```

### Doctor drift-remediation microcopy — from 54-CONTEXT D-04

Track A drift message (when runtime `:schema_prefix` ≠ compiled `@schema_prefix`):
> "Config drift: runtime :schema_prefix is `<X>` but Parapet was compiled with `<Y>`. Spine
> reads/writes may target the wrong schema. Recompile the library:
> `mix deps.compile parapet --force`"

Missing schema message:
> "Schema `<X>` does not exist in the configured repo (`<repo>`). Create it before migrating:
> run the `CREATE SCHEMA` step from `mix parapet.gen.spine`, then `mix ecto.migrate`"

### Honest "action required" framing — from 54-CONTEXT D-18

The canonical sentence (define once in upgrade-1.x.md, reference elsewhere):

> **"Your data never moves automatically — nothing runs behind your back."** (TL;DR first)
>
> **"Action required for existing adopters: add `config :parapet, schema_prefix: nil` +
> `mix deps.compile parapet --force` to stay on `public`, then run `mix parapet.doctor`."**

NOT "no action required." The do-nothing upgrader gets a `relation "parapet.parapet_incidents"
does not exist` error on first spine query — not silent corruption.

---

## Landmines / Gotchas

### Landmine 1: Never assert `== "parapet"` literally in the smoke test

The smoke test runs inside the demo CI `demo` job, which does NOT have `PARAPET_SCHEMA_PREFIX`
in its environment (confirmed at ci.yml:125–126). The demo is compiled with the default:
`Application.compile_env(:parapet, :schema_prefix, "parapet") = "parapet"`.

However: the LIBRARY's `test` CI job (L63-116) uses `PARAPET_SCHEMA_PREFIX` matrix with both
`'parapet'` and `'public'` values. If a smoke test ever asserts `== "parapet"` literally, it will
still pass in the demo CI (because demo job has no matrix env), but it encodes a "default-on only"
claim and is wrong-by-design for the `public` leg.

The correct assertion is always:
```elixir
assert Ecto.get_meta(record, :prefix) == Parapet.Evidence.schema_prefix()
```

When the demo CI compiles with no `PARAPET_SCHEMA_PREFIX` env, `schema_prefix()` returns `"parapet"`.
The assertion reads `== "parapet"` naturally. If somehow the demo were run under a `nil` leg,
`schema_prefix()` would return `nil` and the assertion would naturally read `== nil`.

Similarly for the `information_schema` table-existence query — use `schema_prefix()` not `"parapet"`:
```elixir
prefix = Parapet.Evidence.schema_prefix()
# query: WHERE table_schema = $1, binding: [prefix || "public"]
```

When `schema_prefix()` returns `nil` (unprefixed leg), the tables live in `public` — the query
must handle `nil` by falling back to `"public"` for the schema comparison.

### Landmine 2: Demo CI `PARAPET_SCHEMA_PREFIX` env leak is a non-issue [CONFIRMED]

The `demo` job (ci.yml L118–167) has its own `env:` block with only `MIX_ENV: test`. GitHub
Actions job environments are isolated — the `test` job's `PARAPET_SCHEMA_PREFIX: ${{ matrix.schema_prefix }}`
does NOT propagate to the `demo` job. No leak to prevent. D-12's "confirm during planning"
is satisfied: confirmed non-issue. [VERIFIED: ci.yml L125-126]

### Landmine 3: HexDocs registration double-requirement

`mix docs --warnings-as-errors` (ci.yml:48) validates all cross-references in Extra pages. If
`docs/upgrade-1.x.md` is registered only in `extras:` but NOT in `groups_for_extras`, the file
is invisible on HexDocs but cross-references still work. If it is registered in NEITHER, the
file doesn't render at all AND any cross-link (from migration-v1.md or deployment.md) to
`upgrade-1.x.md` breaks the `mix docs --warnings-as-errors` gate.

**Rule:** BOTH lists in mix.exs must be updated simultaneously. The `planner` must make this
a single task that edits `mix.exs` once, not two separate tasks.

### Landmine 4: information_schema visibility under Ecto Sandbox

`information_schema.tables` is a catalog view — it reflects the persistent database state
(committed DDL), not the state inside an uncommitted sandbox transaction. Ecto Sandbox wraps
each test in a transaction but `mix ecto.migrate` runs before any test sandbox is set up
(at CI step L163), so all six tables ARE visible in `information_schema.tables` by the time
the smoke test queries it.

The query must go through `DemoApp.Repo` (the sandboxed connection), NOT a direct Postgrex
connection — the sandbox checkout in `DemoAppWeb.ConnCase` is on `DemoApp.Repo`. Using
`Ecto.Adapters.SQL.query!/3` on `DemoApp.Repo` works.

Example query:
```elixir
prefix = Parapet.Evidence.schema_prefix() || "public"
result = Ecto.Adapters.SQL.query!(
  DemoApp.Repo,
  "SELECT table_name FROM information_schema.tables WHERE table_schema = $1",
  [prefix]
)
found_tables = Enum.map(result.rows, fn [name] -> name end) |> MapSet.new()
```

### Landmine 5: Sentinel migration ordering

Ecto migrator sorts migrations by `Integer.parse(Path.rootname(base))`, so version `0`
(from `00000000000000_create_parapet_schema.exs`) sorts strictly before `20260525000000`.
The sentinel runs first, creating the `parapet` schema before any `CREATE TABLE prefix: "parapet"`
migration runs. This is the same mechanism confirmed in 53-CONTEXT D-13 and 53-RESEARCH.md.

### Landmine 6: ConnCase vs bare ExUnit.Case for the round-trip assertion

The smoke test uses `use DemoAppWeb.ConnCase`, which sets up the Ecto Sandbox checkout
on `DemoApp.Repo`. The `create_incident/1` call works within the sandbox. The `get_meta`
assertion on the returned struct works on any struct, not requiring a live DB connection.

Do NOT use `Parapet.TestSupport.ConcurrencyRepo` in the demo smoke test — that repo lives
in the library test support, not in the demo app. Use `Parapet.Evidence.create_incident/1`
which routes through `DemoApp.Repo` (configured via `config :parapet, repo: DemoApp.Repo`).

### Landmine 7: One-time contributor stale-DB note (from 53-04-SUMMARY)

Contributors with an existing demo DB (pre-Phase-53) need to run `mix demo.reset` (which is
`mix ecto.drop && mix ecto.create && mix ecto.migrate && mix run priv/repo/seeds.exs`).
This is a contributor note, NOT an adopter instruction. Document in upgrade-1.x.md FAQ or
contributor section only — do not alarm adopters with it.

---

## Architecture Patterns

### System Architecture Diagram

```
CI demo job:
  mix ecto.create
    → creates DB "demo_app_test"
  mix ecto.migrate
    → [00000000000000_create_parapet_schema] CREATE SCHEMA IF NOT EXISTS parapet  ← NEW (Phase 55)
    → [20260525000000] CREATE TABLE "parapet"."parapet_action_items" (...)
    → [20260525000000] CREATE TABLE "parapet"."parapet_incidents" (...)
    → [20260525000001] ALTER TABLE "parapet"."parapet_action_items" ADD ...
    → [20260525000002] CREATE TABLE "parapet"."parapet_action_claims" (...)
  mix compile --no-optional-deps --warnings-as-errors  ← NEW (Phase 55, D-04)
  mix run priv/repo/seeds.exs
  mix test --only smoke
    → [smoke] operator HTTP route tests (existing)
    → [smoke] schema round-trip: create_incident → get_meta == schema_prefix()  ← NEW (Phase 55, D-02)
    → [smoke] six-table existence: information_schema.tables WHERE schema = schema_prefix()  ← NEW (Phase 55, D-03)

Docs graph:
  upgrade-1.x.md   ← sole home for Track A/B mechanics (D-05)
    ↑ routes from:
  migration-v1.md Step 3  ← new step (D-09)
  deployment.md Step 4 subsection  ← new (D-10)
  README.md Installation note  ← new (D-11)

HexDocs:
  mix.exs extras: [..., "docs/upgrade-1.x.md", ...]  ← D-08
  mix.exs groups_for_extras Guides: [..., "docs/upgrade-1.x.md", ...]  ← D-08
  mix docs --warnings-as-errors (ci.yml:48) validates cross-links
```

### Recommended File Structure for Phase 55

```
docs/
  upgrade-1.x.md       ← NEW (DOC-01)
examples/demo_app/
  priv/repo/migrations/
    00000000000000_create_parapet_schema.exs  ← NEW (infrastructure, unblocks demo CI)
  test/demo_app/
    operator_smoke_test.exs  ← EXTENDED (SAFE-03, two new tests)
.github/workflows/
  ci.yml               ← EXTENDED (one new step in demo job)
mix.exs                ← EXTENDED (extras + groups_for_extras)
docs/
  migration-v1.md      ← EXTENDED (insert Step 3, renumber 3-6 → 4-7)
  deployment.md        ← EXTENDED (add Step 4 schema subsection)
README.md              ← EXTENDED (Installation note)
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema existence query | Custom PG catalog query | `information_schema.tables` via `Ecto.Adapters.SQL.query!/3` on `DemoApp.Repo` | Catalog-level, sandbox-safe, injection-safe with parameterized `$1` binding |
| Prefix introspection | Inline `Application.compile_env` or `@prefix` literal | `Parapet.Evidence.schema_prefix()` | Single compile-time frozen source; leg-agnostic |
| Track A/B copy | New prose | Verbatim from 54-CONTEXT D-04/D-17/D-18 | Single-source rule (D-05/D-06) — doc and doctor must tell one story |
| HexDocs page registration | Manual link | `extras:` + `groups_for_extras` in mix.exs | Omitting either makes cross-refs broken under `--warnings-as-errors` |

---

## Common Pitfalls

### Pitfall 1: Forgetting the sentinel migration (most likely failure)
**What goes wrong:** `mix ecto.migrate` fails with `ERROR 3F000: schema "parapet" does not exist`
before any spine table is created.
**Why it happens:** The three demo migrations use `prefix: "parapet"` but no migration creates the
schema. Phase 53 edited migrations in place (D-10) and skipped adding the sentinel to the demo.
**How to avoid:** Add `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs`
as the FIRST task in Phase 55 (Wave 0 / Task 0).
**Warning signs:** `ERROR 3F000` on `mix ecto.create && mix ecto.migrate` in the demo.

### Pitfall 2: Asserting `== "parapet"` literally
**What goes wrong:** Test passes in the demo CI (which has no `PARAPET_SCHEMA_PREFIX` env) but
encodes a wrong claim and is fragile under future leg changes.
**Why it happens:** The demo CI doesn't exercise the public leg, so literal assertions aren't caught.
**How to avoid:** Always assert `== Parapet.Evidence.schema_prefix()`.
**Warning signs:** Hardcoded string `"parapet"` in any assertion inside `operator_smoke_test.exs`.

### Pitfall 3: Registering upgrade-1.x.md in only one of extras/groups_for_extras
**What goes wrong:** `mix docs --warnings-as-errors` fails because cross-references from
migration-v1.md or deployment.md cannot be resolved.
**Why it happens:** HexDocs requires both lists; one without the other is invisible or broken.
**How to avoid:** Edit mix.exs with a single task that adds to BOTH lists atomically.
**Warning signs:** `mix docs --warnings-as-errors` exit non-zero with "undefined reference" error.

### Pitfall 4: Placing the compile-out-clean step incorrectly in ci.yml
**What goes wrong:** Either `_build` cache isn't warm (step too early) or the step doesn't
actually catch host-app compile issues (step after smoke test is too late / wrong order).
**Why it happens:** Misreading D-04 as "anywhere in the demo job."
**How to avoid:** Place AFTER `mix deps.get`, BEFORE `mix test --only smoke`. Before `mix ecto.migrate`
is also fine since compile doesn't need the DB.
**Warning signs:** CI passes compile but smoke test fails due to uncompiled deps.

### Pitfall 5: Restating Track A/B mechanics in multiple docs
**What goes wrong:** Cross-doc drift — the doctor output says `--force`, the doc says `--compile-force`.
**Why it happens:** Copy-paste by paraphrase rather than verbatim lift.
**How to avoid:** Copy verbatim from 54-CONTEXT D-04/D-17. Every other doc routes, never restates.
**Warning signs:** Any migration mechanic string in migration-v1.md, deployment.md, or README
that doesn't match upgrade-1.x.md character-for-character.

---

## Code Examples

### SAFE-03 smoke test additions (legit pattern from prefix_propagation_test.exs)

```elixir
# Source: test/parapet/spine/prefix_propagation_test.exs:71-79 (house pattern)
test "schema prefix: evidence round-trip carries compiled prefix on returned struct" do
  {:ok, incident} =
    Parapet.Evidence.create_incident(%{
      title: "schema prefix smoke proof",
      state: "open"
    })

  assert Ecto.get_meta(incident, :prefix) == Parapet.Evidence.schema_prefix(),
         "create_incident round-trip: expected prefix #{inspect(Parapet.Evidence.schema_prefix())}, " <>
           "got #{inspect(Ecto.get_meta(incident, :prefix))}"
end

test "schema existence: all six spine tables exist in the configured schema" do
  prefix = Parapet.Evidence.schema_prefix() || "public"
  result =
    Ecto.Adapters.SQL.query!(
      DemoApp.Repo,
      "SELECT table_name FROM information_schema.tables WHERE table_schema = $1",
      [prefix]
    )

  found = result.rows |> Enum.map(fn [name] -> name end) |> MapSet.new()

  expected =
    MapSet.new([
      "parapet_action_items",
      "parapet_incidents",
      "parapet_timeline_entries",
      "parapet_tool_audits",
      "parapet_system_events",
      "parapet_action_claims"
    ])

  missing = MapSet.difference(expected, found)

  assert MapSet.size(missing) == 0,
         "Expected all six Parapet spine tables in schema #{inspect(prefix)}, " <>
           "missing: #{inspect(MapSet.to_list(missing))}"
end
```

### Sentinel migration (Wave 0, Task 0)

```elixir
# File: examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs
defmodule DemoApp.Repo.Migrations.CreateParapetSchema do
  use Ecto.Migration

  def up do
    execute("CREATE SCHEMA IF NOT EXISTS parapet")
  end

  def down do
    # Non-cascading: raises 2BP01 if any objects remain (fail-closed safety).
    # Roll back spine table migrations before rolling back this one.
    execute("DROP SCHEMA IF EXISTS parapet")
  end
end
```

### migration-v1.md Step 3 insert (sketch from 55-CONTEXT specifics)

```markdown
## Step 3: Choose your schema location (v1.7+)

Parapet 1.7 changed the default schema for evidence tables from `public` to `parapet`. Your
data never moves automatically — nothing runs behind your back. But existing adopters must
choose, or the first spine query fails with `relation "parapet.parapet_incidents" does not exist`.

**Track A — stay on `public`:** Add to `config/config.exs`:

```elixir
config :parapet, schema_prefix: nil
```

Then recompile:

```bash
mix deps.compile parapet --force
```

**Track B — move to `parapet`:** See [Upgrade Guide (1.x)](upgrade-1.x.md) for the reversible
`mix parapet.gen.schema.move` migration.

Either way, run `mix parapet.doctor` after your change to confirm the prefix resolves correctly.

For full copy-paste blocks, GRANTs, rollback instructions, and the FAQ, see
[Upgrade Guide (1.x)](upgrade-1.x.md).
```

---

## Validation Architecture

> `workflow.nyquist_validation` is absent from `.planning/config.json` — treated as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `examples/demo_app/test/test_helper.exs` |
| Quick run command | `cd examples/demo_app && mix test --only smoke` |
| Full suite command | `cd examples/demo_app && mix test` |

### Phase Requirements → Validation Map

| Req ID | Behavior | Validation Type | Automated Command | CI Gate |
|--------|----------|-----------------|-------------------|---------|
| SAFE-03 | Demo compile-out-clean | CI step | `cd examples/demo_app && mix compile --no-optional-deps --warnings-as-errors` | `demo` job (D-04) |
| SAFE-03 | Six tables exist in `parapet` schema | smoke test assertion | `mix test --only smoke` | `demo` job (D-03) |
| SAFE-03 | Round-trip `get_meta` == `schema_prefix()` | smoke test assertion | `mix test --only smoke` | `demo` job (D-02) |
| DOC-01 | `upgrade-1.x.md` exists and is well-formed | `mix docs --warnings-as-errors` | ci.yml:48 | `lint` job (D-08) |
| DOC-02 | Cross-references from migration-v1.md / deployment.md / README resolve | `mix docs --warnings-as-errors` | ci.yml:48 | `lint` job (D-08) |
| DOC-01 | Track A config block is present | manual content review | — | human verify |
| DOC-01 | `--force` recompile follows each config block | manual content review | — | human verify |
| DOC-01 | FAQ is present | manual content review | — | human verify |

### Coverage Notes

- **CI-enforced:** compile-out-clean (`--no-optional-deps --warnings-as-errors`) via demo job;
  `mix docs --warnings-as-errors` validates that `upgrade-1.x.md` is registered AND
  cross-reference links from migration-v1.md/deployment.md/README resolve.
- **Not CI-enforceable:** Doc-content quality (reassure→instruct tone, FAQ completeness,
  verbatim Track A/B copy). These are review items in SAFE-03 UAT.
- **Wave 0 gap:** The sentinel migration must exist before any `mix ecto.migrate` in the
  demo is attempted. This is the prerequisite for all SAFE-03 assertions.

### Sampling Rate

- **Per task commit:** `cd examples/demo_app && mix test --only smoke` (after sentinel added)
- **Per wave merge:** `cd examples/demo_app && mix test` + `mix docs --warnings-as-errors`
  (from lib root)
- **Phase gate:** Full library suite green (`mix test`) + demo smoke green + docs clean
  before `/gsd-verify-work`

### Wave 0 Gaps

- [x] `examples/demo_app/priv/repo/migrations/00000000000000_create_parapet_schema.exs` — the
  sentinel migration (CRITICAL: demo CI cannot run without this)
- [ ] No test framework install needed — ExUnit is the framework, already present

---

## Security Domain

> `security_enforcement` not explicitly set to `false` — treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | — (no new auth surface) |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Partial | `information_schema` query uses parameterized `$1` binding — no interpolation |
| V6 Cryptography | No | — |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via schema name in `information_schema` query | Tampering | Parameterized `$1` binding — schema_prefix() returns a compile-frozen value, but the query should still use binding for defense-in-depth |
| Documentation cross-link drift (doc tells different story from doctor output) | Repudiation | Single-source rule (D-05/D-06): upgrade-1.x.md is the only place mechanics live; verified by `mix docs --warnings-as-errors` |

---

## Assumptions Log

> All claims that could not be verified against live files in this session.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `information_schema.tables` is visible within Ecto Sandbox test (committed DDL is catalog-level, not rolled back with transaction) | Landmine 4 | Low — this is standard Postgres behavior; if wrong, the six-table assertion must use a non-sandboxed query or `DemoApp.Repo` bypass |
| A2 | The `DO $$` PL/pgSQL in Ecto migration `after_begin/0` fires before the `up` body | Pitfall 4 (compile ordering) | Not applicable; this is Ecto.Migration documented behavior |
| A3 | `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` (mix.exs:87) does not suppress warnings for upgrade-1.x.md cross-links | Landmine 3 | Low risk — that option is file-specific and upgrade-1.x.md must be registered properly |

**Verified claims (not in assumptions log):**
- `Parapet.Evidence.schema_prefix/0` exists at lib/parapet/evidence.ex:41 [VERIFIED]
- `Parapet.Evidence.create_incident/1` exists at lib/parapet/evidence.ex:75 [VERIFIED]
- `@moduletag :smoke` in operator_smoke_test.exs:4 [VERIFIED]
- Demo config.exs omits `schema_prefix` [VERIFIED]
- Demo test.exs omits `schema_prefix` [VERIFIED]
- `mix.exs extras:` block at L62-86 [VERIFIED]
- `groups_for_extras` `Guides:` at L89-101 [VERIFIED]
- CI demo job lines 118-167 [VERIFIED]
- `PARAPET_SCHEMA_PREFIX` confined to `test` job [VERIFIED]
- `lint` job compile-out-clean at L42-44 [VERIFIED]
- `mix docs --warnings-as-errors` at ci.yml:48 [VERIFIED]
- `release_gate` needs `[lint, test, demo]` at L170 [VERIFIED]
- migration-v1.md has exactly 6 steps [VERIFIED]
- deployment.md Step 4 = durable-evidence migrations [VERIFIED]
- No `docs/upgrade-1.x.md` exists yet [VERIFIED]
- No sentinel migration in demo app [VERIFIED]
- Prefix propagation test precedent at L77 and L138 [VERIFIED]

---

## Open Questions

1. **Nil-prefix handling in the six-table assertion**
   - What we know: `schema_prefix()` returns `nil` on the `public` CI leg; `information_schema.tables`
     expects a non-null `table_schema` string.
   - What's unclear: The demo CI only runs without `PARAPET_SCHEMA_PREFIX` (no matrix), so in CI
     `schema_prefix()` is always `"parapet"`. But the assertion should handle nil for correctness.
   - Recommendation: Use `Parapet.Evidence.schema_prefix() || "public"` in the query binding. This
     makes the assertion correct on both legs if ever tested that way.

2. **Whether smoke-test six-table assertion uses one combined query or six individual queries**
   - Claude's Discretion (55-CONTEXT). Both satisfy D-03. Recommendation: one combined query
     returning a MapSet diff is cleaner and produces a better failure message listing which tables
     are missing.

---

## Sources

### Primary (HIGH confidence)
- `examples/demo_app/test/demo_app/operator_smoke_test.exs` — verified current structure
- `examples/demo_app/config/config.exs` + `config/test.exs` — confirmed zero `schema_prefix`
- `.github/workflows/ci.yml` — exact line numbers verified for all CI steps
- `lib/parapet/evidence.ex` — `schema_prefix/0` at L41, `create_incident/1` at L75 verified
- `test/parapet/spine/prefix_propagation_test.exs` — house assertion pattern at L77/L138 verified
- `mix.exs` — `extras:` L62-86 + `groups_for_extras` L88-108 verified
- `docs/migration-v1.md` — current 6-step structure verified verbatim
- `docs/deployment.md` — Step 4 confirmed as durable-evidence migration section
- `examples/demo_app/priv/repo/migrations/` — all 3 files verified, no sentinel exists
- `.planning/phases/54-upgrade-path-doctor/54-CONTEXT.md` — D-04/D-17/D-18 verbatim text extracted
- `.planning/phases/55-demo-app-upgrade-docs/55-CONTEXT.md` — locked decisions D-01 through D-12
- `.planning/phases/53-generators-library-migrations/53-04-SUMMARY.md` — confirmed Phase 53 verified
  only the library test suite, NOT the demo CI job

### Secondary (MEDIUM confidence)
- `lib/parapet/spine/schema.ex` — `__prefix__/0` implementation verified, returns `@prefix` module attribute
- `lib/mix/tasks/parapet.gen.spine.ex` — sentinel migration body confirmed at L187-200

---

## Metadata

**Confidence breakdown:**
- Locked decision verification: HIGH — all 12 decisions checked against live files
- Drift flags: HIGH — sentinel absence confirmed by `find` with no results
- Track A/B copy strings: HIGH — extracted verbatim from 54-CONTEXT locked decisions
- CI line numbers: HIGH — read directly from ci.yml
- information_schema sandbox behavior: MEDIUM — standard Postgres behavior, not directly tested

**Research date:** 2026-07-01
**Valid until:** 2026-08-01 (stable domain)
