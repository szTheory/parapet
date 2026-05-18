# Validation for Phase 6: Fault-Domain Incident Enrichment

## Goals

Guarantee that Phase 6 enriches async and delivery incidents with durable fault-domain classification, ordered evidence, and narrow exact-item follow-up seams without turning the operator surface into a UI-only inference engine or a generic task system.

## Requirements Validated

- **TRIAGE-02**: System enriches async and delivery incidents with fault-domain context that clearly separates internal backlog, worker failure, provider degradation, webhook delay, and suppression drift.
- **TRIAGE-03**: Operator can inspect async and delivery incidents with ordered evidence and clear classification before choosing a recovery path.
- **RNBK-03**: System can create durable follow-up items only for exact operator-owned async or delivery work that requires manual action, without storing raw high-volume event streams in Ecto.

## Validation Protocol

### 1. Alert Enrichment Validation

- **Action**: Exercise `Parapet.Spine.AlertProcessor` with async and delivery alert payloads carrying bounded fault-plane labels or annotations.
- **Expected Outcome**:
  - incident title remains symptom-first and compact
  - `incident.runbook_data` stores a bounded current-state summary only
  - a typed `triage_snapshot` timeline entry is appended for initial classification
  - repeated correlated alerts do not create duplicate conflicting current-state records

### 2. Chronology Validation

- **Action**: Inspect the generated timeline entries for new or changed classifications.
- **Expected Outcome**:
  - chronology remains authoritative for sequence
  - `triage_snapshot` payloads carry bounded rationale facts instead of essays
  - current-state summary does not duplicate or replace append-only evidence history

### 3. Operator Contract Validation

- **Action**: Exercise `Parapet.Operator.WorkbenchContract` and `Parapet.Operator.incident_detail/1` with representative incident and timeline fixtures.
- **Expected Outcome**:
  - the top triage block derives from durable fields, not alert-title parsing
  - operator payloads expose likely plane, symptom, impact, why-we-think-that, and next safe step coherently
  - chronology remains available as ordered evidence for detail inspection

### 4. Exact-Item Follow-Up Validation

- **Action**: Exercise any `ActionItem` creation or lookup path introduced for Phase 6.
- **Expected Outcome**:
  - action items are created only for exact operator-owned objects
  - idempotent resolution behavior remains intact
  - no generic incident-task semantics are introduced
  - high-cardinality identifiers stay in the exact-item seam, not in metrics labels or generic incident metadata

### 5. Documentation And Contract Validation

- **Action**: Review operator docs and compile the project with warnings as errors.
- **Expected Outcome**:
  - docs still describe the operator surface as evidence-first and host-owned
  - Phase 6 additions do not imply provider-console replacement or autonomous remediation
  - compilation succeeds with no warnings

## Automated Validation Suite

- `mix test test/parapet/spine/alert_processor_test.exs`
- `mix test test/parapet/operator/workbench_contract_test.exs test/parapet/operator_test.exs`
- `mix test test/parapet/spine/action_item_test.exs test/parapet/evidence/action_item_test.exs`
- `mix compile --warnings-as-errors`
