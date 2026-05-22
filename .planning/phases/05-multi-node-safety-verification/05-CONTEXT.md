# Phase 5: Multi-Node Safety Verification - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify that Parapet's bounded auto-mitigation and escalation surfaces behave safely when multiple nodes or concurrent workers race on the same incident. This phase covers the concurrency contract, crash/retry semantics, operator evidence, and the proof strategy needed to justify the safety claims. It does not expand Parapet into a distributed workflow engine, generic control plane, or exactly-once orchestration system.

</domain>

<decisions>
## Implementation Decisions

### Concurrency contract
- **D-01:** Treat Oban uniqueness as outer enqueue-pressure relief only, not as the core concurrency guarantee.
- **D-02:** The real safety contract is DB-backed claim ownership for a logical action key such as `incident_id + action_kind + step_id/escalation_key`.
- **D-03:** The contract must prevent duplicate external mitigations, duplicate escalation notifications, and duplicate "system acted" evidence for the same logical action.
- **D-04:** Competing job attempts are acceptable only if losers resolve as durable no-op outcomes such as `automation_claim_conflicted` or `escalation_claim_conflicted`.
- **D-05:** Prefer an explicit claim record with a unique constraint and bounded lifecycle (`claimed`, `executed`, `failed_retryable`, `failed_terminal`, `expired`/`abandoned`) over implicit coordination hidden in `runbook_data` or pure read-time checks.
- **D-06:** Re-check breaker, suppression, and incident-state gates inside the claim transaction so correctness does not depend on stale pre-claim reads.

### Crash and retry semantics
- **D-07:** Parapet should adopt at-least-once execution at the Oban layer, but effectively-once semantics for Parapet-owned intent and durable evidence.
- **D-08:** External effects must be driven with durable idempotency keys derived from the same logical action key used for claim ownership.
- **D-09:** Retries must resume from durable claim state rather than re-deciding from scratch on every re-execution.
- **D-10:** Exact-once across node death and external APIs is explicitly not the product claim for this phase.
- **D-11:** Incident lifecycle state (`open`, `investigating`, `resolved`) remains separate from automation/escalation attempt state; do not overload one to represent the other.
- **D-12:** Short, explicit failure states are preferred over hidden retries: `*_claimed`, `*_executed`, `*_short_circuited`, `*_failed_retryable`, and `*_failed_terminal` are the right mental model.

### Verification strategy
- **D-13:** The primary proof surface should be real Postgres concurrency integration tests using the host Repo, not dummy repos or mock-only seam tests.
- **D-14:** A DB-first hybrid is the preferred strategy: real single-node concurrent DB tests first, targeted crash/retry injection second, and only 1-2 multi-BEAM cluster smoke tests as canaries.
- **D-15:** Property/fuzz tests are optional hardening, not the main proof surface for this phase.
- **D-16:** Assertions should focus on durable end-state invariants: exactly one winning claim, exactly one external-effect path, coherent timeline/audit evidence, and correct loser/no-op outcomes.
- **D-17:** Avoid claiming distributed correctness from static checks alone; doctor remains advisory, tests provide the main proof.

### Operator evidence and DX
- **D-18:** Preserve one canonical incident timeline plus a derived present-tense summary. Do not create a second automation/race console.
- **D-19:** The default operator narrative should record consequential outcomes, not every low-level retry or lock attempt.
- **D-20:** Concurrency losers and retries must surface as calm, typed, operator-meaningful outcomes such as duplicate suppressed, claim conflicted, retry pending, or short-circuited.
- **D-21:** Deep mechanics such as attempt counters, raw lock details, and backend-specific retry trivia belong in logs, docs, or expandable detail, not in the main chronology by default.
- **D-22:** Summary projections must only report durable truth already represented in evidence; no UI-only inferred state machines.

### Architecture and product posture
- **D-23:** Prefer explicit, inspectable Postgres-backed coordination over magical distributed behavior. Host-owned truth is more important than minimizing schema count.
- **D-24:** Keep critical coordination windows short. Claim first, then perform external side effects outside long-held DB locks.
- **D-25:** This phase should strengthen operator trust and maintainer confidence, not maximize raw concurrency throughput.
- **D-26:** The system should stay honest about what it guarantees: bounded, evidence-backed, idempotent-enough automation for Phoenix apps, not Temporal-style workflow semantics.

### Maintainer workflow preference
- **D-27:** For Parapet and similar future phases, GSD should default to recommendation-first, codebase-first context gathering and minimize routine user questioning.
- **D-28:** Only escalate decisions back to the maintainer when they materially change product scope, public API, adoption posture, or operator semantics.
- **D-29:** `workflow.discuss_mode = "assumptions"` is the closest existing GSD setting to the desired planning posture and should be preferred for this repo unless a phase genuinely benefits from interactive discussion.

### the agent's Discretion
- Exact schema/module names for action claims and effect/idempotency storage.
- Exact unique-index shape and whether leases use timestamps, attempt counters, or both.
- Exact event names and payload fields, as long as the evidence remains typed, calm, and durable.
- Exact choice of test helpers and cluster harness, provided the DB-first proof strategy remains intact.

</decisions>

<specifics>
## Specific Ideas

- The right cohesive stance is: **DB-backed claim ownership, idempotent external effects, durable typed evidence, and honest proof surfaces**.
- Parapet should feel more like a careful Phoenix reliability layer than a distributed-systems lab project.
- The preferred developer experience is explicit and inspectable: clear claim records, clear failure modes, clear tests, and no hidden "trust us" concurrency magic.
- The existing product doctrine still applies under races:
  - current truth first
  - durable chronology second
  - risky control semantics after understanding
- The maintainer explicitly prefers stronger recommendation-first synthesis and fewer routine GSD questions in future planning.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and milestone intent
- `.planning/ROADMAP.md` — active v0.9 Phase 5 scope
- `.planning/PROJECT.md` — evidence-first, host-owned, bounded-automation posture
- `.planning/REQUIREMENTS.md` — `SCALE-02` and adjacent v0.9 requirements
- `.planning/STATE.md` — current milestone position and readiness

### Prior locked decisions that constrain this phase
- `.planning/phases/04-unified-install-path-dx/04-CONTEXT.md` — multi-node doctor posture, recommendation-first planning preference
- `.planning/milestones/v0.8-phases/4/4-CONTEXT.md` — single canonical timeline doctrine, escalation/suppression semantics, operator-summary posture

### Product and ecosystem research
- `prompts/parapet-engineering-dna-from-sibling-libs.md` — host-owned generated posture, doctor-first DX, explicit seams
- `prompts/parapet-brand-identity-deep-research.md` — calm, protective, evidence-first product identity
- `prompts/sre-observability-elixir-lib-deep-reseach.md` — SRE library lessons, symptom-first and low-noise posture
- `prompts/elixir-telemetry-space-deep-research.md` — practical Elixir observability ecosystem posture and glue-layer lessons
- `prompts/sre-best-practices-solo-founder-deep-research.md` — low-noise, actionable, evidence-cited operational expectations

### Existing code and proof surfaces
- `lib/parapet/automation/circuit_breaker.ex` — current read-time breaker implementation that must be hardened
- `lib/parapet/automation/executor.ex` — current auto-mitigation worker and Oban uniqueness seam
- `lib/parapet/escalation/worker.ex` — current escalation execution and short-circuit seam
- `lib/parapet/evidence.ex` — transactional evidence-writing boundary
- `lib/parapet/operator.ex` — audited operator command seam and idempotency payload usage
- `lib/parapet/operator/action_payload.ex` — mutation payload contract, including idempotency metadata
- `lib/parapet/operator/workbench_contract.ex` — operator summary/timeline projection contract
- `docs/operator-ui.md` — operator-facing semantics and evidence-first UX doctrine

### Current tests to extend rather than replace
- `test/parapet/automation/circuit_breaker_test.exs`
- `test/parapet/automation/executor_test.exs`
- `test/parapet/escalation/worker_test.exs`
- `test/parapet/operator_test.exs`
- `test/parapet/operator/workbench_contract_test.exs`
- `test/mix/tasks/parapet.doctor_test.exs`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Evidence.run_operator_command/1`: already provides the audited incident/timeline/audit transaction seam that Phase 5 should preserve.
- `Parapet.Operator.ActionPayload`: already carries mutation idempotency metadata and is the natural public contract for action keys.
- `Parapet.Automation.Executor`: already has a bounded automation identity and is the right place to hand off from alert-trigger to claim-driven mitigation execution.
- `Parapet.Escalation.Worker`: already centralizes short-circuit behavior for suppression and incident-state checks.
- `Parapet.Operator.WorkbenchContract`: already enforces the summary-over-canonical-timeline doctrine and should continue to be the projection seam for concurrency outcomes.

### Established Patterns
- Host-owned generated code and inspectable runtime seams are preferred over hidden framework magic.
- Durable evidence beats ephemeral inference.
- Static doctor checks may warn about cluster risks, but they must not overclaim distributed correctness.
- Operator UI should surface current truth and typed chronology, not raw system internals.

### Integration Points
- Add a DB-backed claim seam that both automation and escalation workers must pass through before side effects.
- Rework the breaker/escalation decision path so transaction-time truth, not stale reads, decides the winner.
- Extend the existing evidence taxonomy with claim-conflict, retryable-failure, and terminal-failure outcomes that remain operator-readable.
- Add real Repo-backed contention tests and a minimal cluster canary layer without turning the suite into a distributed test lab.

</code_context>

<deferred>
## Deferred Ideas

- Full Temporal-style durable execution or exactly-once workflow orchestration
- A separate automation control-plane UI or job-console UX
- Broad generalized distributed locking infrastructure beyond the bounded Parapet action-claim use case
- Extensive property/fuzz infrastructure if the DB-first test matrix already gives sufficient confidence

</deferred>

---

*Phase: 05-multi-node-safety-verification*
*Context gathered: 2026-05-20*
