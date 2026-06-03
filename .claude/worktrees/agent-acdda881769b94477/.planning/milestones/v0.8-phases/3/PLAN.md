---
phase: 03-circuit-breakers
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/parapet/automation/circuit_breaker.ex
  - test/parapet/automation/circuit_breaker_test.exs
  - lib/parapet/automation/executor.ex
  - test/parapet/automation/executor_test.exs
autonomous: true
requirements:
  - CIR-01
must_haves:
  truths:
    - Automation cannot execute infinitely due to flap protection.
    - When flap threshold is exceeded, the execution is discarded and a timeline entry is recorded.
    - When flap threshold is exceeded, an escalation job is automatically enqueued for a human.
  artifacts:
    - path: lib/parapet/automation/circuit_breaker.ex
      provides: Flap protection threshold query
    - path: lib/parapet/automation/executor.ex
      provides: Short-circuiting logic before Operator mitigation
  key_links:
    - from: lib/parapet/automation/executor.ex
      to: lib/parapet/automation/circuit_breaker.ex
      via: allow?(incident_id, step_id) function call
    - from: lib/parapet/automation/executor.ex
      to: lib/parapet/escalation/worker.ex
      via: Oban.insert!() when circuit tripped
---

<objective>
Implement safety guardrails to prevent infinite automation loops (flapping) during runbook mitigations.

Purpose: Guarantee that automated actions are safely bounded within an execution window, escalating to human operators automatically if the circuit trips.
Output: Circuit breaker component and short-circuit logic embedded within the automation executor.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/milestones/v0.8-ROADMAP.md
@.planning/milestones/v0.8-phases/3/PATTERNS.md
@.planning/milestones/v0.8-phases/3/RESEARCH.md
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Implement CircuitBreaker module with Ecto Lookbacks</name>
  <files>lib/parapet/automation/circuit_breaker.ex, test/parapet/automation/circuit_breaker_test.exs</files>
  <behavior>
    - Test 1: `allow?/2` returns true when ToolAudit executions are below threshold.
    - Test 2: `allow?/2` returns false when ToolAudit executions reach or exceed threshold within the time window.
  </behavior>
  <action>
    Create `Parapet.Automation.CircuitBreaker`. Implement `allow?(incident_id, step_id)`.
    - Fetch configuration from `Application.get_env(:parapet, :automation, [])` using the config pattern analogous to `lib/parapet/escalation/worker.ex`.
    - Set defaults for `max_executions` (3) and `within` (3600 seconds).
    - Query the `Parapet.Spine.ToolAudit` joining on `Parapet.Spine.TimelineEntry` based on the query pattern found in `lib/parapet/evidence/retrospective.ex`.
    - The query should filter by `incident_id`, a `cutoff` date calculated by `DateTime.add(now, -within, :second)`, and extract the `idempotency_key` via JSON fragment to uniquely match the step.
    - Return true if the query count is less than `max_executions`.
    - Create `Parapet.Automation.CircuitBreakerTest` to mock these database queries and test boundaries.
  </action>
  <verify>
    <automated>mix test test/parapet/automation/circuit_breaker_test.exs</automated>
  </verify>
  <done>Circuit breaker executes valid Ecto queries and restricts execution when the limit is hit.</done>
</task>

<task type="auto">
  <name>Task 2: Plumb CircuitBreaker Short-Circuit into Executor</name>
  <files>lib/parapet/automation/executor.ex, test/parapet/automation/executor_test.exs</files>
  <action>
    Modify `Parapet.Automation.Executor.perform/1`:
    - Before calling `Parapet.Operator.execute_runbook_step/3`, call `Parapet.Automation.CircuitBreaker.allow?(incident_id, step_id)`.
    - If `allow?/2` is true, proceed with mitigation execution.
    - If false, implement the short-circuit and escalation pattern analogous to `lib/parapet/escalation/worker.ex`:
      1. Use `Parapet.Evidence.append_timeline/2` to record type `"automation_circuit_tripped"`.
      2. Durably trigger an escalation job by enqueuing `Parapet.Escalation.Worker` using `Oban.insert!()`. Ensure you check if `Code.ensure_loaded?(Oban)` and `:escalation_policy` config is present.
      3. Return `{:discard, "Circuit breaker tripped for step #{step_id}"}`.
    - Update `test/parapet/automation/executor_test.exs` to verify that when `CircuitBreaker.allow?/2` returns false, it safely discards and logs the timeline entry.
  </action>
  <verify>
    <automated>mix test test/parapet/automation/executor_test.exs</automated>
  </verify>
  <done>Executor delegates to the circuit breaker and safely aborts flapping actions by alerting humans.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| System → DB | Automated process querying historical audit logs |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-03-01 | Denial of Service | `Parapet.Automation.Executor` | mitigate | Implementation of the `CircuitBreaker` inherently mitigates looping and resource exhaustion DoS from auto-mitigations. |
| T-03-02 | Information Disclosure | `Parapet.Automation.CircuitBreaker` | accept | The circuit breaker runs purely on the internal system level and reads historical records but does not output raw payload data back to untrusted endpoints. |
</threat_model>

<verification>
- `mix test test/parapet/automation/circuit_breaker_test.exs` passes.
- `mix test test/parapet/automation/executor_test.exs` passes.
</verification>

<success_criteria>
Automation mitigations are strictly bounded. A runaway runbook task will be short-circuited after the `max_executions` threshold within the configured window, automatically appending timeline context and durably enqueuing an escalation to human operators.
</success_criteria>

<output>
After completion, create `.planning/milestones/v0.8-phases/3/03-01-SUMMARY.md`
</output>