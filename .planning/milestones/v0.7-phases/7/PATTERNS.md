# Phase 7: Host-Owned Recovery Runbooks - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 13
**Analogs found:** 13 / 13

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/runbook.ex` | boundary | runbook schema contract | `lib/parapet/runbook.ex` | exact |
| `lib/parapet/capabilities.ex` | registry | named capability lookup | `lib/parapet/capabilities.ex` | exact |
| `lib/parapet/operator.ex` | public boundary | audited preview/confirm execution | `lib/parapet/operator.ex` | exact |
| `lib/parapet/operator/action_payload.ex` | contract | audit payload validation | `lib/parapet/operator/action_payload.ex` | exact |
| `lib/parapet/operator/workbench_contract.ex` | derivation | durable-evidence to UI contract | `lib/parapet/operator/workbench_contract.ex` | exact |
| `lib/mix/tasks/parapet.gen.runbooks.ex` | generator | host-owned codegen | `lib/mix/tasks/parapet.gen.ui.ex` | strong |
| `priv/templates/parapet.gen.runbooks/*.eex` | generator templates | host-owned runbook modules | `priv/templates/parapet.gen.ui/*.eex` | strong |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | LiveView page | preview-first operator flow | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | LiveView components | runbook step rendering | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |
| `lib/parapet/spine/alert_processor.ex` | ingestion seam | runbook schema attachment | `lib/parapet/spine/alert_processor.ex` | exact |
| `test/parapet/runbook_test.exs` | contract test | schema output | `test/parapet/runbook_test.exs` | exact |
| `test/parapet/capabilities_test.exs` | registry test | capability registration | `test/parapet/capabilities_test.exs` | exact |
| `test/parapet/operator_test.exs` | boundary test | preview/confirm behavior | `test/parapet/operator_test.exs` | exact |

## Pattern Assignments

### `lib/parapet/runbook.ex`

Use the current `title/1`, `description/1`, and `step/2` macro shape. Keep schema extraction through `__runbook_schema__/0`, but enrich each step map rather than changing the top-level return shape radically.

Planner guidance:
- keep stable `module`, `title`, `description`, and `steps` keys
- add bounded new keys like `kind`, `capability`, `guidance`, `target_kind`, `requires_preview`, `preview_only`
- keep a compatibility path for existing simple `type: :mitigation` steps while making capability-backed steps the blessed path

### `lib/parapet/capabilities.ex`

Use the existing single-Agent registry pattern instead of adding a second process. The current registry already deduplicates by capability id.

Planner guidance:
- evolve the stored capability struct from `%{id, name, schema}` to a richer map that can include preview and execute callback refs plus metadata
- keep the capability lookup explicit and named
- preserve "missing capability" behavior as a normal supported state for guidance-only steps

### `lib/parapet/operator.ex`

Use the current public-boundary and transaction-first posture:
- fetch incidents through `Evidence.repo()`
- validate `ActionPayload`
- write timeline and audit data through `Evidence.run_operator_command/1` or a sibling helper

Planner guidance:
- add separate preview and confirm functions instead of overloading direct execute
- keep the older `execute_runbook_step/3` only as a compatibility wrapper or internal delegator
- preserve the existing `incident_detail/1` response shape while extending `derived`

### `lib/mix/tasks/parapet.gen.runbooks.ex`

Use the same structure as the existing Igniter tasks:
- discover host modules from the project
- copy fixed templates into host-owned paths
- provide notices or config guidance instead of hidden side effects

Closest analog:
- `lib/mix/tasks/parapet.gen.ui.ex` for template copying and host path discovery

### `priv/templates/parapet.gen.ui/operator_*`

Use the current generated UI split:
- event handlers live in `operator_detail_live.ex.eex`
- rendering helpers live in `operator_components.ex.eex`

Planner guidance:
- replace one-click execute with preview and confirm events
- render guidance-only steps differently from executable steps
- keep chronology and triage above recovery actions so the evidence-first posture survives

### `lib/parapet/spine/alert_processor.ex`

Use the existing `build_runbook_data/2` seam if Phase 7 needs incident-specific runbook attachment. It already merges runbook schema and triage summary.

Planner guidance:
- if a runbook catalog selector is added, keep it bounded to the fixed catalog and triage or action-item facts
- do not push recovery execution into alert ingestion

## Concrete Shape Guidance

### Capability registry shape

Recommended capability record fields:
- `id`
- `name`
- `target_kind`
- `preview_schema`
- `preview`
- `execute`
- `preview_only`

Keep the names locked to:
- `retry_async_item`
- `requeue_dead_letter`
- `request_manual_provider_check`

### Runbook step shape

Recommended per-step fields:
- `id`
- `label`
- `description`
- `type`
- `kind`
- `capability`
- `target_kind`
- `requires_preview`
- `preview_only`
- `guidance`

### Preview result shape

Recommended preview payload keys:
- `capability`
- `target_kind`
- `target_refs`
- `count`
- `preconditions`
- `warnings`
- `idempotency_caveats`
- `expires_at`
- `preview_token`

Keep this compact and audit-friendly. Do not persist raw provider or job streams.

## Suggested Plan Boundaries

### Plan 07-01

Runbook catalog foundation:
- `lib/parapet/runbook.ex`
- `lib/mix/tasks/parapet.gen.runbooks.ex`
- `priv/templates/parapet.gen.runbooks/*.eex`
- `test/parapet/runbook_test.exs`

### Plan 07-02

Capability registry and preview/confirm operator seam:
- `lib/parapet/capabilities.ex`
- `lib/parapet/operator.ex`
- `lib/parapet/operator/action_payload.ex`
- `test/parapet/capabilities_test.exs`
- `test/parapet/operator_test.exs`

### Plan 07-03

Operator workbench and docs closure:
- `lib/parapet/operator/workbench_contract.ex`
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`
- `priv/templates/parapet.gen.ui/operator_components.ex.eex`
- `docs/operator-ui.md`
- `test/parapet/operator/workbench_contract_test.exs`

## Anti-Patterns To Avoid

- keeping `type: :mitigation` as the only meaningful step distinction
- adding a second registry or side-channel for recovery capabilities
- using incident title or free-form text as mutation selectors
- rendering bulk or queue-wide buttons in the generated UI
- storing wide target lists in Ecto just to support preview or confirm

## PATTERN MAP COMPLETE
