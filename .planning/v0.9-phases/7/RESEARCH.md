# Phase 7: Close Operator UI Performance Proof - Research

**Researched:** 2026-05-21
**Domain:** Closure-grade verification and narrow traceability reconciliation for the existing Phase 3 operator queue performance work
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Phase Boundary

Close the Phase 3 verification gap for operator-queue paging, performance proof, and acceptance evidence. This phase proves and reconciles the existing Phase 3 implementation; it does not redesign the queue, broaden the performance feature set, or turn into milestone-wide cleanup beyond the artifacts directly needed to close the orphaned proof gap.

### Locked Decisions

- **D-01:** Produce `.planning/v0.9-phases/3/VERIFICATION.md` as the canonical closure artifact.
- **D-02:** Keep the verification artifact thin and rerunnable; it should index proof rather than become a new source of truth.
- **D-03:** Follow the repo’s current verification shape: Goal Achievement, Observable Truths, Behavioral Spot-Checks, Plan Output Check, Requirements Coverage, Human Verification Required, and Gaps Summary.
- **D-04:** Treat summaries, `03-VALIDATION.md`, and docs as supporting inputs, not substitutes.
- **D-05:** Use layered proof rather than a single benchmark or a single prose claim.
- **D-06:** Primary proof is deterministic automated evidence that the queue is bounded and the generated LiveView renders only the current page.
- **D-07:** The proof set must include targeted queue/generated-UI tests, low-cardinality telemetry, the advisory 50,120-record benchmark lane, and the operator UI guide.
- **D-08:** `AC-03` requires a fresh captured run of `mix run bench/operator_ui_perf.exs`.
- **D-09:** The benchmark stays advisory and reproducible, not a default merge gate.
- **D-10:** Do not invent hard timing thresholds without pinned benchmark infrastructure.
- **D-11:** Verification wording must prefer measured signals like `queue.visible_rows=30`, `render.visible_rows=30`, `advisory=true`, and `merge_gate=disabled` over vague “fast” claims.
- **D-12:** Reconcile only the direct proof-traceability surfaces after proof lands.
- **D-13:** In scope after proof: `.planning/v0.9-phases/3/VERIFICATION.md`, `.planning/v0.9-phases/3/03-VALIDATION.md`, `.planning/REQUIREMENTS.md`, and the Phase 7 row in `.planning/ROADMAP.md`.
- **D-14:** Out of scope: `.planning/STATE.md`, `.planning/v0.9-MILESTONE-AUDIT.md`, and broader milestone harmonization.
- **D-15:** Leave historical Phase 3 summaries alone unless they are materially false after the new verification file exists.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCALE-01.c | Operator UI Incident list utilizes efficient pagination or cursor-based scrolling to prevent large payload rendering issues. | Existing Phase 3 tests and queue telemetry already provide the deterministic proof lane; Phase 7 should rerun them and record closure evidence in `.planning/v0.9-phases/3/VERIFICATION.md`. |
| AC-03 | The Operator UI loads instantly with 50,000 generated incident records, proving pagination and index effectiveness. | The repo already ships `bench/operator_ui_perf.exs` plus public docs describing the 50,120-record advisory lane; Phase 7 must rerun it and capture honest benchmark evidence without converting it into a universal SLA. |
</phase_requirements>

## Summary

Phase 7 is a proof-and-reconciliation phase, not a feature phase. The implementation work for bounded operator queue paging already exists across Phase 3 Plans 01 through 03: `Parapet.Operator.list_incident_queue/1` is the bounded queue seam, generated LiveView paging is already URL-driven and page-bounded, queue-page telemetry already emits low-cardinality metadata, and the 50,120-record advisory benchmark lane already exists. The audit gap is that those facts are currently spread across summaries, draft validation, and docs without a single closure-grade verification artifact. [VERIFIED: .planning/v0.9-MILESTONE-AUDIT.md] [VERIFIED: .planning/v0.9-phases/3/03-01-SUMMARY.md] [VERIFIED: .planning/v0.9-phases/3/03-02-SUMMARY.md] [VERIFIED: .planning/v0.9-phases/3/03-03-SUMMARY.md]

The strongest proof surface is already present in source. `lib/parapet/operator.ex` exposes the bounded queue API and the queue-page telemetry buckets; `test/parapet/operator/queue_pagination_test.exs` proves deterministic active-only queue semantics and telemetry; `test/parapet/generated_operator_live_paging_test.exs` proves the generated LiveView renders exactly the current page; `test/parapet/operator_ui_integration_test.exs` and `test/mix/tasks/parapet.gen.ui_test.exs` prove the generator and templates consume the bounded queue seam; and `bench/operator_ui_perf.exs` plus `docs/operator-ui.md` define the reproducible 50,120-record benchmark lane and its “advisory, merge-gate-disabled” posture. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: test/parapet/operator/queue_pagination_test.exs] [VERIFIED: test/parapet/generated_operator_live_paging_test.exs] [VERIFIED: test/parapet/operator_ui_integration_test.exs] [VERIFIED: test/mix/tasks/parapet.gen.ui_test.exs] [VERIFIED: bench/operator_ui_perf.exs] [VERIFIED: docs/operator-ui.md]

The right Phase 7 plan split is therefore:
1. create the missing `.planning/v0.9-phases/3/VERIFICATION.md` by rerunning the targeted tests and benchmark, then
2. reconcile only the directly dependent proof-tracking artifacts (`03-VALIDATION.md`, `REQUIREMENTS.md`, and the Phase 7 roadmap row).

This mirrors the successful Phase 6 gap-closure pattern and preserves the repo’s evidence-first, least-surprise posture. [VERIFIED: .planning/v0.9-phases/6/06-01-PLAN.md] [VERIFIED: .planning/v0.9-phases/6/06-02-PLAN.md]

## File Recommendations

| File | Recommendation | Why |
|------|----------------|-----|
| `.planning/v0.9-phases/3/VERIFICATION.md` | Create as the canonical closure artifact. | This is the missing proof object identified by the audit and the core requirement of Phase 7. |
| `.planning/v0.9-phases/3/03-VALIDATION.md` | Update from draft/noncompliant to closure-accurate validation language. | The validation file still says work is pending even though implementation exists. |
| `.planning/REQUIREMENTS.md` | Flip only `SCALE-01.c` and `AC-03` to verified after proof exists. | Requirement closure should follow proof, not precede it. |
| `.planning/ROADMAP.md` | Update only the Phase 7 row once proof and reconciliation land. | This phase explicitly owns its own roadmap closure signal, not milestone-wide cleanup. |
| `.planning/v0.9-phases/7/07-01-PLAN.md` | Own proof creation only. | Keeps the benchmark rerun and verification write-up separate from traceability edits. |
| `.planning/v0.9-phases/7/07-02-PLAN.md` | Own narrow reconciliation only. | Prevents proof creation from drifting into broader milestone synchronization. |

## Verification Patterns

### Pattern 1: Verification Artifact as Proof Index

Use a closure-grade verification doc that cites exact code anchors and exact rerun commands. The verification file should not re-describe Phase 3 implementation in prose-only form; it should answer “what did we re-run, what did it prove, and which requirement did it close?”

### Pattern 2: Layered Proof for Performance Claims

Use multiple proof layers:
- deterministic queue semantics tests
- deterministic generated UI paging/runtime tests
- source-contract generator tests
- advisory benchmark run with captured outputs
- public docs that explain the benchmark lane honestly

This is stronger than either docs-only proof or benchmark-only proof.

### Pattern 3: Advisory Benchmark Honesty

Treat `mix run bench/operator_ui_perf.exs` as a reproducible evidence lane, not a portable latency SLA. The report should capture the measurable signals the script already prints:
- `queue.visible_rows=30`
- `render.visible_rows=30`
- `advisory=true`
- `merge_gate=disabled`

### Pattern 4: Narrow Traceability Reconciliation

After proof exists, reconcile only the files that directly depend on that proof. Do not fold `.planning/STATE.md`, milestone audit docs, or Phase 8/9 work into Phase 7.

## Common Pitfalls

- Treating the three Phase 3 summary files as enough for milestone closure.
- Claiming “instant” or “fast” performance without the benchmark context, machine/runtime details, and advisory posture.
- Updating `REQUIREMENTS.md` or `ROADMAP.md` before `.planning/v0.9-phases/3/VERIFICATION.md` exists.
- Pulling `.planning/STATE.md` or milestone-wide sync work into this phase.
- Rewriting historical Phase 3 summaries unnecessarily instead of adding the missing verification layer.

## Validation Architecture

Phase 7 validation should prove four things:

1. `Parapet.Operator.list_incident_queue/1` remains the bounded public queue seam and still emits low-cardinality queue-page telemetry.
2. The generated LiveView still renders only the current page and uses explicit queue/history/paging affordances.
3. The advisory 50,120-record benchmark still runs and reports bounded visible-row signals plus advisory posture markers.
4. The traceability surfaces close only after proof exists and only for `SCALE-01.c` and `AC-03`.

Recommended commands:

- `mix test test/parapet/operator/queue_pagination_test.exs`
- `mix test test/parapet/generated_operator_live_paging_test.exs`
- `mix test test/parapet/operator_ui_integration_test.exs test/mix/tasks/parapet.gen.ui_test.exs`
- `mix run bench/operator_ui_perf.exs`

## Open Questions (RESOLVED)

1. **Should Phase 7 add new performance features?**
   Resolved: no. This is a verification closure phase, not a queue redesign phase.

2. **Should the benchmark become a merge gate?**
   Resolved: no. Keep it advisory and reproducible, matching the existing docs and benchmark output.

3. **Should Phase 7 sync all milestone trackers?**
   Resolved: no. Only direct proof-traceability surfaces are in scope; broader harmonization belongs to Phase 9.

## RESEARCH COMPLETE
