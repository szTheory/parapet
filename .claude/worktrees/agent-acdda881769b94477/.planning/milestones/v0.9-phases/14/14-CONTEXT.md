# Phase 14: backstop-generated-operator-ui-closure-proof - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Extend the closure-proof chain so future milestone reruns catch generated operator UI runtime regressions. This phase adds an explicit rerunnable backstop for the generated resolve action, promotes that proof into the active Phase 3, Phase 7, and Phase 12 verification hierarchy, and reconciles live roadmap/requirements/state surfaces so they reflect the repaired runtime truth without rewriting historical audit artifacts. It does not widen into another runtime feature phase, and it does not reopen the deferred resolved-history public-seam cleanup unless proof honesty truly requires it.

</domain>

<decisions>
## Implementation Decisions

### Canonical proof ownership
- **D-01:** Phase 3 remains the canonical runtime proof owner for generated operator UI behavior, including queue-side resolve lifecycle and the generated resolve regression lane.
- **D-02:** Phase 14 should strengthen and explicitly name the existing Phase 3 proof lane, then promote that proof upward into Phase 7 and Phase 12 as closure/index surfaces rather than inventing a competing top-level runtime proof artifact.
- **D-03:** Closure phases should index canonical runtime proof and reconcile direct truth surfaces; they should not duplicate runtime evidence text as if they independently own behavior proof.

### Generated UI seam posture
- **D-04:** `Parapet.Operator` remains the sole canonical mutation seam for generated operator actions; generated templates must not encode alternate resolve semantics or UI-local lifecycle shortcuts.
- **D-05:** The generated operator UI should remain thin, host-owned wiring and presentation over the public operator seam, consistent with the repo's embedded-library posture and Phoenix maintainer expectations.
- **D-06:** Phase 14 should continue to treat generator/source-contract coverage as part of the real proof contract because this regression class is template drift as much as runtime drift.

### Backstop lane design
- **D-07:** The canonical resolve-flow backstop remains a two-layer proof lane: one cheap source-contract/generator assertion that generated queue resolve wires to `Parapet.Operator.resolve_incident/2`, plus one narrow generated-runtime lifecycle test proving queue removal and resolved-history visibility.
- **D-08:** Phase 14 should not introduce a browser E2E harness or a second bespoke proof lane unless the existing targeted ExUnit lane becomes insufficient to catch the real regression class.
- **D-09:** The backstop should be named and surfaced clearly enough in verification and validation artifacts that future milestone reruns fail obviously when generated resolve wiring drifts.

### Truth-surface reconciliation
- **D-10:** Once a repaired runtime seam has fresh canonical proof, active truth surfaces should be reconciled even if a fresh milestone audit rerun has not yet happened.
- **D-11:** `SCALE-01.c` and `AC-03` should move out of pending in live tracker surfaces now that Phase 13 repaired the seam and Phase 3 canonical proof reflects the rerun.
- **D-12:** `milestone closure readiness` remains pending until Phase 14 lands because this phase exists to close the remaining proof-chain coverage gap.
- **D-13:** Historical audit artifacts and execution summaries must remain historical; superseding truth should be additive and explicit rather than rewriting prior chronology.
- **D-14:** The active Phase 12 closure-proof surfaces live in `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md` and `12-VALIDATION.md`, and Phase 14 should reconcile them as active hierarchy inputs rather than treating them as frozen historical summaries.

### Maintainer workflow and shift-left doctrine
- **D-15:** Low-impact artifact-reconciliation choices in this repo should be auto-decided in assumptions mode and recorded in context, with escalation reserved for the impact boundaries already locked in `AGENTS.md`.
- **D-16:** The maintainer-facing model should stay least-surprise and easy to teach: `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md` tell what is true now; `VERIFICATION.md` is canonical proof; `VALIDATION.md` is the proof map; milestone audits and summaries are dated historical evidence.
- **D-17:** `docs/operator-ui.md` is not a milestone truth surface; it should change in this phase only if the named proof lane or operator-facing wording materially changes.

### Deferred runtime debt boundary
- **D-18:** The duplicated resolved-history read path in the generated template remains deferred runtime debt and should stay out of Phase 14 unless proof honesty or testability makes it impossible to keep deferred.

### the agent's Discretion
- Exact wording of the re-verified Phase 3, Phase 7, and Phase 12 proof artifacts, provided they clearly preserve canonical proof ownership and do not imply that a fresh milestone audit rerun already passed.
- Exact updates to `ROADMAP.md`, `REQUIREMENTS.md`, and `STATE.md`, provided they tell the current truth coherently and preserve the historical boundary around `.planning/v0.9-MILESTONE-AUDIT.md`.
- Exact naming of the resolve-flow backstop lane in proof artifacts, provided the lane is obviously rerunnable and easy for future maintainers and GSD automation to find.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 14 scope and milestone gap
- `.planning/ROADMAP.md` — Phase 14 scope, explicit proof-coverage deliverables, and live milestone plan status.
- `.planning/REQUIREMENTS.md` — live requirement truth rows for `SCALE-01.c`, `AC-03`, and `milestone closure readiness`.
- `.planning/STATE.md` — live workflow position and current milestone status that must reconcile to the repaired proof chain.
- `.planning/v0.9-MILESTONE-AUDIT.md` — historical audit artifact naming the generated resolve regression and the missing proof-chain backstop that Phase 14 closes.

### Prior locked context shaping this phase
- `AGENTS.md` — recommendation-first posture, narrow escalation thresholds, and preference for shifting low-impact decisions left.
- `.planning/config.json` — repo default `workflow.discuss_mode = "assumptions"` and auto-advance workflow posture.
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-CONTEXT.md` — locked decisions on canonical Phase 3 proof ownership, the two-layer backstop, and deferred resolved-history cleanup.
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-RESEARCH.md` — supporting analysis for the generated resolve seam, proof lane choice, and anti-patterns.
- `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md` — closure-phase proof-index doctrine and historical-boundary rules.
- `.planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md` — proof-hierarchy honesty and bounded proof-lane posture.
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — repo preference for deterministic defaults, low-routine questioning, and explicit certainty boundaries.

### Canonical proof and active closure surfaces
- `.planning/v0.9-phases/3/VERIFICATION.md` — canonical runtime proof for generated operator UI paging, resolve lifecycle, and advisory benchmark posture.
- `.planning/v0.9-phases/3/03-VALIDATION.md` — active sampling map and quick-run command for the generated resolve regression lane.
- `.planning/v0.9-phases/7/VERIFICATION.md` — active closure proof index that should point at the canonical Phase 3 proof chain.
- `.planning/v0.9-phases/7/07-VALIDATION.md` — Phase 7 closure sampling map referencing the generated resolve regression lane.
- `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md` — active closure-proof verification surface for milestone readiness.
- `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VALIDATION.md` — active closure-proof validation map for Phase 12.
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-01-SUMMARY.md` — execution record for repairing the generated queue resolve seam and runtime lane.
- `.planning/phases/13-repair-generated-operator-resolve-flow/13-02-SUMMARY.md` — execution record for promoting the repaired lane into active Phase 3 and Phase 7 proof surfaces.

### Runtime seams, generated UI, and proof lanes
- `lib/parapet/operator.ex` — canonical Phoenix-free operator seam, including `resolve_incident/2` and queue paging behavior.
- `lib/parapet/operator/action_payload.ex` — typed mutation payload contract for generated operator actions.
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — generated queue UI wiring and the still-deferred resolved-history read path.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — existing generated detail seam demonstrating queue/detail mutation convergence.
- `docs/operator-ui.md` — operator-facing proof-lane narrative and explicit bounded queue semantics.
- `test/parapet/generated_operator_live_paging_test.exs` — generated-runtime lifecycle backstop lane.
- `test/parapet/operator_ui_integration_test.exs` — source-contract coverage over generated queue wiring and host-owned UI constraints.
- `test/mix/tasks/parapet.gen.ui_test.exs` — generator output contract checks for emitted operator UI source.

### Local research and product posture
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned generated code, embedded-library posture, and proof-surface discipline.
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first, least-surprise operator product direction.
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — generated paved-road observability patterns, symptom-first proof, and operator guidance.
- `prompts/elixir-telemetry-space-deep-research.md` — ecosystem maturity, host-owned wiring, and “build glue, not a backend” lessons.
- `prompts/parapet-integration-opportunities.md` — host-seam and integration philosophy for sibling-library style developer experience.
- `prompts/prior-art/chimeway-host-app-integration-seam.md` — host-owned auth/URL/repo seam lessons.
- `prompts/prior-art/rulestead-telemetry-observability-and-audit.md` — telemetry-as-API, audit separation, and explainable debug-surface posture.
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` — durable evidence, capture/semantics/exploration separation, and chronology-first modeling.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/parapet/operator.ex`: already owns the durable resolve lifecycle, audited evidence writes, queue paging, and the public seam the generated UI should trust completely.
- `test/parapet/generated_operator_live_paging_test.exs`: already provides the narrow generated-runtime lane proving active queue to resolved-history movement without browser infrastructure.
- `test/parapet/operator_ui_integration_test.exs` and `test/mix/tasks/parapet.gen.ui_test.exs`: already provide cheap source/generator contract coverage over the generated queue resolve seam and are the natural place to keep template-drift assertions.
- `.planning/v0.9-phases/3/VERIFICATION.md` and `.planning/v0.9-phases/3/03-VALIDATION.md`: already form the canonical Phase 3 proof surface and validation map that Phase 14 should strengthen rather than replace.
- `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md`, and `12-VALIDATION.md`: already define the closure/index surfaces Phase 14 must reconcile.

### Established Patterns
- Generated UI in Parapet is host-owned and inspectable; library code owns durable semantics and bounded public seams rather than shipping a hidden control plane.
- This repo prefers bounded, rerunnable ExUnit proof lanes plus source-contract assertions over browser-heavy or theatrical E2E infrastructure.
- Canonical runtime proof belongs in the runtime phase; later closure phases index and reconcile that proof rather than duplicating it.
- Active tracker artifacts (`ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`) tell what is true now; milestone audits and summaries remain historical evidence rather than mutable truth.
- Recommendation-first planning and assumptions mode should shift low-impact decisions left into artifacts unless they cross the repo’s locked escalation boundaries.

### Integration Points
- Strengthen and clearly name the generated resolve-flow proof lane in `test/parapet/generated_operator_live_paging_test.exs`, `test/parapet/operator_ui_integration_test.exs`, and `test/mix/tasks/parapet.gen.ui_test.exs` only as needed to make the backstop explicit.
- Promote that explicit lane through `.planning/v0.9-phases/3/VERIFICATION.md` and `.planning/v0.9-phases/3/03-VALIDATION.md`.
- Reconcile `.planning/v0.9-phases/7/VERIFICATION.md`, `.planning/v0.9-phases/7/07-VALIDATION.md`, `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-VERIFICATION.md`, and `12-VALIDATION.md` so they index the strengthened canonical lane honestly.
- Update `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` so live tracker truth aligns with the repaired Phase 13 runtime seam and Phase 14’s still-pending milestone-readiness gap.

</code_context>

<specifics>
## Specific Ideas

- The most cohesive one-shot recommendation is: **keep canonical runtime proof in Phase 3, make the generated resolve-flow lane a named rerunnable contract of the generator plus runtime seam, promote that proof into Phase 7 and Phase 12 as index layers, and reconcile live tracker surfaces now while preserving the milestone audit as historical.**
- For this repo and future GSD use, low-impact artifact and wording choices should shift left by default into assumptions/context artifacts; maintainers should only be asked when a decision crosses the already-locked impact boundaries in `AGENTS.md`.
- The operator experience should keep its current least-surprise contract: explicit refresh, bounded paging, chronology before controls, and no UI-local mutation semantics that can drift away from `Parapet.Operator`.

</specifics>

<deferred>
## Deferred Ideas

- Pull the generated resolved-history pagination path fully behind a public `Parapet.Operator` read seam to remove the remaining duplicated repo/cursor logic.
- Expand generated operator proof coverage beyond resolve once the current regression class is explicitly backstopped and closure-proof indexing is stable.
- Re-run `$gsd-audit-milestone` after Phase 14 lands so the fresh milestone audit replaces the historical `gaps_found` artifact with new closure evidence.

</deferred>

---

*Phase: 14-backstop-generated-operator-ui-closure-proof*
*Context gathered: 2026-05-23*
