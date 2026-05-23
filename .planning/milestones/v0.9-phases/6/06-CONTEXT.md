# Phase 6: Verify Cardinality Protection - Context

**Gathered:** 2026-05-21 (assumptions mode, expanded research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 1 verification gap for TSDB cardinality protection by producing closure-grade proof that the existing implementation works as claimed, reconciling the directly covered requirement state, and correcting proof-surface drift in the planning artifacts. This phase proves and reconciles existing behavior; it does not expand Parapet's runtime cardinality feature set or broaden milestone-wide artifact cleanup beyond what the proof directly changes.

</domain>

<decisions>
## Implementation Decisions

### Verification artifact shape
- **D-01:** Phase 6 should produce a hybrid verification report: executable reruns are the primary proof surface, and short narrative sections exist only to explain why those reruns prove the claim.
- **D-02:** The verification report should be organized around observable truths and maintainer-relevant claims, not around Phase 1 task order or plan bookkeeping.
- **D-03:** The report should use a mixed structure: observable truths first, followed by compact requirement and plan-output crosswalks so audit traceability stays explicit without turning the artifact into a checklist dump.

### Proof scope and commands
- **D-04:** The closure-grade proof set for Phase 6 should center on `mix compile --force --warnings-as-errors`, `mix test test/parapet/metrics/validator_test.exs`, and `mix test test/mix/tasks/parapet.doctor_test.exs`.
- **D-05:** `mix parapet.doctor cardinality` should be treated as an advisory spot-check in this workspace, not as the primary proof, because the current project state can legitimately return `skip` when no SLOs are configured.
- **D-06:** Phase 6 should explicitly distinguish proof of implementation existence from proof of current behavior: source inspection proves the guardrails exist, while targeted reruns prove they still behave correctly.

### Closure and reconciliation boundaries
- **D-07:** Phase 6 should add a dedicated Phase 1 `VERIFICATION.md` that matches the repo's stronger v0.9 verification posture rather than relying on the older summary/UAT artifacts alone.
- **D-08:** Phase 6 should reconcile the directly covered requirement state for `PERF-01.a` and `PERF-01.b` in `.planning/REQUIREMENTS.md` once the verification artifact is written.
- **D-09:** Phase 6 should update the local Phase 1 validation/proof wording where it is now misleading or stale, including mismatches around doctor exit-code semantics and current workspace behavior.
- **D-10:** Phase 6 should not attempt milestone-wide artifact synchronization across `ROADMAP.md`, `STATE.md`, and future audit outputs unless the new proof directly changes those files' truth; broad milestone reconciliation remains Phase 9 work.

### Elixir/Phoenix proof posture and DX
- **D-11:** The verification style should stay idiomatic to Elixir/Phoenix OSS: rerunnable `mix` commands, precise file citations, and concise claim-to-evidence mapping rather than prose-heavy attestation.
- **D-12:** Great maintainer DX for this phase means future contributors can quickly answer "what exactly was proven, by which commands, and what remains out of scope?" without rereading Phase 1 implementation summaries.
- **D-13:** The report should preserve Parapet's brand and product posture from `prompts/`: calm, evidence-first, low-noise, explicit about uncertainty, and never overstating what the current workspace invocation proves.

### Maintainer workflow preference
- **D-14:** For this repo, later planning and verification agents should default to recommendation-first synthesis and decide low-impact proof/documentation details themselves.
- **D-15:** Agents should escalate only when a choice materially changes public API, install surface, runtime behavior, safety guarantees, irreversible maintenance burden, or overall project posture.
- **D-16:** The least-surprise long-term way to encode that preference is a checked-in repo instruction surface such as `AGENTS.md`, optionally mirrored by a short human-facing note in contributor docs; this is adjacent follow-on work, not core Phase 6 scope.

### the agent's Discretion
- Exact wording and section ordering inside the Phase 1 `VERIFICATION.md`, as long as executable proof remains primary and the report stays concise.
- Exact division between "observable truths", "behavioral spot-checks", and "requirements coverage", as long as the resulting artifact is easy to audit and matches the repo's Phase 2/5 verification posture.
- Whether to keep Phase 1's older summary/UAT files unchanged or add small clarifying corrections, provided the final proof surface stays honest about exit codes, skip behavior, and current provider/SLO posture.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone gap
- `.planning/ROADMAP.md` — active Phase 6 scope, direct requirement targets, and the explicit boundary between proof closure and milestone-wide reconciliation
- `.planning/REQUIREMENTS.md` — `PERF-01.a` and `PERF-01.b` current unchecked state that Phase 6 must reconcile
- `.planning/v0.9-MILESTONE-AUDIT.md` — audit diagnosis showing the gap is missing closure-grade verification, not obvious missing implementation
- `.planning/STATE.md` — current milestone completion claim and the broader artifact-drift backdrop

### Prior implementation and validation artifacts
- `.planning/phases/01-cardinality-protection/01-01-SUMMARY.md` — original implementation summary for the Phase 1 cardinality work
- `.planning/phases/01-cardinality-protection/01-UAT.md` — early proof notes, including the current exit-code mismatch that Phase 6 should reconcile
- `.planning/v0.9-phases/1/PLAN.md` — must-haves, threat model, and original verification intent for the cardinality work
- `.planning/v0.9-phases/1/VALIDATION.md` — existing validation coverage that should be tied to the new verification artifact
- `.planning/v0.9-phases/1/SECURITY.md` — threat-closure evidence tied to the same implementation

### Verification analogs and repo proof posture
- `.planning/v0.9-phases/2/VERIFICATION.md` — current v0.9 example of a strong hybrid proof report for backend/generator work
- `.planning/v0.9-phases/5/VERIFICATION.md` — current v0.9 example of a strong hybrid proof report for reliability and doctor-related proof surfaces
- `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md` — locked maintainer preference for recommendation-first, codebase-first planning with limited escalation
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — locked maintainer preference for deterministic defaults and recommendation-heavy DX decisions

### Product posture and ecosystem research
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — merge-blocking proof posture, doctor/diagnostics as product, and host-owned inspectable seams
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first, low-noise product posture that should shape verification writing
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — observability-library lessons, symptom-first thinking, and cardinality guardrails
- `prompts/elixir-telemetry-space-deep-research.md` — ecosystem composition posture and telemetry-as-API context

### Existing code and proof surfaces
- `lib/mix/tasks/parapet.doctor.ex` — doctor cardinality implementation, severity model, and skip/error semantics that Phase 6 must describe honestly
- `lib/parapet/metrics/validator.ex` — compile-time metric label-limit enforcement
- `lib/parapet/internal/label_policy.ex` — shared source of truth for unsafe label rejection
- `test/mix/tasks/parapet.doctor_test.exs` — executable proof surface for cardinality analysis behavior
- `test/parapet/metrics/validator_test.exs` — executable proof surface for compile-time validator behavior
- `lib/parapet/slo.ex` — current provider-first SLO posture, relevant to how much `mix parapet.doctor cardinality` can prove in the current workspace

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mix.Tasks.Parapet.Doctor`: already exposes named checks, explicit severity semantics, and a bounded error model; Phase 6 should verify and document this surface rather than reinvent it.
- `Parapet.Metrics.Validator`: already provides the compile-time hook needed for proof of bounded label counts on built-in metrics.
- `Parapet.Internal.LabelPolicy`: already acts as the single validation source of truth for unsafe label patterns and should stay the cited root of trust in the proof report.
- Existing v0.9 verification reports for Phases 2 and 5 provide the right structural analog for a closure-grade backend verification artifact.

### Established Patterns
- This repo's better verification artifacts combine fresh targeted reruns with concise explanation and file citations.
- Planning drift is common in the repo; Phase 6 should correct directly covered proof surfaces without accidentally swallowing Phase 9's broader synchronization mandate.
- Doctor commands are part of the public product story, so verification must be explicit about `skip`, `warn`, and exit-code semantics rather than treating green output as self-explanatory.
- Recommendation-first planning is already the preferred maintainer workflow for this project.

### Integration Points
- Add `.planning/v0.9-phases/1/VERIFICATION.md` as the new closure artifact for Phase 1.
- Reconcile `.planning/v0.9-phases/1/VALIDATION.md` and `.planning/REQUIREMENTS.md` against the new proof.
- If needed, touch the older Phase 1 summary/UAT wording only to remove misleading claims about direct doctor behavior or exit-code expectations.
- Preserve broader milestone-wide state cleanup for Phase 9 unless Phase 6 proof directly changes those files' facts.

</code_context>

<specifics>
## Specific Ideas

- The right cohesive stance for Phase 6 is: **hybrid proof report, executable evidence first, observable truths first, direct requirement reconciliation only, and no overclaiming from a `skip` result**.
- In the current workspace, `mix test test/parapet/metrics/validator_test.exs test/mix/tasks/parapet.doctor_test.exs` passes, which strengthens the recommendation to center the proof on rerunnable targeted tests.
- The most important honesty fix is to document that `mix parapet.doctor cardinality` is not a sufficient standalone proof here because the active workspace can legitimately have no configured SLOs.
- The maintainer explicitly wants one-shot, coherent recommendations that reduce future low-impact questioning and push judgment left into the agent workflow.

</specifics>

<deferred>
## Deferred Ideas

- Add a repo-level `AGENTS.md` plus a small contributor-doc mirror so recommendation-first, low-escalation agent behavior becomes explicit across future phases.
- Broader milestone artifact synchronization across `ROADMAP.md`, `STATE.md`, and subsequent milestone audits after Phases 6-8 land.
- Modernize the doctor-cardinality tests away from deprecated `Parapet.SLO.define/2` if that becomes necessary for future maintainability; it is not required to close the current verification gap honestly.

</deferred>

---

*Phase: 06-verify-cardinality-protection*
*Context gathered: 2026-05-21*
