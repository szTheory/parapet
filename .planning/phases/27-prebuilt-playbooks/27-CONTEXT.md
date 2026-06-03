# Phase 27: Prebuilt Playbooks - Context

**Gathered:** 2026-05-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the six JTBD-MAP runbook templates as host-owned `Parapet.Runbook` DSL modules under `priv/templates/parapet.gen.runbooks/`. Two are guidance-only by design (Retry Storm, Suppression Drift — every obvious automated mitigation worsens the failure) and two of the capability-backed four already exist (Stalled Async via `:retry_async_item`, Dead-Letter Drain via `:requeue_dead_letter`). Phase 27 authors the **two net-new** capability-backed templates — Deploy-Tied Incident (`:revert_feature_flag`) and Cardinality Blowout (`:disable_metric_label`) — hardens the two guidance-only warnings to state *why* they're guidance-only, wires the two new templates into the existing `mix parapet.gen.runbooks` generator, and extends the generator test. Covers PB-01..PB-06.

Scope is **template authoring + guidance-warning hardening + generator wiring + generator-test extension**. NOT a new per-template CLI (`mix parapet.gen.runbook <name>` / `mix parapet.gen.recovery <NAME>` is Phase 29 ADOP-01). NOT a shipped reference `Parapet.Recovery` capability module. NOT the runnable demo scenario / seed (Phase 28 Demo Seed + CI Lane). NOT Stable-tier graduation (Phase 29 STAB-07). Templates ship under the Experimental-tier recovery surface established in Phases 23–26.
</domain>

<decisions>
## Implementation Decisions

### Scope — Reuse Existing, Author Only Two (PB-01..PB-06)

- **D-01:** Phase 27 authors exactly **two net-new** EEx templates: `priv/templates/parapet.gen.runbooks/deploy_tied_incident.ex.eex` (module suffix `DeployTiedIncident`, PB-05) and `priv/templates/parapet.gen.runbooks/cardinality_blowout.ex.eex` (module suffix `CardinalityBlowout`, PB-06). Snake_case file → CamelCase module suffix, matching the existing convention (`stalled_executor.ex.eex` → `StalledExecutor`).
- **D-02:** The four other phase-27 templates already exist from v0.10 and are **reused, not rewritten or renamed**:
  - PB-03 "Stalled Async" = existing `stalled_executor.ex.eex` (`kind: :capability, capability: :retry_async_item, target_kind: :async_item, requires_preview: true`).
  - PB-04 "Dead-Letter Drain" = existing `dead_letter.ex.eex` (`kind: :capability, capability: :requeue_dead_letter, target_kind: :async_item, requires_preview: true`).
  - PB-01 "Retry Storm" = existing `retry_storm.ex.eex` (`kind: :guidance, preview_only: true`).
  - PB-02 "Suppression Drift" = existing `suppression_drift.ex.eex` (`kind: :guidance, preview_only: true`).
  Do NOT rename the files or modules to match the ROADMAP's display names ("Stalled Async", "Dead-Letter Drain") — the existing names already satisfy the requirements and renaming breaks the generator test.

### Guidance-Only Hardening (PB-01, PB-02 — Success Criterion #2)

- **D-03:** The two guidance-only templates carry **no `capability:` key** — that structural absence is the "adopters cannot accidentally wire a capability into them" guarantee (success criterion #2). Keep them `kind: :guidance, preview_only: true` on every step.
- **D-04:** Strengthen the `warning:` text so each guidance-only template explicitly documents *why every obvious automated mitigation worsens the failure*:
  - `retry_storm.ex.eex` already states "executing retries on storming items will worsen worker exhaustion" (`:14`) — keep/lightly reinforce so the "no safe automated mitigation" framing is unambiguous.
  - `suppression_drift.ex.eex` warnings currently focus on on-call readiness (`:14`, `:24`) — add/reframe a warning that explains the guidance-only rationale (automated clearing could mass-trigger escalations or re-suppress incorrectly; the safe path is operator review). Plan-phase picks exact copy.

### Generator Interface (PB-01..PB-06 — Success Criterion #1)

- **D-05:** Wire the two new templates into the **existing** `mix parapet.gen.runbooks` task (`lib/mix/tasks/parapet.gen.runbooks.ex`) by appending two more `Igniter.copy_template(...)` calls (mirroring the existing seven, `on_exists: :skip`, copying into `lib/<app>/parapet/runbooks/deploy_tied_incident.ex` and `.../cardinality_blowout.ex`). This is the established "fixed host-owned runbook catalog" pattern (`@moduledoc`, `:3`).
- **D-06:** Do **NOT** build a new per-template-selectable CLI (`mix parapet.gen.runbook <name>` with an argument). The ROADMAP success-criterion phrasing `mix parapet.gen.runbook retry_storm` is illustrative of "an adopter generates a template," not a literal new CLI contract. Per-template scaffolding is Phase 29 ADOP-01 (`mix parapet.gen.recovery <NAME>`), explicitly deferred in `24-CONTEXT.md` D-20 and `25-CONTEXT.md` D-22. Generating the full catalog (then deleting unwanted modules) is the v1.1 contract.

### Capability Reference Model — Atom-Only, No Reference Impl (PB-05, PB-06 — Success Criterion #1, #3)

- **D-07:** The two new capability templates reference their capability by **atom id only** (`capability: :revert_feature_flag` and `capability: :disable_metric_label`). Both atoms are already in the `@valid_capabilities` allowlist (`lib/parapet/capabilities.ex:14-20`, widened in Phase 24). The `Parapet.Runbook` DSL does **not** compile-validate `capability:` against the allowlist (no allowlist reference in `lib/parapet/runbook.ex`) — templates compile cleanly regardless, with zero module-level optional-dep coupling. This is how "compiles cleanly under `if Code.ensure_loaded?(HostDep)`" (criterion #1) is satisfied trivially: the runbook template names a capability *atom*, never a host module, so there is no optional dep to guard at the template layer.
- **D-08:** Phase 27 ships **NO** reference `Parapet.Recovery` capability implementation module. The host owns the `preview/2`/`execute/2` impl (with its own `Code.ensure_loaded?(HostDep)` guard). Point the adopter at the canonical wiring target via **guidance/warning text + a moduledoc comment** in each new template:
  - Deploy-Tied Incident → Rulestead as the canonical `:revert_feature_flag` wiring target (PB-05).
  - Cardinality Blowout → the existing cardinality analyzer surface (`mix parapet.doctor cardinality` / `Parapet.Metrics.Validator`) as the `:disable_metric_label` reference (PB-06).
  A runnable reference impl is Phase 28 demo-seed / Phase 29 ADOP-03 docs territory, not Phase 27.

### Preview → Confirm Proof Boundary (PB-03, PB-04 — Success Criterion #3)

- **D-09:** Phase 27 proves the capability templates "demonstrate the Preview → Confirm flow against realistic preview output (count, target_refs, preconditions, warnings, summary)" **structurally**: each capability step declares `requires_preview: true` + `target_kind:` + a `warning:`, and the documented preview-shape the step targets carries the five fields. The runbook *template* declares the step; the preview *output map* shape is the host capability's `preview/2` return (the operator path that renders it lives at `lib/parapet/operator.ex` confirm/preview surface, untouched here).
- **D-10:** The runnable demo scenario (seeded stalled job / seeded DLQ entries, a live LiveView Preview → Confirm against real data) is **Phase 28 (Demo Seed + CI Lane)**, per the PB-03/PB-04 requirement text and the ROADMAP Phase 28 title. Phase 27 does NOT seed demo data or wire a running end-to-end flow.

### Tests + Packaging (Success Criterion #1, #4)

- **D-11:** Extend `test/mix/tasks/parapet.gen.runbooks_test.exs` with assertions for the two new templates, mirroring the existing assertion shape (`:44-99`): file present under `lib/test/parapet/runbooks/`, module `defmodule Test.Parapet.Runbooks.DeployTiedIncident`/`...CardinalityBlowout`, the `capability: :revert_feature_flag`/`capability: :disable_metric_label` line, and `warning:`. Same `Igniter.Test` content-assertion approach (`async: true`).
- **D-12:** No `mix.exs` changes. The `files:` whitelist already ships `priv/templates/**` and `lib/mix/tasks/**`; no new deps. Phase 27 is pure template + generator + test work.
- **D-13:** Success criterion #4 ("adopters can map any of the six templates to a specific SLO or alert name using the existing `Parapet.Runbook` DSL without modification") is satisfied by reusing the existing DSL unchanged — the templates are ordinary `use Parapet.Runbook` modules; mapping to an SLO/alert name uses the existing mapping mechanism. No DSL changes in Phase 27.

### Claude's Discretion

- Exact `warning:`/`guidance:` prose for the two new templates and the reframed `suppression_drift` warning (D-04, D-08) — must carry the required rationale/wiring-pointer, but wording is open.
- Exact step ids, labels, descriptions, and step count for the two new templates — should mirror the 3-step investigate → mitigate → verify shape of the existing capability templates (`stalled_executor`, `dead_letter`), but the concrete steps are open.
- Whether the moduledoc wiring pointer (D-08) lives in the module `@moduledoc`, a leading comment, or step `guidance:` text — plan-phase picks; all satisfy PB-05/PB-06.
- Exact `target_kind:` value for the two new capability steps (e.g., `:feature_flag` / `:metric_label`) — plan-phase picks an idiomatic atom.

### Folded Todos

None — no pending todos matched this phase (`todo.match-phase 27` returned 0).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/REQUIREMENTS.md` — PB-01 (`:47`), PB-02 (`:48`), PB-03 (`:49`), PB-04 (`:50`), PB-05 (`:51`), PB-06 (`:52`); Phase 27 traceability (`:124-129`).
- `.planning/ROADMAP.md` — Phase 27 entry ("Prebuilt Playbooks") with the four success criteria; dependency on Phase 26; Phase 28 ("Demo Seed + CI Lane") is the downstream demo phase.
- `.planning/phases/24-recovery-behaviour-capability-allowlist/24-CONTEXT.md` — D-09 (5-atom allowlist incl. `:revert_feature_flag`, `:disable_metric_label`); D-19 (templates are Phase 27); D-20 (per-template `mix parapet.gen.recovery` scaffolder deferred to Phase 29).
- `.planning/phases/25-wire-confirm-through-claimservice-preview-confirm-ux/25-CONTEXT.md` — D-21 (templates deferred to Phase 27); D-22 (Igniter scaffolder is Phase 29); the operator Confirm/Preview path the capability templates' preview output flows through.
- `.planning/research/SUMMARY.md` — v1.1 research synthesis (JTBD-MAP failure modes, guidance-vs-capability rationale).
- `.planning/research/PITFALLS.md` — guidance-only rationale ("every obvious automated mitigation worsens the failure" for retry storm / suppression drift).
- `.planning/threads/actionable-recovery-design.md` — v1.1 seed thread.
- `priv/templates/parapet.gen.runbooks/` — the template catalog directory. Existing reused templates: `retry_storm.ex.eex` (PB-01), `suppression_drift.ex.eex` (PB-02), `stalled_executor.ex.eex` (PB-03, `:22` capability), `dead_letter.ex.eex` (PB-04, `:22` capability). New templates land here: `deploy_tied_incident.ex.eex`, `cardinality_blowout.ex.eex`. (`provider_outage.ex.eex`, `callback_delay.ex.eex`, `partial_backlog_drain.ex.eex` exist but are out of Phase-27 scope.)
- `lib/mix/tasks/parapet.gen.runbooks.ex` — the generator task; `:32-109` is the `Igniter.copy_template` chain; append two calls for the new templates (`on_exists: :skip`, `lib_dir` = `lib/<app>/parapet/runbooks`).
- `test/mix/tasks/parapet.gen.runbooks_test.exs` — `:44-99` the per-template assertion pattern to extend for the two new templates.
- `lib/parapet/runbook.ex` — `:34-42` the documented step opts (`:kind`, `:capability`, `:target_kind`, `:requires_preview`, `:preview_only`, `:guidance`, `:warning`); `:45-59` the `step/2` macro. No allowlist validation here — templates compile regardless of allowlist membership.
- `lib/parapet/capabilities.ex` — `:14-20` `@valid_capabilities` (5 atoms incl. the two new template targets); `:29` `register_recovery/2` allowlist guard (the only allowlist enforcement, at registration time, not template compile time).
- `lib/parapet/operator.ex` — the Confirm/Preview path that renders the capability step's preview output (count/target_refs/preconditions/warnings/summary). **Read-only context** — Phase 27 does not touch it.
- `mix.exs` — `files:` whitelist already covers `priv/templates/**` and `lib/mix/tasks/**`. No changes expected.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Four of six templates already exist** in `priv/templates/parapet.gen.runbooks/` with the correct shape — `stalled_executor.ex.eex` (`:retry_async_item`), `dead_letter.ex.eex` (`:requeue_dead_letter`), `retry_storm.ex.eex` (guidance), `suppression_drift.ex.eex` (guidance). The two new templates copy the 3-step investigate → mitigate → verify shape of `stalled_executor`/`dead_letter`.
- **The generator** (`lib/mix/tasks/parapet.gen.runbooks.ex`) is a flat `Igniter.copy_template` chain; adding a template is a mechanical two-call append. `assigns` (`app_name`, `base_name`, `module_prefix`) and `lib_dir` are already computed.
- **The generator test** (`parapet.gen.runbooks_test.exs:44-99`) has a copy-paste-per-template assertion block; extend it identically for the two new files.
- **The Runbook DSL** (`lib/parapet/runbook.ex`) already supports every key the new templates need (`kind`, `capability`, `target_kind`, `requires_preview`, `preview_only`, `guidance`, `warning`) — no DSL change required.
- **Both new capability atoms are already allowlisted** (`capabilities.ex:18-19`) from Phase 24 — the templates reference valid ids out of the box.

### Established Patterns

- **EEx template shape**: `defmodule <%= inspect(@module_prefix) %>.<Name> do / use Parapet.Runbook / title(...) / description(...) / step(...)`. Snake_case file → CamelCase module suffix.
- **3-step recovery template**: investigate (`:manual, :guidance, preview_only: true`) → mitigate (`:mitigation, :capability, capability:, target_kind:, requires_preview: true`) → verify (`:manual, :guidance, preview_only: true`). Each mitigation step carries a `warning:`.
- **Guidance-only template**: every step is `kind: :guidance, preview_only: true`, no `capability:` key; the `warning:` documents why no safe automated mitigation exists.
- **Fixed-catalog generator**: `mix parapet.gen.runbooks` copies the whole catalog with `on_exists: :skip`; adopters delete unwanted modules. No per-template selection (that's Phase 29 ADOP-01).
- **Allowlist enforcement is at registration, not template compile**: the `id in @valid_capabilities` guard lives in `Parapet.Capabilities.register_recovery/2`; runbook templates only name the atom.

### Integration Points

- New templates → `mix parapet.gen.runbooks` generator (two `copy_template` calls) → host's `lib/<app>/parapet/runbooks/`.
- `capability: :revert_feature_flag` / `:disable_metric_label` atoms → host's `Parapet.Recovery` capability impl (host-owned, out of Phase-27 scope) → `Parapet.Capabilities.register_recovery/2` allowlist guard.
- Capability step's `requires_preview: true` → operator Confirm/Preview path (`lib/parapet/operator.ex`, untouched) → preview output map (count/target_refs/preconditions/warnings/summary) rendered in the demo LiveView (Phase 28 seeds the runnable scenario).
- Generator test extension → `Igniter.Test` content assertions (no compilation of generated modules; matches the existing test's approach).
</code_context>

<specifics>
## Specific Ideas

- **New template file names are `deploy_tied_incident.ex.eex` and `cardinality_blowout.ex.eex`** (snake_case), producing module suffixes `DeployTiedIncident` and `CardinalityBlowout`.
- **The two new templates reference capability atoms only** (`:revert_feature_flag`, `:disable_metric_label`) — never a host module — so they compile with zero optional-dep coupling.
- **Deploy-Tied Incident points at Rulestead** as the canonical `:revert_feature_flag` wiring target; **Cardinality Blowout points at the cardinality analyzer** (`mix parapet.doctor cardinality` / `Parapet.Metrics.Validator`) for `:disable_metric_label` — both as guidance/comment pointers, not shipped impls.
- **No file/module renames** of the four reused templates — the ROADMAP display names ("Stalled Async", "Dead-Letter Drain") are descriptive, not filenames.
- **Phase 27 is one coherent PR**: two new templates + suppression_drift warning hardening + two generator `copy_template` calls + extended generator test, landing together.
- **No `mix.exs` changes, no new deps, no DSL changes, no operator-path changes.**
</specifics>

<deferred>
## Deferred Ideas

- **Runnable demo scenario / seed** (seeded stalled job, seeded DLQ entries, live LiveView Preview → Confirm) — Phase 28 (Demo Seed + CI Lane).
- **CI lane for the recovery loop** — Phase 28.
- **Per-template-selectable generator** (`mix parapet.gen.runbook <name>`) / `mix parapet.gen.recovery <NAME>` Igniter scaffolder — Phase 29 (ADOP-01).
- **Shipped reference `Parapet.Recovery` capability impl** wired to Rulestead / the cardinality analyzer — Phase 28 demo-seed or Phase 29 (ADOP-03 `docs/recovery-actions.md`).
- **`mix parapet.doctor` adoption-signal check** (runbook-references-unknown-capability flagging) — Phase 29 (ADOP-02).
- **`Parapet.Recovery` Experimental → Stable graduation** — Phase 29 (STAB-07).
- **Renaming the four reused templates** to match ROADMAP display names — rejected; breaks the generator test for no adopter benefit.

### Reviewed Todos (not folded)

None — `todo.match-phase 27` returned 0 matches.
</deferred>
</content>
</invoke>
