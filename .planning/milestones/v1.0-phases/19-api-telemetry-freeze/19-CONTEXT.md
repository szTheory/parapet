# Phase 19: API & Telemetry Freeze - Context

**Gathered:** 2026-05-25 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Freeze Parapet's public API and telemetry contract under three named tiers
(Stable / Experimental / Internal) plus a written deprecation policy, so every
downstream v1.0 artifact (docs, demo, integration guides) can reference a stable
surface. Scope is **declaring and enforcing** the existing surface — NOT adding,
removing, or redesigning public capabilities. Covers requirements STAB-01…STAB-06.
</domain>

<decisions>
## Implementation Decisions

### Tier System & Detection (STAB-01, STAB-04)
- **D-01:** Exactly three named tiers — **Stable / Experimental / Internal** (per
  `V1-STABILITY-FREEZE.md`). Stable = `> #### Stable {: .info}` ExDoc callout in the
  moduledoc + full semver protection. Experimental = `> #### Experimental {: .warning}`
  callout + one-release CHANGELOG notice before any breaking change. Internal =
  `Parapet.Internal.*` namespace or `@moduledoc false`; no guarantees.
- **D-02:** Tier detection mechanism = parse the ExDoc admonition callout out of each
  public module's `@moduledoc` via `Code.fetch_docs/1` (match `{: .info}`+"Stable" /
  `{: .warning}`+"Experimental"). The in-moduledoc callout is the **single source of
  truth** — no separate `@stability` module attribute, no external tier registry file.
- **D-03:** Harden `Mix.Tasks.Verify.PublicApi` so any documented public module
  (excluding `@moduledoc false`, `Parapet.Internal.*`, `Parapet.TestSupport.*`,
  `.Resolvable.`) that resolves to `:unclassified` causes a **non-zero exit**, making
  tier annotation mandatory for every future public surface.
- **D-04:** ⚠️ **Fix the `mix.exs` alias** (`"verify.public_api": ["docs --warnings-as-errors"]`,
  ~line 102) which currently **shadows** the task — today `mix verify.public_api` runs
  `mix docs`, so the gate logic is dead code at the CLI. Rewire so the command actually
  invokes `Mix.Tasks.Verify.PublicApi` (compose with `docs --warnings-as-errors` if both
  behaviors are wanted). Without this, STAB-04 is a silent false-green.

### Telemetry Contract Freeze (STAB-03, STAB-05)
- **D-05:** Freeze the **FULL** first-class `[:parapet, …]` event surface — the 6
  async/delivery families **plus** the ~19 additional literal families currently emitted
  but undocumented: journey (login/signup/billing±checkout/webhook), scoria
  (eval.completed/metrics±stale/resumed/expired/mcp.error), operator.queue.page,
  probe.run±stop/exception, ecto.query, http.request, oban.job, audit.created,
  deploy.mark, rulestead.flag_change. **The raw ecto/http/oban passthroughs ARE part
  of the frozen public contract** (user-confirmed — they carry the `:parapet` prefix
  and are Parapet's normalized surface).
- **D-06:** STAB-05 contract test (`test/telemetry_contract_test.exs`) asserts committed
  fixtures of (event family, measurement keys, metadata keys, outcome-atom vocabularies)
  and fails CI on drift. Seed the 6 async/delivery families from existing
  `Parapet.Telemetry.AsyncDelivery` attributes (`event_families/0`,
  `allowed_public_keys/1`, frozen vocab); add explicit fixture declarations for the
  remaining families.
- **D-07:** Pin parameterized/dynamic families by asserting against the **resolved**
  `AsyncDelivery.event_families/0` list, not the `[:parapet, :async, family]` source
  token (`family` is guard-bound to a fixed set). No runtime-dynamic event names ever;
  **NO configurable `:event_prefix`** (the Oban v2.10 yank lesson).
- **D-08:** Add a stability-freeze header to `docs/telemetry.md` — static event names,
  additive-only evolution of measurements/metadata, explicit "no configurable
  `:event_prefix`" rule — cross-linking `docs/stability.md`.

### Documentation & Policy (STAB-02)
- **D-09:** Create **`docs/stability.md`** (this exact filename per STAB-02 / ROADMAP,
  overriding the research doc's `stability-policy.md` name): enumerates the frozen
  surface with per-module tier assignments, the semver promise, breaking-vs-additive
  definitions, and the full deprecation cycle. Add it to `mix.exs` `extras:` (the
  `files:` whitelist already covers `docs` wholesale).
- **D-10:** Deprecation cycle: soft `@doc deprecated:` (+ CHANGELOG, no compile warning)
  → hard `@deprecated` for ≥1 minor (compile warning; replacement must already exist)
  → removal only at a major. Experimental tier: a single CHANGELOG entry suffices
  before a breaking change.

### Module Classification & Deprecation (STAB-01, STAB-06)
- **D-11:** Module classification follows the `V1-STABILITY-FREEZE.md` split.
  **Stable:** `Parapet`, `Parapet.Integration`, `Parapet.SLO.Provider`,
  `Parapet.SLO.SliceSpec`, `Parapet.Runbook`, `Parapet.Escalation.Policy`,
  `Parapet.Notifier`, `Parapet.Evidence`, `Parapet.Operator`, `Parapet.Deploy`, SLO
  starter packs, documented telemetry events. **Experimental:** `Parapet.MCP.*`,
  `Parapet.Automation.*`, `Parapet.Metrics.*`, `Parapet.Probe*`,
  `Parapet.Evidence.Archiver`, `Parapet.Evidence.Retrospective`,
  `Parapet.Integrations.*`. **Internal:** `Parapet.Internal.*`, `Parapet.TestSupport.*`.
- **D-12:** Namespaces the research did NOT classify get explicit tiers: `Parapet.Spine.*`
  (8 modules) → Experimental (Internal where already `@moduledoc false`),
  `Parapet.Capabilities` → Experimental, SLO StarterPacks → Stable. (Confirm exact
  per-module tier during planning; default by these rules.)
- **D-13:** `@doc since: "1.0.0"` on every Stable public function is **documentation-only**
  (ExDoc-rendered), NOT mechanically enforced by the gate — the gate enforces only the
  module-level tier callout. Scope ≈ 245 public functions, concentrated in the Stable set.
- **D-14:** **STAB-06 already satisfied** — `Parapet.SLO.define/2` already carries
  `@deprecated "Use a Parapet.SLO.Provider module instead"` (`lib/parapet/slo.ex:29`).
  Phase 19 only verifies the compile-time warning actually fires and documents the
  deprecation window in `docs/stability.md`.

### Claude's Discretion
- Exact per-module tier for any module not explicitly named above — default by
  namespace rules in D-11/D-12.
- Exact prose/wording of the ExDoc callouts, the `docs/stability.md` policy, and the
  `docs/telemetry.md` stability header.

### Folded Todos
None — no pending todos matched this phase.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/V1-STABILITY-FREEZE.md` — canonical design backing: 3-tier scheme,
  module classification, deprecation cycle, telemetry-as-API freeze, contract-test pattern.
- `.planning/research/V1-SUMMARY.md` — v1.0 milestone context.
- `lib/mix/tasks/verify.public_api.ex` — the task to extend for STAB-04 (tier detection).
- `mix.exs` — alias fix (~line 102), `extras:` registration (~lines 58-73), `files:` whitelist (~line 42).
- `lib/parapet/telemetry/async_delivery.ex` — existing contract module / fixture source
  (`event_families/0`, `allowed_public_keys/1`, frozen vocab attributes).
- `test/parapet/telemetry/async_delivery_test.exs` — existing contract-test pattern to generalize for STAB-05.
- `lib/parapet/slo.ex` — STAB-06 `@deprecated` (already in place at line 29).
- `docs/telemetry.md` — add stability-freeze header (STAB-03).
- `docs/stability.md` — to be created (STAB-02).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Verify.PublicApi` already loads app modules, filters the `Parapet.*` surface
  (excluding `Internal`/`TestSupport`/`.Resolvable.`), and reads docs via `Code.fetch_docs/1`
  + emits a JSON manifest — extend in place, don't rewrite.
- `Parapet.Telemetry.AsyncDelivery` is the only existing machine-readable contract module
  (6 families with frozen measurement/metadata/outcome vocab) — the template + fixture source.
- `test/parapet/telemetry/async_delivery_test.exs` already asserts against the resolved
  `event_families/0` list — generalize this pattern to all frozen families.
- `@deprecated` already present on `Parapet.SLO.define/2` — STAB-06 needs verification, not new code.

### Established Patterns
- Callout-in-moduledoc as single source of truth; module-granularity doc gate.
- `Parapet.Internal.*` namespace, `@moduledoc false`, and `Parapet.TestSupport.*` are the
  recognized exclusions from the public-API gate (existing PROJECT.md decisions).
- "Telemetry as API" is a hard project constraint — events carry semver guarantees
  (PROJECT.md Constraints, line ~161).
- Convention: code surfaces land before the docs that name them.

### Integration Points
- `mix.exs` alias + `extras:` + `files:` whitelist; CI runs `mix verify.public_api` as a gate.
- `docs/stability.md` ↔ `docs/telemetry.md` cross-links; both consumed by hexdocs and by
  later v1.0 phases (governance/docs, demo, guides).
</code_context>

<specifics>
## Specific Ideas

- **Load-bearing wiring bug:** the `mix.exs` `verify.public_api` alias shadows the real
  task and must be rewired (D-04) — easy to miss, breaks the whole STAB-04 gate if left.
- **Full-surface telemetry freeze** (~25 families incl. raw ecto/http/oban passthroughs),
  not just the 6 async/delivery families (D-05).
- Policy file is named exactly `docs/stability.md` (not `stability-policy.md`).
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope.

### Reviewed Todos (not folded)
None — no pending todos matched this phase.
</deferred>
