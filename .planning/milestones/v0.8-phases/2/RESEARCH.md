# Phase 2: Bounded Runbook Execution - Research

**Researched:** 2024-05-18
**Domain:** System Automation, Audit Logging, and Background Jobs
**Confidence:** HIGH

## Summary

This phase implements "Bounded Runbook Execution" by extending the existing `Parapet.Runbook` DSL and safely executing automated steps via `Parapet.Operator`. By routing matching alerts to an Oban worker (`Parapet.Automation.Executor`), Parapet can perform one-click mitigations automatically acting as a strictly identified system actor (`system:automation:executor`). 

**Primary recommendation:** Extend the `@steps` accumulator in `Parapet.Runbook` with an `auto_execute: boolean` option. Hook into `Parapet.Spine.AlertProcessor` on *new incident creation* to spawn Oban jobs for each auto-executing step. Modify `Parapet.Operator.execute_runbook_step/3` to durably inject the `ActionPayload.actor` into the `TimelineEntry` payload, guaranteeing attribution.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| DSL Parsing (`auto_execute`) | API / Backend | — | Evaluated at compile-time via `Parapet.Runbook` macros. |
| Background Execution | API / Backend | Database | `Parapet.Automation.Executor` uses Oban (DB-backed queue) for retries and durable dispatch. |
| Alert Ingestion/Routing | API / Backend | — | `Parapet.Spine.AlertProcessor` evaluates `runbook_data` when an incident opens. |
| Durable Audit Stamping | Database | API / Backend | `Parapet.Operator` enforces immutable facts for `ToolAudit` and `TimelineEntry`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Oban | >= 0.0.0 | Background jobs | Parapet's standard durable queue engine for async behaviors (escalation, now automation). |
| Ecto | >= 3.0 | Database | Used for `ToolAudit` lookbacks and wrapping state transitions safely. |

## Architecture Patterns

### Pattern 1: Bounded Macro Extensions
**What:** Extending the `Parapet.Runbook` DSL to include a new boolean field.
**When to use:** When adding static configuration that must be available in `incident.runbook_data` at runtime.
**Example:**
```elixir
defmacro step(id, opts) do
  quote do
    @steps %{
      id: unquote(id),
      # ... existing keys
      auto_execute: Keyword.get(unquote(opts), :auto_execute, false)
    }
  end
end
```

### Pattern 2: Operator Payload Injection
**What:** `Parapet.Operator.ActionPayload` dictates the identity (`actor`), but `execute_runbook_step` currently drops this when creating the `TimelineEntry`.
**When to use:** Always, when writing `TimelineEntry` for automated actions.
**Example:**
```elixir
timeline_attrs = %{
  type: "mitigation_executed",
  payload: %{
    "step_id" => to_string(step_atom),
    "module" => to_string(module),
    "result" => inspect(mitigation_result),
    "actor" => payload.actor # <-- Crucial addition for system identity stamping
  }
}
```

### Pattern 3: Idempotent Alert Processing
**What:** `Parapet.Spine.AlertProcessor.process_firing_alert/1` receives alerts continually.
**When to use:** When determining when to enqueue an Oban job, ensuring it runs exactly once per incident.
**How:** Inside `process_firing_alert/1`, enqueue the `Parapet.Automation.Executor` job via `Ecto.Multi` *only* if `is_nil(existing_incident)` (i.e., this is a newly opened incident). Leverage Oban unique constraints by specifying `unique: [period: 3600, keys: [:incident_id, :step_id]]` in the worker as a secondary defense.

### Anti-Patterns to Avoid
- **Ad-hoc `apply` for automation:** Bypassing `Parapet.Operator`. All automation MUST flow through `Parapet.Operator.execute_runbook_step/3` to guarantee uniform telemetry and audit trails.
- **Flap-looping:** Enqueueing the automation on every webhook delivery. Webhooks replay frequently; Oban unique jobs or strict new-incident checks are mandatory.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Retry Logic | Custom Task supervisors or GenServers | Oban | Native durable retries, observability, and unique-job guarantees out of the box. |
| Idempotency checking | Custom DB queries before insert | Oban Unique Jobs | `use Oban.Worker, unique: [period: 3600, keys: [:incident_id, :step_id]]` prevents dual-execution trivially. |

## Common Pitfalls

### Pitfall 1: Unattributed Automation
**What goes wrong:** The UI shows a mitigation occurred, but it looks like it was initiated by a human or a ghost.
**Why it happens:** `TimelineEntry` payload for mitigations does not currently persist the `payload.actor` field.
**How to avoid:** Ensure `Parapet.Operator.execute_runbook_step/3` puts `"actor" => payload.actor` in the `TimelineEntry` payload.

### Pitfall 2: Infinite Alert Processing Loops
**What goes wrong:** A step is auto-executed every 15 seconds.
**Why it happens:** Prometheus Alertmanager repeatedly fires the webhook while the alert is active.
**How to avoid:** Only spawn the automation if `incident` is newly created (i.e., `is_nil(existing_incident)` inside `process_firing_alert/1`).

## Code Examples

### Enqueuing Automation in Ecto.Multi
```elixir
# Inside `AlertProcessor.process_firing_alert/1` or similar
|> Ecto.Multi.run(:enqueue_automation, fn _repo, %{incident: incident} ->
  steps = Map.get(incident.runbook_data || %{}, "steps", [])
  
  Enum.each(steps, fn step ->
    if step["auto_execute"] do
      %{incident_id: incident.id, step_id: step["id"]}
      |> Parapet.Automation.Executor.new()
      |> Oban.insert!()
    end
  end)

  {:ok, :enqueued}
end)
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | test_helper.exs |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PH-2-1 | `step/2` macro sets `auto_execute: true` | unit | `mix test test/parapet/runbook_test.exs` | ✅ Wave 0 |
| PH-2-2 | Executor dispatches with `:system` identity | integration | `mix test test/parapet/automation/executor_test.exs` | ❌ Wave 0 |
| PH-2-3 | AlertProcessor enqueues Executor correctly | integration | `mix test test/parapet/spine/alert_processor_test.exs` | ✅ Wave 0 |
| PH-2-4 | Operator logs TimelineEntry with actor | unit | `mix test test/parapet/operator_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/automation/executor_test.exs` — Need to verify that `perform/1` correctly constructs the ActionPayload and delegates to `Parapet.Operator`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Actor Identity (`system:automation:executor`) |
| V3 Session Management | no | — |
| V4 Access Control | yes | `Parapet.Operator` validation |
| V5 Input Validation | yes | `Parapet.Operator.ActionPayload` strict struct |

### Known Threat Patterns for Elixir/Ecto

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Ghost Automation | Repudiation | Mandatory Actor identity injection in `ToolAudit` and `TimelineEntry`. |
| Unbounded Execution Loop | Denial of Service | Gate Oban job insertion on `is_nil(existing_incident)` and Oban `unique:` job constraints. |
