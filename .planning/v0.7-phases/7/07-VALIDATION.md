# Validation for Phase 7: Host-Owned Recovery Runbooks

## Goals

Guarantee that Phase 7 provides host-generated, inspectable runbook templates plus preview-first, exact-scope recovery seams for async and delivery incidents without introducing autonomous mutation or broad replay controls.

## Requirements Validated

- **RNBK-01**: System provides host-generated runbook templates for stalled executors, dead-letter handling, safe retry decisions, provider outage triage, and callback-delay investigation.
- **RNBK-02**: System scopes any built-in recovery action behind explicit host wiring, audit logging, and preview-first safety guidance rather than autonomous replay or mutation.

## Validation Protocol

### 1. Runbook Catalog Generation Validation

- **Action**: Run the new runbook generator and inspect the generated host-owned modules.
- **Expected Outcome**:
  - host modules are generated for `stalled_executor`, `dead_letter`, `provider_outage`, and `callback_delay`
  - generated modules expose stable `__runbook_schema__/0` output
  - generated steps carry bounded metadata for capability-backed and guidance-only actions

### 2. Capability Registry Validation

- **Action**: Register the built-in named capabilities and inspect lookup behavior for wired and unwired capabilities.
- **Expected Outcome**:
  - only the locked capability names are surfaced by default
  - preview and execute callbacks are stored explicitly
  - missing capability wiring yields guidance-only behavior instead of crashes or hidden execution

### 3. Preview and Confirm Execution Validation

- **Action**: Exercise preview and confirm flows for one exact-item recovery and one guidance-only recovery.
- **Expected Outcome**:
  - mutating recovery cannot execute without a prior preview
  - confirm requires `ActionPayload.idempotency_key`
  - stale or mismatched preview tokens fail closed
  - preview and confirm both create durable timeline and audit evidence

### 4. Exact-Item Scope Validation

- **Action**: Preview and confirm recovery from an `ActionItem`-scoped incident detail payload.
- **Expected Outcome**:
  - object-level mutation uses exact refs from `ActionItem` or explicit bounded selectors
  - incident prose, labels, or titles are not used as mutation selectors
  - bulk or queue-wide replay controls are not exposed as normalized built-ins

### 5. Operator UI Validation

- **Action**: Review the generated UI template flow for recovery actions.
- **Expected Outcome**:
  - the UI offers Preview or Guidance states instead of one-click Execute
  - warnings, scope, and stale-preview handling are visible before confirm
  - chronology and triage remain primary, with recovery as a bounded follow-up layer

## Automated Validation Suite

- `mix test test/parapet/runbook_test.exs`
- `mix test test/parapet/capabilities_test.exs test/parapet/operator_test.exs`
- `mix test test/parapet/operator/workbench_contract_test.exs`
- `mix test test/mix/tasks/parapet.gen.runbooks_test.exs`
- `mix compile --warnings-as-errors`

