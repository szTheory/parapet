# Phase 3 Validation: Circuit Breakers & Flap Protection

## Roadmap Requirements Covered

- **CIR-01:** Ecto-Backed Circuit Breakers
  - System implements a circuit breaker that queries `ToolAudit` before auto-executing a runbook.
  - System prevents execution if the runbook has fired more than a configurable threshold.
  - System automatically escalates the incident and adds a timeline entry if the circuit breaker opens.

## Test Strategies

### Unit Tests

- `test/parapet/automation/circuit_breaker_test.exs`
  - *Strategy:* Mock the Repo or use a sandbox database to insert `ToolAudit` records with varying `inserted_at` timestamps and `idempotency_key` payloads.
  - *Scenarios:*
    - Threshold not met: Function returns `true`.
    - Threshold met exactly or exceeded: Function returns `false`.
    - Threshold exceeded but past `ToolAudit` records fall outside the configured `within` time window: Function returns `true`.

- `test/parapet/automation/executor_test.exs`
  - *Strategy:* Ensure that `Executor.perform/1` evaluates the `CircuitBreaker.allow?/2` output.
  - *Scenarios:*
    - Circuit breaker trips (returns `false`): Asserts `Parapet.Evidence.append_timeline/2` was correctly invoked and an Oban job for `Parapet.Escalation.Worker` was enqueued to alert human operators. Asserts the function returns `{:discard, reason}`.
    - Circuit breaker allows (returns `true`): Asserts `Parapet.Operator.execute_runbook_step/3` is called successfully.

### Integration / Functional Tests

- *Strategy:* Simulate an end-to-end flapping alert event causing multiple auto-execute triggers. Verify that after `max_executions` is reached, the subsequent runbook executions are safely blocked, the system does not enter a runaway loop, and an escalation job successfully appears in the Oban job queue.
