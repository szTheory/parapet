# Phase 56: Contract & Release Hardening - Context

**Gathered:** 2026-07-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Final phase of v1.7 (Postgres Schema Isolation). Close the milestone by proving the
**public API and telemetry contracts are frozen** despite the schema-prefix change, and
frame the change **honestly** as additive for existing installs. Scope is exactly three
requirements: SAFE-01 (`verify.public_api` clean), SAFE-02 (telemetry contract + Ecto
`:source` invariance), SAFE-04 (`feat` CHANGELOG / release-note framing).

**In scope:** re-asserting the two frozen contracts as milestone done-criteria, adding the
one missing behavioral assertion (Ecto `:source` = bare table name), and writing the
CHANGELOG entry. **Out of scope:** any new public export, any new telemetry event, a
standalone "milestone gate" runner, and the `mix ci` alias (deferred to v1.8 / CI-01).
</domain>

<decisions>
## Implementation Decisions

> Areas B/C/D were "Confident/Likely" from codebase evidence and locked as-is. Area A (the
> CHANGELOG framing) was the one genuine fork — the SAFE-04 literal banner "No action
> required for existing installs" is factually false as an unqualified claim (the mechanism
> below proves it), so the user selected the **two-part banner** reconciliation.

### A. SAFE-04 — CHANGELOG `feat` entry framing (the crux)

- **D-01 (mechanism — why the literal banner is false):** `lib/parapet/spine/schema.ex:81`
  freezes `@raw_prefix = Application.compile_env(:parapet, :schema_prefix, "parapet")`. An
  existing adopter with **no** `config :parapet, :schema_prefix` line compiles `@prefix ==
  "parapet"`, but their pre-1.7 evidence tables live in `public`. A do-nothing upgrader who
  recompiles therefore hits `relation "parapet.parapet_incidents" does not exist` on the
  first spine query. `docs/upgrade-1.x.md` states this 4× (lines 13, 20-24, 182-185, 226-229)
  and its H2 is literally "## Action Required for Existing Adopters". Phase-55 D-07
  (`55-CONTEXT.md:84-90`) and Phase-54 D-18 deliberately chose "action required" framing and
  **forbid** "no action required." UPG-05's "no action" is a **new-install** promise only.
  ⇒ The unqualified string "No action required for existing installs" must **NOT** be written
  verbatim.

- **D-02 (LOCKED — two-part banner):** The `feat` CHANGELOG entry uses a **two-part** structure:
  1. **Headline reassurance, true for everyone:** *"No data is migrated automatically — your
     evidence tables never move unless you choose."* (This is the honest form of SAFE-04's
     reassurance — no forced migration, semver-minor, additive; public API & telemetry
     unchanged.)
  2. **Distinct "action required" line for existing adopters:** they must add
     `config :parapet, schema_prefix: nil` and recompile to keep tables in `public` (Track A),
     with a link to `docs/upgrade-1.x.md` for the full Track A / Track B guide.
  Rationale: satisfies SAFE-04's *spirit* (additive, reassuring, semver-minor) AND Phase-54
  D-18 / Phase-55 D-07's *letter* (honest "action required"). Reference wording:
  ```markdown
  ### Features

  * **schema:** spine tables now live in a dedicated `parapet` Postgres schema by default
    (semver-minor, additive — public API & telemetry unchanged).

    **No data is migrated automatically — your evidence tables never move unless you choose.**

    Existing adopters: one action is required to keep your tables in `public` — add
    `config :parapet, schema_prefix: nil` and recompile. See the full Track A / Track B guide
    in docs/upgrade-1.x.md.
  ```
- **D-03 (single-story consistency):** The CHANGELOG copy must tell the **same** story as
  `docs/upgrade-1.x.md` and the doctor remediation — no new mechanics restated (per Phase-55
  D-05 single-source-of-truth); link out for Track A/B detail. The matching **release-note
  callout** (release-please generates the GitHub release body from this `feat` entry, `release-type: elixir`)
  inherits the same two-part text — verify the rendered release note carries both parts.
- **D-04 (Conventional Commit type):** Commit type is `feat` (semver-minor bump), scope
  `schema`, consistent with `CHANGELOG.md` house format (Keep a Changelog + Conventional
  Commits + release-please).

### B. SAFE-01 — `verify.public_api` (re-assert as done-criterion; no new prod code)

- **D-05:** SAFE-01 requires **no new production or task code**. `mix verify.public_api` is
  already green and CI-gated (`.github/workflows/ci.yml:56`). The compile-time prefix attribute
  (`@schema_prefix`/`@prefix`, `lib/parapet/spine/schema.ex:86,95`) is **not** an export; the
  only prefix-related public export — `Parapet.Evidence.schema_prefix/0` (`@doc since: "1.0.3"`,
  `evidence.ex:41`) — is a **pre-existing** Stable helper already in the frozen manifest
  (`priv/parapet/public_api_stable.json:46`). Manifest last touched Phase 52; Phases 53-55
  added zero exports.
- **D-06:** The phase's job is to **run it and prove zero `--write` drift**, then **pin that
  fact as a milestone done-criterion** (recorded in the VERIFICATION/UAT artifacts, D-10). If
  the recomputed manifest drifts, that signals an accidental contract expansion from 53-55 —
  the leaked export must be walled off (`Parapet.Internal.*` or `@moduledoc false`), **not**
  blessed with `--write`.

### C. SAFE-02 — telemetry contract (re-assert families) + Ecto `:source` (NEW assertion)

- **D-07 (re-assert half):** "No `[:parapet, :schema, …]` event" and "telemetry contract stays
  green" is a **re-assert**. `test/telemetry_contract_test.exs` pins exactly 35 families
  (`:212-216`), none a `schema` family; adding one would break the length assertion. No new
  event is introduced this phase.
- **D-08 (NEW assertion — LOCKED to add):** The claim "Ecto query telemetry `:source` (the bare
  table name) is unaffected by the prefix" is **currently unproven by any test** and MUST get a
  new behavioral assertion. Existing fixture `[:parapet, :ecto, :query] => [:source]`
  (`telemetry_contract_test.exs:168`) only pins `:source` as a *metadata key*, not its *value*.
  `lib/parapet/metrics/ecto.ex:79` reads `source = Map.get(metadata, :source, "_raw")`; Ecto
  supplies `:source` from `schema.__schema__(:source)` = the bare table name, structurally
  prefix-free.
- **D-09 (assertion location → behavioral, in `metrics/ecto_test.exs`):** Add the new assertion
  to `test/parapet/metrics/ecto_test.exs`: drive a **real spine query** under the default
  `parapet` prefix, capture the emitted `:source`, assert `== "parapet_incidents"` (bare, no
  `parapet.` schema qualifier). This is behavioral (Alternative 1) and strongest; the current
  ecto_test only uses synthetic sources (`"users"`, `"accounts"`, `"_raw"`). Optionally also
  add a documenting static note in `telemetry_contract_test.exs`, but the behavioral test is
  the required proof. Guards against a future refactor leaking `parapet.parapet_incidents` into
  Prometheus `:source` and silently doubling series cardinality.

### D. Milestone done-criteria gating

- **D-10:** "Asserted as a milestone done-criterion" = record the three checks
  (verify.public_api zero-`--write`; telemetry contract green + no schema event; new `:source`
  bare-name assertion) in this phase's `56-VERIFICATION.md` / `56-UAT.md` artifacts. The
  enforcement backstop is the **already-existing** CI (`ci.yml:56` for public_api; the ExUnit
  suite for the telemetry contract + new ecto assertion). **No** new bespoke "milestone gate"
  mix task, and **no** `mix ci` alias (explicitly deferred to v1.8 / CI-01, roadmap `:184` —
  introducing it here would front-run a scheduled milestone).

### Claude's Discretion
- Exact ExUnit test-name/moduletag for the new `:source` assertion (D-09), and whether to
  additionally add the optional documenting note in `telemetry_contract_test.exs`.
- Exact prose of the VERIFICATION/UAT done-criterion records (D-10), following prior-phase
  artifact shape.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — SAFE-01, SAFE-02, SAFE-04 (+ SAFE-03 context, already done in 55)
- `docs/upgrade-1.x.md` — the shipped "Action Required for Existing Adopters" guide; the
  CHANGELOG (D-02/D-03) MUST stay consistent with it and link to it, never restate mechanics
- `CHANGELOG.md` — "Unreleased" section + house format (Keep a Changelog + Conventional
  Commits + release-please `release-type: elixir`)
- `lib/parapet/spine/schema.ex` — the `@raw_prefix`/`@prefix` compile-time mechanism (D-01)
- `lib/mix/tasks/verify.public_api.ex` + `priv/parapet/public_api_stable.json` — frozen public
  API manifest + drift gate (D-05/D-06)
- `test/telemetry_contract_test.exs` — 35 pinned families + the `[:parapet, :ecto, :query] =>
  [:source]` fixture (D-07/D-08)
- `lib/parapet/metrics/ecto.ex` + `test/parapet/metrics/ecto_test.exs` — `:source` derivation
  and where the new bare-name assertion lands (D-08/D-09)
- `.github/workflows/ci.yml` — existing `verify.public_api` gate (`:56`) and test suite (the
  done-criterion backstop, D-10)
- `.planning/phases/55-demo-app-upgrade-docs/55-CONTEXT.md` (D-05, D-07) and Phase-54 D-18 —
  the locked "action required" framing the CHANGELOG must not contradict
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix verify.public_api` task + `public_api_stable.json` manifest + drift gate already exist
  and are CI-wired — SAFE-01 reuses them wholesale, adds nothing.
- `test/telemetry_contract_test.exs` already pins the full 35-family contract with a length
  assertion that auto-fails on any added event — SAFE-02's "no schema event" is enforced for free.
- `Parapet.Evidence.schema_prefix/0` is the sole prefix-related public export, already Stable
  and already in the frozen manifest.

### Established Patterns
- Compile-time-only prefix (`@schema_prefix` attribute) means it is structurally impossible for
  the prefix to appear in the exported surface (SAFE-01) or in Ecto's `__schema__(:source)`
  (SAFE-02) — the phase proves an invariant that the architecture already guarantees.
- Done-criteria are pinned as automated ExUnit/CI checks recorded in VERIFICATION/UAT
  artifacts, not manual gates (repo memory: "Automate UAT into CI").

### Integration Points
- CHANGELOG `feat` entry → release-please generates the v1.7 semver-minor bump + GitHub release
  note body (D-03).
- New `:source` assertion rides the existing ExUnit suite in CI — no new job needed (D-10).
</code_context>

<specifics>
## Specific Ideas

- Reference CHANGELOG wording locked in D-02 (two-part banner) — use verbatim as the starting
  point, adjusting only to match the exact final config-key spelling used elsewhere in the repo.
- New Ecto `:source` assertion must assert the **bare** `"parapet_incidents"` (no `parapet.`
  qualifier) — that exact negative is the whole point (D-08/D-09).
</specifics>

<deferred>
## Deferred Ideas

- `mix ci` alias chaining `verify.public_api` + telemetry test — deferred to **v1.8 / CI-01**
  (roadmap `:184`); do NOT add here.
- Any standalone aggregate "milestone gate" mix task — unnecessary; CI already runs the checks.
- Telemetry drift gate (`telemetry_stable.json` mirroring `public_api_stable.json`) — that is
  **v1.9 / TELEM-01**, not this phase.

### Reviewed Todos (not folded)
None — `todo.match-phase 56` returned zero matches.
</deferred>
