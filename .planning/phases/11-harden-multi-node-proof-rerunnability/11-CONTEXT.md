# Phase 11: harden-multi-node-proof-rerunnability - Context

**Gathered:** 2026-05-22 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the Phase 5 multi-node proof lane honest, bounded, and rerunnable in environments without distributed Erlang. This phase covers the peer-node smoke lane degradation path, the proof hierarchy for `SCALE-02`, and reconciliation of verification surfaces so milestone claims match executable behavior. It does not widen Parapet's runtime guarantees, replace the DB-first contention proof with a distributed-only contract, or promote `mix parapet.doctor` into a distributed-correctness proof surface.

</domain>

<decisions>
## Implementation Decisions

### Proof hierarchy
- **D-01:** Keep the closure-grade proof for `SCALE-02` anchored in the real Postgres-backed contention suite.
- **D-02:** Treat the multi-BEAM `:peer` lane as a narrow canary, not as an always-on required proof surface in every environment class.

### Smoke lane degradation
- **D-03:** Replace the current hard failure at distributed-node bootstrap with an explicit bounded skip or equivalent non-failing degradation when distributed Erlang is unavailable.
- **D-04:** The canary must be honest about its environment contract and must not pretend to have exercised peer-node behavior when the environment cannot support it.

### Verification reconciliation
- **D-05:** Rewrite the Phase 5 verification and validation surfaces so they describe the peer-node canary as environment-conditional and rerunnable rather than as an unconditional pass everywhere.
- **D-06:** Reconcile `SCALE-02` truth across roadmap-adjacent proof artifacts so the executable behavior, verification wording, and milestone audit posture agree.

### Doctor posture
- **D-07:** Keep `mix parapet.doctor` advisory-only for distributed posture; do not widen it into a proof of distributed correctness.
- **D-08:** Preserve the existing certainty boundary: doctor reports live or static facts and explicit uncertainty, while executable tests remain the proof surface.

### the agent's Discretion
- Exact skip/degradation mechanism in the test lane, provided it is explicit, bounded, and non-misleading.
- Exact verification wording and artifact phrasing, provided the proof hierarchy and environment contract stay clear.
- Exact helper extraction or test harness refactoring, provided the runtime product contract does not widen.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone truth
- `.planning/ROADMAP.md` — Phase 11 scope, requirement target, and the explicit `:nodistribution` degradation goal.
- `.planning/REQUIREMENTS.md` — `SCALE-02` traceability and current pending status.
- `.planning/STATE.md` — current milestone position and readiness to plan Phase 11.
- `.planning/v0.9-MILESTONE-AUDIT.md` — exact rerunnability gap, environment failure mode, and milestone-close implications.

### Prior locked decisions that constrain this phase
- `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md` — DB-first proof hierarchy, canary posture, and honest guarantee boundary.
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — doctor certainty boundary and advisory-only cluster posture.

### Existing proof surfaces to reconcile
- `.planning/v0.9-phases/5/VERIFICATION.md` — current unconditional Phase 5 proof wording that now needs reconciliation.
- `.planning/v0.9-phases/5/05-VALIDATION.md` — current validation surface for the Phase 5 concurrency proof.
- `.planning/v0.9-phases/5/05-02-SUMMARY.md` — original canary summary language and verification command history.

### Existing code and tests
- `test/parapet/automation/executor_cluster_smoke_test.exs` — failing peer-node canary bootstrap path and the primary rerunnability seam.
- `test/parapet/automation/executor_concurrency_test.exs` — DB-first contention proof that remains the main executable safety surface.
- `test/support/concurrency_case.ex` — shared real-Repo concurrency harness.
- `test/support/concurrency_bootstrap.ex` — portable Postgres bootstrap layer used by the proof suite.
- `lib/parapet/automation/executor.ex` — runtime automation seam being proven by the contention and canary lanes.
- `lib/parapet/automation/claim_service.ex` — DB-backed claim ownership seam that anchors the safety contract.
- `lib/mix/tasks/parapet.doctor.ex` — existing advisory cluster posture wording that must remain intact.
- `test/mix/tasks/parapet.doctor_test.exs` — tests locking doctor certainty-boundary semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/parapet/automation/executor_concurrency_test.exs`: already proves one-winner claim semantics without requiring distributed Erlang and should remain the primary closure lane.
- `test/parapet/automation/executor_cluster_smoke_test.exs`: already contains the narrow peer canary flow and is the right seam to make degradation explicit instead of fatal.
- `test/support/concurrency_case.ex` and `test/support/concurrency_bootstrap.ex`: provide the reusable real-Repo harness that keeps the proof DB-first and rerunnable.
- `lib/parapet/automation/claim_service.ex`: already centralizes the DB-backed ownership contract that the proof surfaces are validating.

### Established Patterns
- Multi-node correctness claims are bounded and evidence-backed, not generalized distributed workflow guarantees.
- Doctor checks can report risks and live facts, but must stay explicit that they do not prove distributed correctness.
- Verification artifacts are expected to match executable behavior in the current environment class rather than preserving stale "passed once" language.

### Integration Points
- Adjust the peer-canary bootstrap path in `test/parapet/automation/executor_cluster_smoke_test.exs`.
- Reconcile proof wording in `.planning/v0.9-phases/5/VERIFICATION.md` and `.planning/v0.9-phases/5/05-VALIDATION.md`.
- Keep doctor wording and tests coherent with the unchanged advisory-only posture in `lib/mix/tasks/parapet.doctor.ex` and `test/mix/tasks/parapet.doctor_test.exs`.

</code_context>

<specifics>
## Specific Ideas

- The live rerun on 2026-05-22 failed in `test/parapet/automation/executor_cluster_smoke_test.exs` when `Node.start/2` returned `:nodistribution`, so the current blocker is confirmed in this workspace and not just inherited from the audit text.
- The intended stance is: DB-first proof remains authoritative, peer canary stays narrow, and environment limits are stated plainly rather than hidden behind a red test.
- This phase is about truthfulness and rerunnability of the proof lane, not about widening Parapet into a stronger distributed runtime contract.

</specifics>

<deferred>
## Deferred Ideas

- Replacing the DB-first proof contract with a distributed-only proof hierarchy.
- Broad cluster-test infrastructure beyond the narrow peer canary needed for this phase.
- Any expansion of `mix parapet.doctor` into a distributed assurance or runtime enforcement surface.

</deferred>

---

*Phase: 11-harden-multi-node-proof-rerunnability*
*Context gathered: 2026-05-22*
