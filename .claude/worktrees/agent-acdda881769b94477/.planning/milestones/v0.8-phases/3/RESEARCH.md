# Phase 3: Circuit Breakers & Flap Protection - Research

**Researched:** 2024-05-19
**Domain:** Automation Safety Guardrails
**Confidence:** HIGH

## Summary

The goal of this phase is to implement `Parapet.Automation.CircuitBreaker` to prevent flapping and runaway execution loops for automated runbook mitigations. This component will query `Parapet.Spine.ToolAudit` (via `TimelineEntry`) to enforce a bounded `max_executions` limit `within` a time window. 

When the threshold is reached, `Parapet.Automation.Executor` will short-circuit the execution, append a timeline entry indicating the circuit was tripped, and durably enqueue a `Parapet.Escalation.Worker` job to alert human operators that the automation was blocked due to flapping.

**Primary recommendation:** Implement `Parapet.Automation.CircuitBreaker` using Ecto to query `ToolAudit` records joined on `TimelineEntry` by `incident_id`, filtering by `inserted_at` and the `idempotency_key` embedded in the tool's `input` JSON.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| **Execution Loop Analysis** | API / Backend (Domain) | Database (Ecto) | CircuitBreaker queries Ecto database to count recent `ToolAudit` execution records. |
| **Circuit Breaking** | API / Backend (Worker) | — | `Parapet.Automation.Executor` (Oban Worker) short-circuits mitigation when `CircuitBreaker.allow?/2` returns false. |
| **Escalation Triggering** | API / Backend (Worker) | — | When tripped, `Executor` queues an escalation job to be processed asynchronously by `Parapet.Escalation.Worker`. |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REQ-01 | Implement `Parapet.Automation.CircuitBreaker` leveraging `ToolAudit` lookbacks. | Verified Ecto models. Query `ToolAudit` joining on `TimelineEntry` to filter by `incident_id` and the specific automation `idempotency_key`. |
| REQ-02 | Add config for `max_executions` and `within` window. | Use `Application.get_env(:parapet, :automation, [])` with fallback defaults. |
| REQ-03 | Plumb circuit-breaker rejections into the escalation engine. | `Parapet.Automation.Executor` should enqueue `Parapet.Escalation.Worker` on rejection and log to timeline. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | ~> 1.19 | Runtime | Framework standard. |
| Ecto | ~> 3.10 | Database | Existing ORM for durable evidence data and querying `ToolAudit`. |
| Oban | >= 0.0.0 | Job Queue | Already used for `Parapet.Automation.Executor` and `Parapet.Escalation.Worker`. |

## Architecture Patterns

### Component: `Parapet.Automation.CircuitBreaker`
**What:** Evaluates whether a mitigation step can be safely executed based on historical frequency.
**When to use:** In `Parapet.Automation.Executor.perform/1` before calling `Parapet.Operator.execute_runbook_step/3`.
**Example:**
```elixir
defmodule Parapet.Automation.CircuitBreaker do
  import Ecto.Query
  alias Parapet.Spine.{ToolAudit, TimelineEntry}

  def allow?(incident_id, step_id) do
    config = Application.get_env(:parapet, :automation, [])
    max_execs = Keyword.get(config, :max_executions, 3)
    within_secs = Keyword.get(config, :within, 3600)

    cutoff = DateTime.add(DateTime.utc_now(), -within_secs, :second)
    idempotency_key = "auto_exec_#{incident_id}_#{step_id}"

    count =
      Parapet.Evidence.repo().one(
        from a in ToolAudit,
          join: t in TimelineEntry, on: a.timeline_entry_id == t.id,
          where: t.incident_id == ^incident_id,
          where: a.tool_name == "operator_execute_mitigation",
          where: fragment("?->>'idempotency_key'", a.input) == ^idempotency_key,
          where: a.inserted_at > ^cutoff,
          select: count(a.id)
      )

    count < max_execs
  end
end
```

### Worker Short-Circuiting & Escalation
**Source:** `lib/parapet/automation/executor.ex`
**Pattern:**
```elixir
  if Parapet.Automation.CircuitBreaker.allow?(incident_id, step_id) do
    # ... execute step ...
  else
    # 1. Log to Timeline
    Parapet.Evidence.append_timeline(incident_id, %{
      type: "automation_circuit_tripped",
      payload: %{"step_id" => step_id, "reason" => "Flap protection threshold exceeded."}
    })

    # 2. Trigger Escalation
    if Code.ensure_loaded?(Oban) and Application.get_env(:parapet, :escalation_policy) do
      %{"incident_id" => incident_id}
      |> Parapet.Escalation.Worker.new()
      |> Oban.insert!()
    end

    {:discard, "Circuit breaker tripped for step #{step_id}"}
  end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| In-Memory Counters | GenServer-based counters for executions. | Ecto Queries on `ToolAudit` | In-memory state is lost on restarts or split across distributed nodes. The Ecto durable store guarantees safety and accuracy. |
| Time Arithmetic | Custom logic for second math. | `DateTime.add(now, -amount, :second)` | Elixir 1.19 standard library datetime math handles leap seconds and edge cases robustly. |

## Common Pitfalls

### Pitfall 1: Querying `ToolAudit` without `incident_id`
**What goes wrong:** Calculating total executions globally instead of per-incident.
**Why it happens:** `ToolAudit` schema does not contain `incident_id` directly.
**How to avoid:** Always join `TimelineEntry` (which contains `incident_id`) to properly scope the execution count to the current incident.

### Pitfall 2: Relying purely on `tool_name`
**What goes wrong:** The `tool_name` used by Operator API is `"operator_execute_mitigation"` globally for all steps.
**Why it happens:** The Operator maps different `step_id` inputs under the same generic tool name.
**How to avoid:** Use `fragment("?->>'idempotency_key'", a.input)` in the Ecto query to uniquely identify executions for the specific `incident_id` and `step_id` combination.

### Pitfall 3: Failing to trigger escalation asynchronously
**What goes wrong:** The automation silently blocks, and nobody is notified.
**Why it happens:** Short-circuiting without enqueuing `Parapet.Escalation.Worker`.
**How to avoid:** Explicitly queue an escalation Job via Oban before discarding the Executor run.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/automation/circuit_breaker_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Circuit Breaker respects limits | unit | `mix test test/parapet/automation/circuit_breaker_test.exs` | ❌ Wave 0 |
| REQ-03 | Executor triggers Escalation | unit | `mix test test/parapet/automation/executor_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/automation/circuit_breaker_test.exs` — covers REQ-01 (mock dummy repo limits)

## Open Questions (RESOLVED)

1. **Escalation Check in Executor**
   - What we know: `Evidence.create_incident/1` checks `Code.ensure_loaded?(Oban)` and `:escalation_policy` config before enqueuing `Escalation.Worker`. 
   - What's unclear: Should `Parapet.Automation.Executor` replicate this check exactly, or can it assume Oban is running (since it is an Oban Worker itself)?
   - Resolution: It is safe to assume Oban is loaded since `Executor` is an `Oban.Worker`. It should still verify `Application.get_env(:parapet, :escalation_policy)` is set before inserting the escalation job.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly follows the project's dependency specs.
- Architecture: HIGH - Mapped from 1:1 analogues inside `PATTERNS.md` and codebase discovery.
- Pitfalls: HIGH - Audited `Operator.execute_runbook_step` to confirm that `tool_name` is generic, necessitating the `idempotency_key` JSON query.
