---
phase: "02"
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/parapet/runbook.ex
  - lib/parapet/operator.ex
  - lib/parapet/automation/executor.ex
  - lib/parapet/spine/alert_processor.ex
autonomous: true
requirements: ["AUT-01"]
must_haves:
  truths:
    - "Developer can configure a runbook step with auto_execute: true"
    - "Execution is durably logged with system:automation:executor identity"
    - "System automatically executes auto-execute steps when new incident is created"
    - "System prevents flap-looping by only enqueueing on new incident creation"
  artifacts:
    - path: "lib/parapet/automation/executor.ex"
      provides: "Oban worker for automation execution"
      contains: "use Oban.Worker"
    - path: "lib/parapet/runbook.ex"
      provides: "DSL configuration for auto_execute"
      contains: "auto_execute:"
  key_links:
    - from: "lib/parapet/spine/alert_processor.ex"
      to: "lib/parapet/automation/executor.ex"
      via: "Oban.insert enqueuing in Ecto.Multi"
      pattern: "Executor.new"
    - from: "lib/parapet/automation/executor.ex"
      to: "lib/parapet/operator.ex"
      via: "Operator API call"
      pattern: "Operator.execute_runbook_step"
---

<objective>
Implement Bounded Runbook Execution to allow safe, deterministic auto-mitigations using the existing Operator API.

Purpose: Protect SLOs by automatically executing predefined mitigations when specific alerts fire, without relying on autonomous AI mutation.
Output: Extended Runbook DSL, Automation Executor Oban worker, and automated alert routing.
</objective>

<execution_context>
@$HOME/.gemini/get-shit-done/workflows/execute-plan.md
@$HOME/.gemini/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md

<interfaces>
<!-- Key types and contracts the executor needs. Extracted from codebase. -->
From lib/parapet/operator.ex:
```elixir
defmodule Parapet.Operator.ActionPayload do
  defstruct [:actor, :reason, :correlation_id, :action_type, :idempotency_key]
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Core Automation Foundations (DSL & Operator identity)</name>
  <files>lib/parapet/runbook.ex, lib/parapet/operator.ex, test/parapet/runbook_test.exs, test/parapet/operator_test.exs</files>
  <action>
    1. In `lib/parapet/runbook.ex`, update the `step/2` macro to include `auto_execute: Keyword.get(unquote(opts), :auto_execute, false)` in the `@steps` map.
    2. In `lib/parapet/operator.ex`, update `execute_runbook_step/3` to inject the actor identity. Ensure the `timeline_attrs` payload includes `"actor" => payload.actor` so that the TimelineEntry durably records who performed the action (e.g., the system executor).
    3. Ensure existing tests pass and add specific unit tests for `auto_execute` in `runbook_test.exs`.
  </action>
  <verify>
    <automated>mix test test/parapet/runbook_test.exs test/parapet/operator_test.exs</automated>
  </verify>
  <done>Runbook DSL supports auto_execute and Operator properly durably stamps the TimelineEntry payload with the payload.actor.</done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Automation Execution Engine (Oban Worker & Router)</name>
  <files>lib/parapet/automation/executor.ex, lib/parapet/spine/alert_processor.ex, test/parapet/automation/executor_test.exs, test/parapet/spine/alert_processor_test.exs</files>
  <action>
    1. Create `lib/parapet/automation/executor.ex` as an `Oban.Worker`. Use `queue: :default` and add `unique: [period: 3600, keys: [:incident_id, :step_id]]` to prevent flap-looping.
    2. In `Executor.perform/1`, fetch the incident. If it exists, construct a `Parapet.Operator.ActionPayload` with `actor: "system:automation:executor"`, `action_type: :execute_mitigation`, and call `Parapet.Operator.execute_runbook_step/3`.
    3. In `lib/parapet/spine/alert_processor.ex`, update `process_firing_alert/1`. When a *new* incident is created (`is_nil(existing_incident)`), scan `runbook_data["steps"]` for any step with `auto_execute: true`. For each matching step, use `Ecto.Multi.insert/3` or `Ecto.Multi.run/3` to enqueue the `Executor` job via `Oban.insert!`.
    4. Write integration tests in `executor_test.exs` and `alert_processor_test.exs` to prove the routing and execution.
  </action>
  <verify>
    <automated>mix test test/parapet/automation/executor_test.exs test/parapet/spine/alert_processor_test.exs</automated>
  </verify>
  <done>Automation executor safely calls the Operator API under system identity, and AlertProcessor correctly routes new alerts to it.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Alert Ingestion -> Execution | Untrusted alert webhook triggers safe, predefined internal execution. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-02-01 | Repudiation | Operator | mitigate | Ensure TimelineEntry payload explicitly logs "actor" => payload.actor to prevent ghost automation. |
| T-02-02 | Denial of Service | AlertProcessor | mitigate | Enqueue Executor only on *new* incident creation (`is_nil(existing_incident)`) and use Oban unique constraints to prevent flap-looping. |
</threat_model>

<verification>
- `Parapet.Runbook` test ensures `auto_execute` defaults to false and can be set to true.
- `Parapet.Operator` test confirms `TimelineEntry` payload includes `actor`.
- `Parapet.Automation.Executor` tests prove safe delegation to `Operator.execute_runbook_step/3`.
- `Parapet.Spine.AlertProcessor` tests confirm automation is ONLY scheduled for new incidents, not flap updates.
</verification>

<success_criteria>
All automated tasks pass, and Phase 2 Requirements (AUT-01) are satisfied. Bounded runbook execution is deterministically handled via Oban and fully audited.
</success_criteria>

<output>
After completion, create `.planning/phases/2/02-01-SUMMARY.md`
</output>