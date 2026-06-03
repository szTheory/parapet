# Phase 3 Architectural Decisions: Circuit Breakers & Flap Protection

## Context & Principles

Phase 3 focuses on introducing Circuit Breakers and Flap Protection for automated runbook execution in Parapet. 

As a Phoenix-native reliability substrate, Parapet must adhere to the following principles:
- **Evidence-first:** Every action, block, or escalation must leave a clear, cited trace in the incident timeline.
- **Protect users, not graphs:** Circuit breakers exist to prevent runaway automation from compounding user harm. 
- **Keep operators inside the guardrail:** Automation is bounded; human operators retain ultimate authority but are provided with context and warnings when overriding safety limits.
- **Idiomatic Elixir:** Configuration should live as close to the relevant code as possible, leveraging macros and explicit behaviour rather than opaque global state.

Here are the definitive architectural recommendations for Phase 3.

---

## 1. Configuration Scope: Where should limits be configured?

**Decision: Runbook Step DSL (`Parapet.Runbook.step/2`)**

Circuit breaker limits (`max_executions`, `within` window) must be configured directly on the runbook step definition.

```elixir
step :restart_worker,
  label: "Restart Payment Worker",
  auto_execute: true,
  circuit_breaker: [max_executions: 3, within: :timer.minutes(15)]
```

### Rationale
- **Locality of Behavior:** The safety threshold of an action is an intrinsic property of the action itself. Restarting a worker might be safe to try 3 times in 15 minutes, while flushing a cache or failing over a database should perhaps only be attempted once per hour. 
- **Developer Ergonomics:** Placing this in the `Parapet.Runbook` module allows developers to review the mitigation logic and its safety constraints in a single glance.
- **Avoids Alert Coupling:** An alert defines *when* to trigger an incident (e.g., `checkout_success_rate` burning). It should not dictate *how* a runbook mitigates it. Runbooks are reusable; their safety constraints must travel with them.

---

## 2. Identity Filtering: Whose executions consume the budget?

**Decision: Query all identities, but apply asymmetric enforcement.**

The circuit breaker should query the execution history (`ToolAudit` or Incident Evidence) for *all* executions of the step within the time window, regardless of whether they were triggered by `:system` (automation) or a human operator. However, enforcement behaves differently based on the acting identity:

1. **Automation (`:system`):** Strictly blocked if `total_executions >= max_executions`. Automation must never bypass the breaker.
2. **Human Operator:** Warned, but permitted to bypass. 

### Rationale
- **System Stability:** Flapping is flapping. If a human restarts a worker twice, and automation tries a third time a minute later, the system is still experiencing high-frequency state changes. The circuit breaker's job is to recognize this thrashing and halt the automation.
- **Human Authority:** A tired SRE at 3 AM might know that a 4th restart is the only way to clear a specific deadlock. Blocking them completely is a "fortress software" anti-pattern. Instead, present them with evidence: *"Circuit breaker open: this step was executed 3 times in the last 15m. [Force Execute]"*.

---

## 3. Escalation Mechanics: What happens when the breaker trips?

**Decision: Immediate, synchronous escalation (Short-Circuit the Wait).**

When automated execution is blocked by an open circuit breaker, the system must immediately trigger the next step in the `Escalation.Policy` (e.g., paging the human). Do *not* wait for an existing scheduled Oban job to run its course.

### Rationale
- **Page on User Harm:** If a SEV-1 incident is burning error budget and the automation has exhausted its allowed attempts, the incident is officially **unmitigated**. Delaying the page violates the core SRE contract.
- **Evidence Trail:** The timeline must explicitly log the sequence:
  1. `runbook_execution_attempted`
  2. `circuit_breaker_tripped` (with payload detailing the limit reached)
  3. `escalation_triggered` (reason: automation exhausted)
- **Implementation:** The worker attempting the runbook execution should catch the `{:error, :circuit_breaker_open}` response and synchronously dispatch to the `Escalation.Worker` or `Escalation.Policy`.

---

## 4. Override Mechanics: How do manual overrides interact with the system?

**Decision: Distinct pathways for "Mitigation Overrides" vs. "Escalation Triggers".**

We must separate the concepts of forcing a runbook step from forcing an escalation.

1. **Runbook Step Override (`force: true`):**
   - Triggered from the Runbook UI when a human clicks "Force Execute" on a circuit-broken step.
   - Bypasses the circuit breaker limit.
   - Appends a `human_override` and `execution_executed` event to the timeline.
   - Does *not* automatically resolve or escalate the incident; it's simply a manual mitigation attempt.

2. **Panic Button / "Escalate Now":**
   - Triggered from the Incident UI.
   - Completely independent of runbook circuit breakers.
   - Immediately invokes `Parapet.Escalation.Policy.escalate/2`.
   - Appends a `manual_escalation_triggered` event to the timeline.
   - Used when the operator realizes the current runbook is insufficient and needs to page a secondary team or higher-tier commander immediately.

### Rationale
- **Clarity of Intent:** Mixing mitigation overrides with escalation policies creates dangerous coupling. A human forcing a worker restart is trying to *fix* the problem; a human clicking "Escalate" is acknowledging they *cannot* fix it alone.
- **Auditability:** Explicit `force: true` flags on runbook execution endpoints ensure that standard `ToolAudit` logs clearly differentiate routine manual executions from intentional safety bypasses.