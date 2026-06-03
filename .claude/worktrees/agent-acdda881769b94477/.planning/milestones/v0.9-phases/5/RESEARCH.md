# Phase 5: Multi-Node Safety Verification - Research

**Researched:** 2026-05-20
**Domain:** Elixir/Ecto/Oban concurrency safety for bounded automation and escalation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)
- Full Temporal-style durable execution or exactly-once workflow orchestration
- A separate automation control-plane UI or job-console UX
- Broad generalized distributed locking infrastructure beyond the bounded Parapet action-claim use case
- Extensive property/fuzz infrastructure if the DB-first test matrix already gives sufficient confidence
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| P5-01 | Create tests simulating concurrent mitigation triggers across multiple nodes. | Use real Repo-backed concurrency tests first, plus 1-2 distributed smoke tests only after the DB contract exists.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][VERIFIED: test/parapet/automation/executor_test.exs] |
| P5-02 | Validate Ecto-backed circuit breakers are robust against race conditions via database-level atomic checks or locks. | Replace read-time breaker decisions with claim-time gate checks inside a transaction using a unique claim row and, where needed, a locked incident row.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][CITED: https://hexdocs.pm/ecto/Ecto.Query.html][CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html] |
| P5-03 | Ensure escalation policies handle node crashes/restarts gracefully without duplicate alerts. | Persist claim state and use durable idempotency keys so retries resume from claim state instead of re-deciding from incident state alone.[VERIFIED: lib/parapet/escalation/worker.ex][VERIFIED: lib/parapet/operator.ex][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| SCALE-02 | System test suite includes multi-node or concurrency simulation tests verifying that Ecto-backed circuit breakers prevent race conditions when multiple nodes attempt auto-mitigation simultaneously. | Build a Postgres-backed proof lane for concurrent executor attempts and keep current DummyRepo tests as seam tests only.[VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: test/parapet/automation/circuit_breaker_test.exs][VERIFIED: test/parapet/automation/executor_test.exs] |
</phase_requirements>

## Summary

The current implementation is not yet race-safe for Phase 5. `Parapet.Automation.CircuitBreaker.allow?/2` performs a historical count over `ToolAudit` rows and returns `count < max_executions`, but it does not claim ownership or lock any row before `Parapet.Automation.Executor` calls `Parapet.Operator.execute_runbook_step/3`.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][VERIFIED: lib/parapet/automation/executor.ex] `Parapet.Escalation.Worker` likewise re-reads incident state and suppression state and then directly calls the configured policy, persisting only after the effect attempt.[VERIFIED: lib/parapet/escalation/worker.ex]

That means the real seam to harden is not Oban insertion; it is the execution boundary immediately before a mitigation or escalation side effect. Oban’s own docs state that uniqueness applies during insertion and does not prevent concurrent execution, and that its open-source uniqueness relies on transactional locks and queries rather than database unique constraints.[CITED: https://hexdocs.pm/oban/unique_jobs.html] The phase context already locks the product posture to DB-backed claim ownership, and the live code supports that direction because `ActionPayload` already carries an idempotency key and the system already centralizes evidence writes through `Parapet.Evidence.run_operator_command/1`.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][VERIFIED: lib/parapet/operator/action_payload.ex][VERIFIED: lib/parapet/evidence.ex]

**Primary recommendation:** add an explicit Postgres-backed action-claim table and force both automation execution and escalation execution through a shared claim service that (1) acquires or loses a unique claim, (2) re-checks incident/suppression/breaker gates inside the transaction, (3) performs the side effect outside the lock window with a durable idempotency key, and (4) persists one calm, typed durable outcome per logical action.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html][CITED: https://hexdocs.pm/ecto/Ecto.Query.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Automation claim ownership | API / Backend | Database / Storage | The winner/loser decision must be made in a DB transaction, not in the browser or via queue uniqueness alone.[VERIFIED: lib/parapet/automation/executor.ex][CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Circuit-breaker gate evaluation | Database / Storage | API / Backend | The current breaker is a DB read already; Phase 5 needs that gate re-evaluated atomically at claim time.[VERIFIED: lib/parapet/automation/circuit_breaker.ex] |
| Escalation policy dispatch | API / Backend | Database / Storage | The worker owns orchestration, but durable claim state must live in Postgres so retries and crashes converge on the same truth.[VERIFIED: lib/parapet/escalation/worker.ex][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| Operator-visible chronology | API / Backend | Database / Storage | Timeline and audit entries are written through `Parapet.Evidence` and projected by `Parapet.Operator.WorkbenchContract`.[VERIFIED: lib/parapet/evidence.ex][VERIFIED: lib/parapet/operator/workbench_contract.ex] |
| Multi-node proof tests | API / Backend | Database / Storage | `SCALE-02` is about concurrency at the execution seam, so proof must use a real Repo and Postgres concurrency rather than pure seam doubles.[VERIFIED: .planning/REQUIREMENTS.md][VERIFIED: test/parapet/automation/circuit_breaker_test.exs] |

## Project Constraints (from CLAUDE.md)

No `CLAUDE.md` file exists at the repo root, so there are no additional project-local directives to honor for this phase.[VERIFIED: repo root `CLAUDE.md` absent]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto` | locked `3.13.6`; latest `3.14.0` released 2026-05-19 | Transactions, `update_all`, row locking, conflict handling | The repo already depends on Ecto and the required primitives for locking and upserts are in the official API.[VERIFIED: mix.lock][VERIFIED: `mix hex.info ecto`][CITED: https://hexdocs.pm/ecto/Ecto.Repo.html][CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| `ecto_sql` | locked `3.13.5`; latest `3.14.0` released 2026-05-19 | Migrations and SQL adapter support | Phase 5 needs a migration for the claim table and likely no new dependency beyond Ecto SQL.[VERIFIED: mix.lock][VERIFIED: `mix hex.info ecto_sql`][CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html] |
| `oban` | locked `2.22.1`; latest `2.22.1` released 2026-04-30 | Retrying execution and queue orchestration | The repo already uses Oban workers; keep using Oban for at-least-once execution, not for the core duplication guarantee.[VERIFIED: mix.lock][VERIFIED: `mix hex.info oban`][VERIFIED: lib/parapet/automation/executor.ex][VERIFIED: lib/parapet/escalation/worker.ex][CITED: https://hexdocs.pm/oban/unique_jobs.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html] |
| PostgreSQL | local `14.17` available in environment | Real concurrency proof surface | The docs-backed design depends on database constraints and row locks, and the local environment already has PostgreSQL installed.[VERIFIED: `psql --version`][VERIFIED: `postgres --version`][CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `ExUnit` | bundled with Elixir `1.19.5` | Unit and integration tests | Keep current seam tests in ExUnit and add a real Repo-backed concurrency lane in ExUnit as well.[VERIFIED: `mix --version`][VERIFIED: test/test_helper.exs] |
| `Oban.Testing` | available through the existing `oban` dependency | Queue assertions and drain helpers | Use only if it fits naturally with the test harness; it is helpful for enqueue/retry assertions but is not required for the core contention proof.[VERIFIED: mix.lock][ASSUMED] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Postgres claim rows | Oban uniqueness only | Rejected because Oban’s docs say uniqueness applies at insertion time and does not control concurrent execution.[CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Explicit claim rows | Advisory-lock-only coordination | Rejected for this phase because explicit rows give durable operator-facing state and retry recovery, while locks alone do not preserve claim lifecycle evidence.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][ASSUMED] |
| Real Repo-backed tests | DummyRepo-only tests | Rejected because current tests prove branches but not row-lock/constraint behavior under contention.[VERIFIED: test/parapet/automation/circuit_breaker_test.exs][VERIFIED: test/parapet/escalation/worker_test.exs] |

**Installation:**
```bash
# No new runtime dependency is recommended for Phase 5.
# Reuse the existing Ecto + Oban + PostgreSQL stack.
```

**Version verification:** the current repo is locked to `ecto 3.13.6`, `ecto_sql 3.13.5`, and `oban 2.22.1`; those values were verified with `mix.lock` and `mix hex.info` on 2026-05-20.[VERIFIED: mix.lock][VERIFIED: `mix hex.info ecto`][VERIFIED: `mix hex.info ecto_sql`][VERIFIED: `mix hex.info oban`]

## Architecture Patterns

### System Architecture Diagram

```text
Alert / operator intent
        |
        v
Oban job start (Executor / Escalation Worker)
        |
        v
Claim transaction
  - load + optionally lock incident row
  - insert/refresh action claim by logical key
  - re-check breaker / suppression / incident-state gates
        |
        +---- conflict or gate closed ----> persist calm no-op evidence ----> done
        |
        v
Winner leaves transaction with claim + idempotency key
        |
        v
External mitigation / escalation policy call
        |
        v
Persist outcome transaction
  - claim => executed / failed_retryable / failed_terminal
  - timeline entry
  - audit entry (or durable policy evidence)
        |
        v
Oban retry or completion
  - retries resume from claim state, not from fresh incident guesses
```

This ownership split matches the phase context’s requirement to keep critical lock windows short while making Postgres the source of truth for action ownership.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

### Recommended Project Structure

```text
lib/parapet/automation/
├── action_claim.ex        # schema for durable ownership and lifecycle
├── claim_service.ex       # shared transaction boundary for claim/winner/loser logic
├── circuit_breaker.ex     # breaker window query helpers reused inside claim tx
└── executor.ex            # worker delegates to claim_service

lib/parapet/escalation/
├── worker.ex              # worker delegates to same claim_service
└── policy.ex              # existing behaviour; pass idempotency key through opts

test/support/
├── phase5_repo.ex         # test-only real Repo for Postgres concurrency
├── data_case.ex           # SQL sandbox/manual checkout helpers
└── cluster_case.ex        # minimal distributed canary helper, only if needed

test/parapet/concurrency/
├── automation_claim_test.exs
├── escalation_claim_test.exs
└── multi_node_smoke_test.exs
```

### Pattern 1: Explicit Claim Row Per Logical Action

**What:** represent automation or escalation ownership as a durable row keyed by `{incident_id, action_kind, action_key}` with a database unique index and lifecycle columns such as `status`, `idempotency_key`, `claimed_at`, `finished_at`, `attempt_count`, and optional lease metadata.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html]

**When to use:** every path that can cause an external effect or a durable “system acted” timeline event.[VERIFIED: lib/parapet/automation/executor.ex][VERIFIED: lib/parapet/escalation/worker.ex]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/constraints-and-upserts.html
attrs = %{
  incident_id: incident.id,
  action_kind: "mitigation",
  action_key: step_id,
  status: "claimed",
  idempotency_key: "auto_exec_#{incident.id}_#{step_id}"
}

Repo.insert(
  %ActionClaim{} |> ActionClaim.changeset(attrs),
  on_conflict: :nothing,
  conflict_target: [:incident_id, :action_kind, :action_key]
)
```

### Pattern 2: Re-Check Gates Inside the Claim Transaction

**What:** after inserting or selecting the claim winner, re-load the incident inside the same transaction and apply incident-state, suppression, and breaker checks before any side effect runs.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][VERIFIED: lib/parapet/escalation/worker.ex][VERIFIED: lib/parapet/automation/circuit_breaker.ex]

**When to use:** winner path only; loser paths should not perform external effects.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

**Example:**
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Query.html
incident =
  from(i in Incident, where: i.id == ^incident_id, lock: "FOR UPDATE")
  |> Repo.one!()
```

### Pattern 3: Resume from Claim State on Retry

**What:** on retry, the worker should first inspect the claim row and branch on durable claim state instead of recomputing from raw incident state alone.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][CITED: https://hexdocs.pm/oban/job_lifecycle.html]

**When to use:** escalation policy retries and automation retries where the previous attempt may have died after the side effect but before evidence persistence.[VERIFIED: lib/parapet/escalation/worker.ex][VERIFIED: lib/parapet/automation/executor.ex]

**Example:**
```elixir
# Source: current repo seam + Oban retry lifecycle docs
case claim.status do
  "executed" -> {:discard, "already executed"}
  "failed_terminal" -> {:discard, "already terminal"}
  "failed_retryable" -> continue_with_same_idempotency_key(claim)
  "claimed" -> continue_with_same_idempotency_key(claim)
end
```

### Anti-Patterns to Avoid

- **Read-time breaker only:** the current `allow?/2` count query is necessary context but insufficient as the final concurrency guard because multiple workers can observe the same count before either writes new evidence.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][VERIFIED: lib/parapet/automation/executor.ex]
- **Oban uniqueness as the proof:** Oban’s docs explicitly separate uniqueness from concurrency, so a green unique-job test does not prove race-safe execution.[CITED: https://hexdocs.pm/oban/unique_jobs.html]
- **Writing loser chronology as full executions:** losers should produce typed no-op outcomes such as claim conflicted or duplicate suppressed, not duplicate `mitigation_executed` or `escalation_executed` entries.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]
- **Hiding coordination in `runbook_data`:** `runbook_data` currently stores escalation projection state and summary inputs; using it as the only ownership mechanism would mix projection state with execution truth.[VERIFIED: lib/parapet/operator.ex][VERIFIED: lib/parapet/operator/workbench_contract.ex]

## Likely Implementation Strategy

1. Introduce a new durable claim schema and migration, likely `parapet_action_claims`, with a unique index on `incident_id`, `action_kind`, and `action_key` plus status/idempotency metadata.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]
2. Extract a shared claim service used by both `Parapet.Automation.Executor` and `Parapet.Escalation.Worker` so the winning/losing logic is identical at the transaction boundary.[VERIFIED: lib/parapet/automation/executor.ex][VERIFIED: lib/parapet/escalation/worker.ex]
3. Keep `Parapet.Automation.CircuitBreaker` as a query helper for historical windows, but call it only after claim acquisition and incident reload inside the transaction.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]
4. Reuse the existing mitigation idempotency shape. `Executor` already derives `auto_exec_<incident>_<step>` and `ActionPayload` already supports `idempotency_key`, which makes `{incident_id, step_id}` the natural first action key for automation.[VERIFIED: lib/parapet/automation/executor.ex][VERIFIED: lib/parapet/operator/action_payload.ex]
5. Extend escalation dispatch to derive a stable idempotency key from the escalation claim and pass it through `policy_module.escalate/2` options. The existing behaviour already accepts `opts`, so this can be additive rather than a breaking callback change.[VERIFIED: lib/parapet/escalation/policy.ex][VERIFIED: lib/parapet/escalation/worker.ex]
6. Persist one operator-meaningful loser outcome such as `automation_claim_conflicted` or `escalation_claim_conflicted`, but only if it adds durable signal; do not spam low-level retries into the main chronology.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

## Likely Plan Decomposition

### Slice 1: Real Repo-backed proof harness

- Add a test-only Repo, sandbox/manual transaction helpers, and a way to run the existing spine schemas against local Postgres for tests.[VERIFIED: test/test_helper.exs][VERIFIED: no `DataCase`/SQL sandbox helper found by repo grep]
- Create the minimum migration/test bootstrap needed for incidents, timeline entries, audits, and the new claim table.[VERIFIED: lib/parapet/spine/incident.ex][VERIFIED: lib/parapet/spine/timeline_entry.ex][VERIFIED: lib/parapet/spine/tool_audit.ex]

### Slice 2: Shared claim service

- Add the claim schema, migration, and unique index.[CITED: https://hexdocs.pm/ecto_sql/Ecto.Migration.html]
- Add winner/loser claim acquisition helpers and durable status transitions.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

### Slice 3: Harden automation executor

- Refactor `Executor.perform/1` to call the claim service before `Operator.execute_runbook_step/3`.[VERIFIED: lib/parapet/automation/executor.ex]
- Move breaker gating into the transaction and record a calm short-circuit outcome if the breaker closes.[VERIFIED: lib/parapet/automation/circuit_breaker.ex]

### Slice 4: Harden escalation worker

- Refactor `Escalation.Worker.perform/1` to claim before policy execution and persist retryable/terminal claim outcomes.[VERIFIED: lib/parapet/escalation/worker.ex]
- Pass claim-derived idempotency data through policy opts.[VERIFIED: lib/parapet/escalation/policy.ex]

### Slice 5: Verification matrix

- Add concurrent executor contention tests, escalation retry/crash tests, and at most one minimal distributed smoke test if the first four slices are green.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Duplicate job suppression | Custom in-memory node registry | Postgres unique claim rows + `on_conflict` | In-memory state disappears on crash and does not coordinate across nodes.[CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html][ASSUMED] |
| Execution serialization | Oban uniqueness as sole guard | Oban for enqueue pressure plus DB claim ownership | Oban uniqueness does not prevent concurrent execution.[CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Race-safe update logic | Ad hoc read-then-write checks | `Repo.transaction`, `lock`, `update_all`, and constraint-backed inserts | Ecto already exposes the necessary transactional primitives.[CITED: https://hexdocs.pm/ecto/Ecto.Repo.html][CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| Crash/restart duplicate suppression tests | Broad distributed chaos framework | Deterministic retry injection with a fake policy and durable effect sink | The phase scope calls for bounded proof, not a new reliability platform.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md] |

**Key insight:** Phase 5 should hand-roll only the domain-specific claim lifecycle, not generic locking infrastructure or a workflow engine.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Counting history and assuming that prevents the next race

**What goes wrong:** two workers both observe the same historical breaker count and both execute the mitigation anyway.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][VERIFIED: lib/parapet/automation/executor.ex]
**Why it happens:** the current breaker query is disconnected from ownership acquisition and side-effect execution.[VERIFIED: lib/parapet/automation/circuit_breaker.ex]
**How to avoid:** claim first, then re-check the gate in the same transaction, then execute only for the winner.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]
**Warning signs:** concurrent tests still show two `mitigation_executed` entries or two side-effect invocations for one `{incident, step}` key.[VERIFIED: lib/parapet/operator.ex]

### Pitfall 2: Treating Oban uniqueness as a concurrency proof

**What goes wrong:** a test shows duplicate insert suppression, but execution still races under multiple workers or retries.[CITED: https://hexdocs.pm/oban/unique_jobs.html]
**Why it happens:** uniqueness is insertion-time logic, while execution concurrency is controlled separately by queue processing and worker behavior.[CITED: https://hexdocs.pm/oban/unique_jobs.html][CITED: https://hexdocs.pm/oban/job_lifecycle.html]
**How to avoid:** keep unique jobs for pressure relief, but prove execution safety with claim-row tests.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]
**Warning signs:** tests assert `job.conflict?` but never inspect durable outcome rows or timeline invariants.[CITED: https://hexdocs.pm/oban/unique_jobs.html]

### Pitfall 3: Losing the side effect across crash/retry windows

**What goes wrong:** the policy sends an alert, the node dies before evidence persistence, and the retry sends the alert again.[VERIFIED: lib/parapet/escalation/worker.ex][CITED: https://hexdocs.pm/oban/job_lifecycle.html]
**Why it happens:** current escalation execution persists after the policy call and has no durable ownership/effect state before the call.[VERIFIED: lib/parapet/escalation/worker.ex]
**How to avoid:** derive a stable idempotency key from the claim, reuse it on retry, and persist claim state transitions.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][VERIFIED: lib/parapet/operator/action_payload.ex]
**Warning signs:** retry tests need process-local flags or mailbox assertions to prove duplicate suppression because there is no durable effect sink.[VERIFIED: test/parapet/escalation/worker_test.exs]

## Code Examples

Verified patterns from official sources:

### Row-level lock at the winner-selection seam
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Query.html
incident =
  from(i in Incident,
    where: i.id == ^incident_id,
    lock: "FOR UPDATE"
  )
  |> Repo.one!()
```

### Constraint-backed no-op on duplicate claim insert
```elixir
# Source: https://hexdocs.pm/ecto/constraints-and-upserts.html
Repo.insert(
  %ActionClaim{
    incident_id: incident_id,
    action_kind: "escalation",
    action_key: escalation_key,
    status: "claimed"
  },
  on_conflict: :nothing,
  conflict_target: [:incident_id, :action_kind, :action_key]
)
```

### Atomic outcome transition
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Repo.html
from(c in ActionClaim,
  where: c.id == ^claim.id and c.status in ["claimed", "failed_retryable"],
  update: [set: [status: "executed", finished_at: ^DateTime.utc_now()]]
)
|> Repo.update_all([])
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Queue uniqueness as duplicate protection | Queue uniqueness plus DB-owned idempotency/claim state | Current Oban docs distinguish uniqueness from concurrency in v2.22.1 docs | Phase 5 should treat Oban uniqueness as advisory pressure relief, not the core correctness claim.[CITED: https://hexdocs.pm/oban/unique_jobs.html] |
| Read-then-write race checks | Constraint-backed inserts and transactional locking | Current Ecto docs and guides | The repo should move breaker/escalation safety to transaction-time truth.[CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html][CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |

**Deprecated/outdated:**
- Relying on a plain historical count query in front of side effects as the primary race guard is outdated for this phase’s guarantees.[VERIFIED: lib/parapet/automation/circuit_breaker.ex]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A test-only use of `Oban.Testing` can be added without product-level design friction because the repo already depends on Oban in test-capable form. | Standard Stack | Low; the phase can still use direct worker invocation plus real Repo assertions if `Oban.Testing` proves awkward.[ASSUMED] |
| A2 | A dedicated claim table is acceptable from a schema-footprint perspective because the phase context prioritizes explicit inspectable coordination over minimizing schema count. | Likely Implementation Strategy | Medium; if schema count becomes a product concern, the planner would need to revisit how much claim lifecycle state must be first-class.[ASSUMED] |

## Open Questions (RESOLVED)

1. **How should the library bootstrap a real Repo-backed concurrency test harness?** Resolved.
   - What we know: the current suite uses `DummyRepo`/Agent-style repos and there is no `DataCase` or sandbox harness in `test/support` today.[VERIFIED: test/parapet/automation/circuit_breaker_test.exs][VERIFIED: test/parapet/escalation/worker_test.exs][VERIFIED: test/test_helper.exs]
   - Decision: use a small test-only Postgres repo inside this library and bootstrap the canonical Parapet spine tables from the existing `lib/mix/tasks/parapet.gen.spine.ex` DDL, extracted into reusable test support rather than copied ad hoc into each test.[VERIFIED: lib/mix/tasks/parapet.gen.spine.ex]
   - Rationale: the repo does not ship standalone base spine migrations in `priv/repo/migrations/`, so Phase 5 must make the generator-backed table definitions reusable for a dedicated proof lane instead of relying on generated-host patterns or skip-only tests.[VERIFIED: priv/repo/migrations/20260511000000_add_runbook_data_to_incidents.exs][VERIFIED: lib/mix/tasks/parapet.gen.spine.ex]

2. **Should loser attempts write a timeline entry every time?** Resolved.
   - What we know: the phase context wants typed, calm, durable outcomes but also low-noise chronology.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md]
   - Decision: persist claim state for every loser or retry transition, but emit main-timeline entries only for operator-meaningful outcomes such as first duplicate suppression, breaker short-circuit, retryable escalation failure, or terminal failure.
   - Rationale: this preserves durable truth for tests and retries without turning the incident chronology into a low-level lock-attempt log, which matches the evidence-first operator posture for the phase.[VERIFIED: lib/parapet/operator/workbench_contract.ex][VERIFIED: lib/parapet/evidence.ex]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | test and implementation work | ✓ | `1.19.5` | — |
| Mix | test and migration commands | ✓ | `1.19.5` | — |
| PostgreSQL client/server | real concurrency integration tests | ✓ | `14.17` | Dockerized Postgres if local service setup is inconvenient |
| Docker | optional isolated DB test lane | ✓ | `29.4.1` | local Postgres |

**Missing dependencies with no fallback:**
- None.[VERIFIED: `mix --version`][VERIFIED: `elixir --version`][VERIFIED: `psql --version`][VERIFIED: `postgres --version`][VERIFIED: `docker --version`]

**Missing dependencies with fallback:**
- None.[VERIFIED: local environment probes on 2026-05-20]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir `1.19.5`.[VERIFIED: test/test_helper.exs][VERIFIED: `mix --version`] |
| Config file | `test/test_helper.exs`; no `DataCase`/sandbox harness detected yet.[VERIFIED: test/test_helper.exs][VERIFIED: repo grep for `DataCase` and `Ecto.Adapters.SQL.Sandbox`] |
| Quick run command | `mix test test/parapet/automation/circuit_breaker_test.exs test/parapet/automation/executor_test.exs test/parapet/escalation/worker_test.exs test/parapet/evidence_test.exs`.[VERIFIED: local command run on 2026-05-20] |
| Full suite command | `mix test`.[ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| P5-01 | concurrent mitigation attempts produce one winner and typed loser outcomes | integration | `mix test test/parapet/concurrency/automation_claim_test.exs -x` | ❌ Wave 0 |
| P5-02 | breaker gate is evaluated atomically at claim time | integration | `mix test test/parapet/concurrency/automation_claim_test.exs -x` | ❌ Wave 0 |
| P5-03 | escalation retries after simulated crash/restart do not duplicate external effect intent | integration | `mix test test/parapet/concurrency/escalation_claim_test.exs -x` | ❌ Wave 0 |
| SCALE-02 | multi-node or concurrency simulation proves one execution path under contention | integration / smoke | `mix test test/parapet/concurrency/automation_claim_test.exs test/parapet/concurrency/multi_node_smoke_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/parapet/automation/circuit_breaker_test.exs test/parapet/automation/executor_test.exs test/parapet/escalation/worker_test.exs`
- **Per wave merge:** `mix test test/parapet/concurrency/automation_claim_test.exs test/parapet/concurrency/escalation_claim_test.exs`
- **Phase gate:** full targeted Phase 5 suite green, including one real contention proof and one retry/crash proof, before `/gsd-verify-work`.[VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `test/support/data_case.ex` — SQL sandbox/manual transaction helper for a real Repo-backed lane.[VERIFIED: repo grep found no DataCase]
- [ ] `test/support/phase5_repo.ex` — test-only Repo module for Postgres concurrency proof.[VERIFIED: repo grep found no real Repo test harness]
- [ ] `test/parapet/concurrency/automation_claim_test.exs` — covers P5-01, P5-02, and SCALE-02.
- [ ] `test/parapet/concurrency/escalation_claim_test.exs` — covers P5-03.
- [ ] Claim-table migration/test bootstrap — needed before the concurrency suite can prove duplicate suppression.[VERIFIED: current `priv/repo/migrations` lacks claim-table migration]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not add a new auth surface; it hardens backend automation paths.[VERIFIED: phase scope in .planning/ROADMAP.md] |
| V3 Session Management | no | No session semantics change in this phase.[VERIFIED: phase scope in .planning/ROADMAP.md] |
| V4 Access Control | yes | Keep execution behind existing backend seams; do not let UI projection state become an authority for effect execution.[VERIFIED: lib/parapet/operator.ex][VERIFIED: lib/parapet/evidence.ex] |
| V5 Input Validation | yes | Continue validating typed action payloads and schema changesets with Ecto.[VERIFIED: lib/parapet/operator/action_payload.ex][VERIFIED: lib/parapet/spine/incident.ex] |
| V6 Cryptography | no | No new cryptographic primitive is needed; idempotency keys are identifiers, not secrets.[VERIFIED: lib/parapet/operator/action_payload.ex][ASSUMED] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Duplicate mitigation or alert under contention | Tampering / DoS | Unique claim row plus transaction-time gate checks.[CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html][CITED: https://hexdocs.pm/ecto/Ecto.Query.html] |
| Retry after crash replays external effect | Repudiation / DoS | Durable claim state plus stable idempotency key reused across retries.[CITED: https://hexdocs.pm/oban/job_lifecycle.html][VERIFIED: lib/parapet/operator/action_payload.ex] |
| UI-derived state treated as execution truth | Elevation of privilege | Keep `WorkbenchContract` as projection only; execute through backend claim service.[VERIFIED: lib/parapet/operator/workbench_contract.ex][VERIFIED: lib/parapet/operator.ex] |

## Sources

### Primary (HIGH confidence)

- `lib/parapet/automation/circuit_breaker.ex` - current breaker query and race window.
- `lib/parapet/automation/executor.ex` - current uniqueness settings, idempotency key derivation, and side-effect ordering.
- `lib/parapet/escalation/worker.ex` - current escalation decision and persistence ordering.
- `lib/parapet/evidence.ex` - transactional evidence seam.
- `lib/parapet/operator.ex` and `lib/parapet/operator/action_payload.ex` - idempotency payload contract and escalation mutation seams.
- `.planning/phases/05-multi-node-safety-verification/05-CONTEXT.md` - locked phase decisions and proof posture.
- `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md` - active v0.9 phase scope and `SCALE-02`.
- `mix.lock`, `mix hex.info ecto`, `mix hex.info ecto_sql`, `mix hex.info oban` - live dependency versions.
- `https://hexdocs.pm/ecto/Ecto.Query.html` - row locking via `lock`.
- `https://hexdocs.pm/ecto/Ecto.Repo.html` - `update_all` and transaction primitives.
- `https://hexdocs.pm/ecto/constraints-and-upserts.html` - constraint-backed inserts and `on_conflict`.
- `https://hexdocs.pm/oban/unique_jobs.html` - uniqueness scope and guarantees.
- `https://hexdocs.pm/oban/job_lifecycle.html` - retryable/completed/discarded lifecycle.

### Secondary (MEDIUM confidence)

- Existing tests under `test/parapet/automation/*`, `test/parapet/escalation/worker_test.exs`, `test/parapet/evidence_test.exs` - current proof surface and its limitations.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase stays on the repo’s existing Ecto/Oban/Postgres stack and versions were verified live.[VERIFIED: mix.lock][VERIFIED: `mix hex.info ecto`][VERIFIED: `mix hex.info ecto_sql`][VERIFIED: `mix hex.info oban`]
- Architecture: HIGH - the recommendation follows both the locked phase context and the current code’s actual seams.[VERIFIED: .planning/phases/05-multi-node-safety-verification/05-CONTEXT.md][VERIFIED: lib/parapet/automation/executor.ex][VERIFIED: lib/parapet/escalation/worker.ex]
- Pitfalls: HIGH - the main pitfalls are directly visible in the current implementation and reinforced by official Oban/Ecto docs.[VERIFIED: lib/parapet/automation/circuit_breaker.ex][CITED: https://hexdocs.pm/oban/unique_jobs.html][CITED: https://hexdocs.pm/ecto/constraints-and-upserts.html]

**Research date:** 2026-05-20
**Valid until:** 2026-06-19
