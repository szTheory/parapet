# Phase 13: repair-generated-operator-resolve-flow - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Restore the generated operator resolve path so the Phase 3 runtime lifecycle and acceptance story are true again. This phase repairs the generated queue LiveView `"resolve"` action, re-establishes honest proof for the active-queue to resolved-history/archive lifecycle, and reconciles the current proof surfaces that currently overstate closure. It does not widen Parapet into a larger operator-console redesign, and it does not turn the optional resolved-history seam cleanup into required runtime scope for this phase.

</domain>

<decisions>
## Implementation Decisions

### Runtime seam repair
- **D-01:** The generated queue LiveView `"resolve"` handler should call `Parapet.Operator.resolve_incident/2`, not `Parapet.Operator.record_note/3`.
- **D-02:** The queue and detail generated LiveViews should converge on the same public `Parapet.Operator` mutation seam so resolve semantics are consistent across operator entrypoints.
- **D-03:** The generated operator UI should stay thin and host-owned, while durable lifecycle behavior remains owned by the Phoenix-free `Parapet.Operator` boundary.

### Operator semantics
- **D-04:** In generated operator UI, `"Resolve"` means a real lifecycle transition to `resolved`, including the durable status-change evidence and retrospective behavior already encoded in `Parapet.Operator.resolve_incident/2`.
- **D-05:** Phase 13 should not redefine `"Resolve"` as a soft note-writing shortcut or require operators to leave the queue view just to perform a legitimate resolve action.

### Proof strategy
- **D-06:** The canonical regression backstop should be a two-layer proof: one cheap source-contract assertion that the generated queue template wires `"resolve"` to `Parapet.Operator.resolve_incident/2`, plus one narrow generated-runtime test that proves queue resolve changes incident state and removes it from the active lane.
- **D-07:** This proof should extend the existing targeted quick-run operator UI lane rather than introduce a new heavyweight browser or generated-host harness.
- **D-08:** The runtime test should prove the user-visible lifecycle outcome that matters for the milestone contract: active queue to resolved-history/archive progression, not just handler presence.

### Verification hierarchy
- **D-09:** The new resolve proof becomes part of the canonical Phase 3 runtime proof surface first; Phase 7 and Phase 12 should index that runtime proof rather than duplicate it inside closure-phase verification artifacts.
- **D-10:** Reconciliation updates after the fix should stay narrow and honest: update current truth surfaces that materially overstate closure, while leaving historical audit artifacts historical until a fresh rerun replaces them.

### Maintainer workflow posture
- **D-11:** For this phase and downstream planning in this repo, default harder toward one-shot, research-backed recommendations with low-impact decisions shifted left into assumptions and artifacts.
- **D-12:** Escalate only for the repo’s already-locked impact boundaries: public CLI/API contract, default install contents, auth ownership, dependency/support surface, runtime behavior, safety guarantees, operator semantics, durable evidence truth, irreversible schema/maintenance burden, or two medium-impact concerns moving at once.

### the agent's Discretion
- Whether the resolve runtime assertion belongs inside `test/parapet/generated_operator_live_paging_test.exs` or a nearby targeted generated-UI test, provided it stays in the existing quick-run proof set and remains obvious to maintainers.
- Exact wording of the reconciled verification and validation surfaces, provided they point clearly at the repaired runtime proof and do not imply a fresh milestone audit has already passed.
- Whether to leave the resolved-history public-seam cleanup for a later phase or capture it only as a deferred follow-up, provided Phase 13 still closes the broken resolve lifecycle and proof gap.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and current milestone gap
- `.planning/ROADMAP.md` — Phase 13 scope, exact runtime repair, and reconciliation intent
- `.planning/v0.9-MILESTONE-AUDIT.md` — exact resolve-flow defect, proof blind spot, and optional resolved-history seam follow-up
- `.planning/PROJECT.md` — host-owned generator posture, telemetry/API discipline, optional dependency constraints, and operator/evidence product boundaries
- `.planning/REQUIREMENTS.md` — `SCALE-01.c` and `AC-03` truth rows that this phase repairs
- `.planning/STATE.md` — current milestone position and repo-level planning doctrine

### Prior locked context shaping this phase
- `AGENTS.md` — recommendation-first posture and narrow escalation thresholds
- `.planning/config.json` — repo default `workflow.discuss_mode = "assumptions"`
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — deterministic defaults, low-routine questioning, and maintainer workflow preference
- `.planning/phases/11-harden-multi-node-proof-rerunnability/11-CONTEXT.md` — proof honesty and bounded proof-lane posture
- `.planning/phases/12-backfill-closure-phase-verification-surfaces/12-CONTEXT.md` — proof hierarchy and historical-boundary rules

### Runtime seams and generated UI surfaces
- `lib/parapet/operator.ex` — public Phoenix-free queue/detail/mutation seam, including `resolve_incident/2`
- `lib/parapet/operator/action_payload.ex` — typed action payload contract for operator mutations
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — broken generated queue resolve handler and current resolved-history query path
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — already-correct generated resolve seam
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — generated queue/detail action wording and operator affordances

### Existing proof and documentation surfaces
- `test/parapet/generated_operator_live_paging_test.exs` — current generated runtime lane for bounded queue behavior
- `test/parapet/operator_ui_compile_out_test.exs` — compile-out and template seam assertions
- `test/parapet/operator_ui_integration_test.exs` — generated queue/detail source-contract and seam assertions
- `test/mix/tasks/parapet.gen.ui_test.exs` — generator output contract checks
- `.planning/v0.9-phases/3/03-VALIDATION.md` — Phase 3 quick-run proof set and sampling map
- `.planning/v0.9-phases/3/VERIFICATION.md` — canonical runtime proof surface to repair
- `.planning/v0.9-phases/7/07-VALIDATION.md` — Phase 7 closure sampling map
- `.planning/v0.9-phases/7/VERIFICATION.md` — closure proof index that should point at the repaired Phase 3 runtime proof
- `docs/operator-ui.md` — public operator UI proof and behavior narrative that must stay honest

### Local research inputs
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned generated code, narrow public seams, and rerunnable proof posture
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first operator UX and least-surprise product direction
- `prompts/elixir-telemetry-space-deep-research.md` — compose existing Phoenix primitives with opinionated host-owned glue
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — bounded proof lanes, symptom-first operator surfaces, and DX guidance
- `prompts/parapet-integration-opportunities.md` — ecosystem posture and operator-first integration philosophy

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/parapet/operator.ex`: already owns the correct audited resolve command, queue paging, and incident detail contracts.
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`: already demonstrates the intended generated resolve wiring against `Parapet.Operator.resolve_incident/2`.
- `test/parapet/generated_operator_live_paging_test.exs`: existing generated-runtime harness that can be extended to prove queue resolve lifecycle behavior without adding a new heavy fixture.
- `test/parapet/operator_ui_compile_out_test.exs`, `test/parapet/operator_ui_integration_test.exs`, and `test/mix/tasks/parapet.gen.ui_test.exs`: existing low-cost generator/source-contract seams that can cheaply backstop the wiring bug class.

### Established Patterns
- Generated UI code in Parapet is intended to remain host-owned presentation and wiring, not a second place where durable query and mutation semantics are reimplemented.
- Canonical runtime proof belongs in the underlying runtime phase verification surface; closure phases index and reconcile that proof rather than shadowing it with duplicate runtime claims.
- This repo prefers bounded, rerunnable ExUnit proof lanes and honest documentation over theatrical E2E infrastructure or one-off benchmark theater.
- Repo doctrine already favors recommendation-first planning and shifting routine decisions left into artifacts.

### Integration Points
- Repair `priv/templates/parapet.gen.ui/operator_live.ex.eex` to route `"resolve"` through `Parapet.Operator.resolve_incident/2`.
- Add explicit resolve-wiring proof to the generated UI source-contract tests.
- Add narrow runtime resolve lifecycle proof to the existing targeted generated UI quick-run lane.
- Reconcile `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/7/VERIFICATION.md`, their validation maps, and any current truth surfaces that presently over-claim closure.

</code_context>

<specifics>
## Specific Ideas

- The most cohesive Phase 13 recommendation is: **repair the queue resolve seam through the existing public operator API, prove that behavior with one cheap template assertion plus one narrow generated-runtime lifecycle test, and keep closure artifacts indexing that repaired runtime proof instead of duplicating it.**
- The repo should continue to bias toward one-shot recommendations: do the research, pick the coherent default, record the assumption, and escalate only when the decision crosses the already-locked impact boundaries.
- The optional resolved-history public-seam cleanup is worth preserving as a follow-up idea, but it should not block the narrow runtime and proof repair that this phase exists to deliver.

</specifics>

<deferred>
## Deferred Ideas

- Pull the generated resolved-history pagination path fully behind a public `Parapet.Operator` read seam to remove duplicated repo/cursor logic.
- Add broader closure-proof coverage for generated operator UI runtime mutations beyond resolve once the narrow backstop is in place.
- Further centralize recommendation-first repo doctrine if future phases still reopen low-impact defaults despite `AGENTS.md`, `.planning/config.json`, and phase context artifacts.

</deferred>

---

*Phase: 13-repair-generated-operator-resolve-flow*
*Context gathered: 2026-05-23*
