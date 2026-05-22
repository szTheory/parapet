# Phase 4 Validation: Operator UI Surfacing

## Roadmap Requirements Covered

- **UI-01:** Escalation and mitigation UI
  - Operator UI displays the active escalation chain and time-until-next-escalation on the Incident detail page.
  - Operator UI highlights system-executed mitigations distinctly from human-executed ones.
  - Operator UI provides a manual `Trigger Next Escalation` panic button.

## Test Strategies

### Unit / Seam Tests

- `test/parapet/operator_test.exs`
  - *Strategy:* exercise the audited operator boundary with the in-memory dummy repo.
  - *Scenarios:*
    - Manual trigger writes a timeline entry, audit row, and any bounded escalation summary updates.
    - Suppression writes durable expiring command state and remains distinct from acknowledge or resolve.
    - `incident_detail/1` returns the richer escalation-aware derived payload without hiding chronology.

- `test/parapet/operator/workbench_contract_test.exs`
  - *Strategy:* build incidents and timeline entries as plain structs and assert deterministic projection.
  - *Scenarios:*
    - Escalation summary is derived from incident summary plus typed chronology.
    - System actor identity is surfaced distinctly from operator or AI/copilot actors.
    - Countdown/next-step fields are treated as projected state, not authoritative scheduler state.

- `test/parapet/escalation/worker_test.exs`
  - *Strategy:* verify worker gating against incident state and durable suppression state.
  - *Scenarios:*
    - Worker short-circuits when escalation is suppressed.
    - Worker appends explicit typed chronology for suppression and normal execution paths.
    - Manual trigger or retry semantics do not bypass the worker truth gate.

### Generated UI / Integration Tests

- `test/parapet/operator_ui_integration_test.exs`
  - *Strategy:* assert the generated templates preserve the host-owned responsive layout while adopting Phase 4 controls and rendering contracts.
  - *Scenarios:*
    - Detail template still routes all risky actions through `Parapet.Operator`.
    - Components render a distinct escalation summary section and typed system-action timeline markers.
    - Manual controls appear after context instead of ahead of the summary panel.

- `test/parapet/operator_ui_compile_out_test.exs`
  - *Strategy:* ensure new template logic does not widen optional Phoenix coupling or break compile-out posture.

### Functional Validation

- *Strategy:* create an incident with automation and escalation evidence, then verify the operator detail surface answers:
  - what state the incident is in now,
  - whether the system already acted,
  - whether escalation is pending or suppressed,
  - what the next safe operator control is,
  - and where the durable chronology proves it.

## Automated Commands

- `mix test test/parapet/operator_test.exs`
- `mix test test/parapet/operator/workbench_contract_test.exs`
- `mix test test/parapet/escalation/worker_test.exs`
- `mix test test/parapet/operator_ui_integration_test.exs test/parapet/operator_ui_compile_out_test.exs`
- `mix compile --warnings-as-errors`
