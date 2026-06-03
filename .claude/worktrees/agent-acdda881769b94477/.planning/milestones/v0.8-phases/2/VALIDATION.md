# Phase 2 Validation

## Goal Coverage Mapping
Phase 2 Goal: Implement Bounded Runbook Execution to allow safe, deterministic auto-mitigations using the existing Operator API.

| Requirement ID | Description | Covered By |
| --- | --- | --- |
| AUT-01 | Extend `Parapet.Runbook` DSL with `auto_execute` configuration. | 02-01-PLAN.md (Task 1) |
| AUT-01 | Implement the `Parapet.Automation.Executor` that acts as the `:system` identity. | 02-01-PLAN.md (Task 2) |
| AUT-01 | Route matching incoming alerts directly to the Executor. | 02-01-PLAN.md (Task 2) |
| AUT-01 | Ensure `ToolAudit` and `TimelineEntry` records are correctly stamped with system identity. | 02-01-PLAN.md (Task 1) |

## Goal-Backward Test Plan

### Truth 1: Developer can configure a runbook step with auto_execute: true
**Validation Steps:**
- Inspect `lib/parapet/runbook.ex` to ensure `step/2` macro parses and stores `auto_execute`.
- `mix test test/parapet/runbook_test.exs` proves that the DSL correctly maps `auto_execute` to internal step definitions and defaults to false.

### Truth 2: Execution is durably logged with system:automation:executor identity
**Validation Steps:**
- Trigger an automated execution through the executor (or simulate it in tests).
- Query the database (or rely on `operator_test.exs` output) to confirm both a `ToolAudit` and a `TimelineEntry` record are created with `actor: "system:automation:executor"`.
- Verify the Operator API's `execute_runbook_step/3` persists both records securely.

### Truth 3: System automatically executes auto-execute steps when new incident is created
**Validation Steps:**
- Create a test alert webhook payload that targets a runbook with an `auto_execute: true` step.
- Verify through `test/parapet/spine/alert_processor_test.exs` that the `Ecto.Multi` transaction inserts an `Oban.Job` for `Parapet.Automation.Executor`.
- Run the Oban worker in test mode and assert it attempts to call `Operator.execute_runbook_step/3`.

### Truth 4: System prevents flap-looping by only enqueueing on new incident creation
**Validation Steps:**
- Ensure `test/parapet/spine/alert_processor_test.exs` tests flap updates (an alert updating an *existing* incident).
- Assert that no new `Oban.Job` for automation is enqueued during these updates.
- Verify `Parapet.Automation.Executor` uses unique Oban configuration (`unique: [period: 3600, keys: [:incident_id, :step_id]]`) for defense-in-depth against duplicate execution.