# Phase 7: Close Operator UI Performance Proof - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Close the Phase 3 verification gap for operator-queue paging, performance proof, and acceptance evidence. This phase proves and reconciles the existing Phase 3 implementation; it does not redesign the queue, broaden the performance feature set, or turn into milestone-wide cleanup beyond the artifacts directly needed to close the orphaned proof gap.

</domain>

<decisions>
## Implementation Decisions

### Verification artifact shape
- **D-01:** Phase 7 must produce a dedicated `.planning/v0.9-phases/3/VERIFICATION.md` as the canonical closure artifact.
- **D-02:** The verification artifact should be a thin, rerunnable proof index over executable evidence surfaces, not a new primary source of truth.
- **D-03:** The report shape should follow the repo’s existing Phase 2 and Phase 5 verification pattern: Goal Achievement, Observable Truths, Behavioral Spot-Checks, Plan Output Check, Requirements Coverage, Human Verification Required, and Gaps Summary.
- **D-04:** Summaries, `VALIDATION.md`, and public docs are supporting inputs, not substitutes for the canonical verification artifact.

### Proof standard for `SCALE-01.c` and `AC-03`
- **D-05:** Closure must use layered proof, not a single benchmark or a single prose claim.
- **D-06:** The primary proof surface is deterministic automated evidence that the operator queue is bounded and the generated LiveView renders only the current page.
- **D-07:** The required proof set should include targeted queue and generated-UI tests, the low-cardinality queue telemetry seam, the advisory 50,120-record benchmark lane, and the operator UI guide that explains the lane honestly.
- **D-08:** `AC-03` closure requires a fresh captured run of `mix run bench/operator_ui_perf.exs`; summary-only claims are not sufficient.
- **D-09:** The benchmark lane remains advisory and reproducible, not a default merge gate and not a universal cross-hardware latency SLA.
- **D-10:** Phase 7 must not invent hard millisecond thresholds for closure unless the project later adds dedicated pinned benchmark infrastructure.
- **D-11:** Verification wording should avoid naked claims like "loads instantly" and instead record measured proof signals such as `queue.visible_rows=30`, `render.visible_rows=30`, resolved rows excluded, `advisory=true`, and `merge_gate=disabled`, alongside machine/runtime context.

### Reconciliation scope
- **D-12:** Phase 7 should reconcile the proof artifact and the immediately dependent traceability surfaces, but stop short of milestone-wide synchronization.
- **D-13:** In scope after proof lands: `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/REQUIREMENTS.md` for `SCALE-01.c` and `AC-03`, and the Phase 7 row in `.planning/ROADMAP.md`.
- **D-14:** Out of scope for Phase 7: `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, broader milestone wording harmonization, and cross-phase cleanup that is better handled by Phase 9.
- **D-15:** Phase 3 summary files should remain historical execution records unless they contain a materially false claim that would mislead an auditor even after `VERIFICATION.md` exists.

### Maintainer workflow preference
- **D-16:** For this repo, downstream agents should default to recommendation-first synthesis and decide low-impact proof/documentation details themselves.
- **D-17:** Escalate to the maintainer only when a choice materially changes public API, product posture, proof honesty, acceptance semantics, or architecture.
- **D-18:** The least-surprise long-term place to encode that preference is a repo-root `AGENTS.md`, optionally mirrored into other repo-local instruction surfaces later. Phase 7 should capture this recommendation, but adding that file is adjacent work rather than core proof scope.

### the agent's Discretion
- Exact wording inside `VERIFICATION.md`, as long as executable proof remains primary and the report stays concise.
- Exact command grouping for the targeted test reruns.
- Exact environment details captured from the advisory benchmark run, as long as they make the numbers reproducible and honest.
- Exact `VALIDATION.md` wording changes needed to move it from draft/noncompliant state to closure-accurate status.

</decisions>

<specifics>
## Specific Ideas

- The cohesive recommendation is: **one canonical verification report, layered executable proof, advisory benchmark evidence without fake thresholds, and narrow direct-traceability reconciliation only**.
- This matches Parapet’s evidence-first, least-surprise posture better than either docs-only proof or broad milestone cleanup.
- Great maintainer DX here means future reviewers can answer "what exactly was proven, how was it rerun, and which claims are now closed?" by reading one verification report plus a small set of aligned tracking files.
- Great adopter honesty means the public docs continue to present the benchmark lane as reproducible and useful, but not as a portable performance guarantee.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and audit gap
- `.planning/ROADMAP.md` — active Phase 7 scope and the explicit boundary between proof closure and milestone-wide reconciliation
- `.planning/REQUIREMENTS.md` — `SCALE-01.c` and `AC-03` current unchecked state that Phase 7 must close
- `.planning/v0.9-MILESTONE-AUDIT.md` — audit diagnosis showing the gap is missing closure-grade verification, not obvious missing implementation
- `.planning/PROJECT.md` — evidence-first product posture, generated host-owned UI philosophy, and low-cardinality telemetry discipline

### Prior implementation and locked Phase 3 decisions
- `.planning/v0.9-phases/3/3-CONTEXT.md` — locked queue semantics, proof posture, and maintainer preference already chosen for Phase 3
- `.planning/v0.9-phases/3/RESEARCH.md` — keyset paging, LiveView stream, and benchmark/proof rationale
- `.planning/v0.9-phases/3/03-01-SUMMARY.md` — bounded queue API and queue-aligned index work completed
- `.planning/v0.9-phases/3/03-02-SUMMARY.md` — generated LiveView bounded paging and refresh/history affordances completed
- `.planning/v0.9-phases/3/03-03-SUMMARY.md` — queue telemetry, advisory benchmark lane, and docs work completed
- `.planning/v0.9-phases/3/03-VALIDATION.md` — current draft validation state that Phase 7 should reconcile

### Verification analogs
- `.planning/v0.9-phases/2/VERIFICATION.md` — current repo example of backend/generator verification artifact shape
- `.planning/v0.9-phases/5/VERIFICATION.md` — current repo example of reliability-proof verification artifact shape
- `.planning/v0.9-phases/6/06-CONTEXT.md` — direct precedent for narrow proof-plus-traceability reconciliation without milestone-wide cleanup

### Existing code and proof surfaces
- `lib/parapet/operator.ex` — bounded queue API and queue-page telemetry seam
- `test/parapet/operator/queue_pagination_test.exs` — deterministic queue semantics and telemetry coverage
- `test/parapet/generated_operator_live_paging_test.exs` — generated LiveView bounded rendering proof
- `test/parapet/operator_ui_integration_test.exs` — generated operator UI source-contract assertions
- `test/mix/tasks/parapet.gen.ui_test.exs` — generator output assertions for bounded queue affordances
- `bench/operator_ui_perf.exs` — advisory 50,120-record proof lane
- `docs/operator-ui.md` — public benchmark and operator-queue proof narrative

### Product and ecosystem guidance
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned seam discipline, diagnostics-first DX, and least-surprise defaults
- `prompts/parapet-brand-identity-deep-research.md` — calm, evidence-first, low-noise product direction
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — observability-library proof and product posture lessons
- `prompts/elixir-telemetry-space-deep-research.md` — telemetry/API discipline and ecosystem composition lessons
- `prompts/prior-art/SOURCE-CANONICAL.md` — prior-art index for sibling-library and ecosystem patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Operator.list_incident_queue/1` is already the bounded public seam and the correct unit of proof.
- `bench/operator_ui_perf.exs` already proves the generated host-owned path rather than only a library seam, which is the right posture for this repo.
- The targeted queue and generated UI tests already cover the core boundedness semantics; Phase 7 mainly needs to rerun and attest to them coherently.
- The existing Phase 2 and Phase 5 verification reports already provide the document structure that keeps this repo auditable.

### Established Patterns
- This repo’s strongest closure artifacts combine rerunnable commands with a short truth table and a requirement crosswalk.
- Public docs can explain proof lanes, but milestone closure depends on an internal verification artifact.
- Performance claims stay honest when they are framed as bounded behavior plus reproducible advisory measurements, not as universal timing promises.
- Narrow verification phases should fix direct proof drift first and leave milestone-wide synchronization to dedicated cleanup phases.

### Integration Points
- Add `.planning/v0.9-phases/3/VERIFICATION.md` as the new canonical closure artifact for Phase 3.
- Reconcile `.planning/v0.9-phases/3/03-VALIDATION.md` with the new proof artifact.
- Update `.planning/REQUIREMENTS.md` and the Phase 7 line in `.planning/ROADMAP.md` once proof is captured.
- Consider a future repo-root `AGENTS.md` to encode recommendation-first maintainer preferences across GSD and adjacent agent tooling.

</code_context>

<deferred>
## Deferred Ideas

- Milestone-wide synchronization across `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, and other cross-phase trackers after Phases 7 and 8 land
- Turning the advisory benchmark lane into a longer-running baseline/trend system
- Adding repo-root `AGENTS.md` and any mirrored instruction surfaces as a separate focused follow-on task

</deferred>

---

*Phase: 07-close-operator-ui-performance-proof*
*Context gathered: 2026-05-21*
