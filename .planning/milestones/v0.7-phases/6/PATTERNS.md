# Phase 6: Fault-Domain Incident Enrichment - Pattern Map

**Mapped:** 2026-05-17
**Files analyzed:** 12
**Analogs found:** 10 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/spine/alert_processor.ex` | service | alert-ingestion | `lib/parapet/spine/alert_processor.ex` | exact |
| `lib/parapet/spine/incident.ex` | schema | durable summary | `lib/parapet/spine/incident.ex` | exact |
| `lib/parapet/spine/timeline_entry.ex` | schema | chronology append | `lib/parapet/spine/timeline_entry.ex` | exact |
| `lib/parapet/spine/action_item.ex` | schema | exact follow-up | `lib/parapet/spine/action_item.ex` | exact |
| `lib/parapet/evidence.ex` | boundary | transactional persistence | `lib/parapet/evidence.ex` | exact |
| `lib/parapet/operator/workbench_contract.ex` | derivation | durable-evidence to UI contract | `lib/parapet/operator/workbench_contract.ex` | exact |
| `lib/parapet/operator.ex` | public boundary | queue/detail queries | `lib/parapet/operator.ex` | exact |
| `test/parapet/spine/alert_processor_test.exs` | test | seam-level behavior | `test/parapet/spine/alert_processor_test.exs` | exact |
| `test/parapet/operator/workbench_contract_test.exs` | test | derivation behavior | `test/parapet/operator/workbench_contract_test.exs` | exact |
| `test/parapet/operator_test.exs` | test | boundary behavior | `test/parapet/operator_test.exs` | exact |
| `test/parapet/spine/action_item_test.exs` | test | schema validation | `test/parapet/spine/action_item_test.exs` | exact |
| `test/parapet/evidence/action_item_test.exs` | test | exact-item API | `test/parapet/evidence/action_item_test.exs` | exact |

## Pattern Assignments

### `lib/parapet/spine/alert_processor.ex`

Use the existing `process_batch/1 -> process_firing_alert/1 -> process_resolved_alert/1` shape. Keep alert ingestion centralized here rather than bypassing through operator or integration modules.

Relevant patterns:

- create an incident changeset first, then enrich it before insert
- use `on_conflict: :nothing` with `conflict_target: [:correlation_key]`
- differentiate new-vs-existing incident behavior after insert
- append timeline entries through typed payloads rather than free-form strings

Planner guidance:

- add a dedicated helper layer for bounded alert classification instead of growing one long `process_firing_alert/1`
- prefer one transactional write path for summary-map update plus `triage_snapshot` append
- preserve current correlation semantics and notifier behavior

### `lib/parapet/operator/workbench_contract.ex`

Use the current derivation pattern:

- sort entries by `inserted_at`
- find the latest entry by event type
- derive compact operator-facing fields from durable evidence

Planner guidance:

- extend the struct rather than replacing it
- keep derivation deterministic and bounded
- prefer looking at `incident.runbook_data` and typed entries such as `triage_snapshot` over parsing titles or descriptions

### `lib/parapet/operator.ex`

Use the existing public-boundary posture:

- fetch repo-backed incidents and timeline entries
- return a workbench-ready map from `incident_detail/1`
- keep mutating commands audited through `Evidence.run_operator_command/1`

Planner guidance:

- Phase 6 should focus on the detail payload shape, not add new broad mutation commands
- if exact action items need to be surfaced, add them as durable data in the detail response rather than turning the operator boundary into a workflow engine

### `lib/parapet/spine/action_item.ex` and `lib/parapet/evidence.ex`

Use the current narrow exact-object seam:

- schema with `title`, `integration`, `external_id`, `state`
- `create_action_item/1` for inserts
- `resolve_action_item/1` for idempotent resolution

Analog:

- `lib/parapet/integrations/scoria.ex` shows the right usage pattern: create one durable object-scoped follow-up record when there is an exact workflow item, not for every telemetry event

Planner guidance:

- if Phase 6 needs stronger linkage, prefer small additive fields like `incident_id` or bounded `kind`
- do not introduce owners, free-form notes, or generic incident task semantics

## Concrete Shape Guidance

### Summary-map pattern

Use a bounded map in `Incident.runbook_data` for current-state classification. Match the repo’s existing map-heavy approach rather than introducing a new embedded schema unless validation becomes impossible.

Recommended keys:

- `integration`
- `symptom`
- `fault_plane`
- `impact`
- `queue`
- `pipeline_stage`
- `delay_bucket`
- `failure_class`
- `next_safe_action`
- `confidence`
- `evidence_facts`

### Timeline-entry pattern

Use `TimelineEntry` payloads as typed maps with stable keys. The chronology should be explicit enough that tests can assert on event type and a few key fields without brittle prose matching.

Recommended event types:

- `triage_snapshot`
- `provider_feedback_missing`
- `queue_age_bucket_changed`
- `callback_delay_observed`
- `action_item_created`

### Test pattern

Follow the repo’s current lightweight seam-testing style:

- Dummy repos capture inserts or transactions
- tests assert on `Ecto.Changeset` applied changes
- operator tests assert payload shape, not LiveView markup

This phase should continue that style instead of trying to introduce full DB-backed integration tests.

## Suggested Plan Boundaries

### Plan 06-01

Incident enrichment foundation:

- `alert_processor.ex`
- `incident.ex`
- `timeline_entry.ex`
- `alert_processor_test.exs`

### Plan 06-02

Operator-facing classification contract:

- `workbench_contract.ex`
- `operator.ex`
- `workbench_contract_test.exs`
- `operator_test.exs`

### Plan 06-03

Exact-item follow-up and docs:

- `action_item.ex`
- `evidence.ex`
- `spine/action_item_test.exs`
- `evidence/action_item_test.exs`
- `docs/operator-ui.md`

## Anti-Patterns To Avoid

- storing raw alert payloads or exact identifiers directly in `runbook_data`
- inferring fault-plane meaning from title strings inside the UI layer
- treating `ActionItem` as a generic incident-task table
- duplicating chronology in both `runbook_data` and timeline entries
- adding recovery or replay actions that belong to Phase 7

## PATTERN MAP COMPLETE
