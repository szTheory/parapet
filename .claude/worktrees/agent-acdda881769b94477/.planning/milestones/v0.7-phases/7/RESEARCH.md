# Phase 7: Host-Owned Recovery Runbooks - Research

**Researched:** 2026-05-18
**Domain:** Host-generated recovery runbooks, preview-first mitigation seams, and audited exact-item recovery for async and delivery incidents
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Phase Boundary

Generate safe, inspectable, host-owned recovery runbooks and narrow recovery seams for async and delivery incidents, on top of the Phase 6 evidence and triage model.

This phase is about operator guidance, preview-first recovery, bounded host-wired execution, and auditability. It does **not** add autonomous remediation, a generic workflow engine, a broad approval system, provider-console-style forensics, or broad bulk replay controls.

### Locked Decisions

### Runbook catalog shape
- **D-01:** Ship a small fixed catalog of generated host-owned runbook modules, not a generic composition DSL.
- **D-02:** Canonical v0.7 runbook classes are `stalled_executor`, `dead_letter`, `provider_outage`, and `callback_delay`.
- **D-03:** Private helpers and builders are allowed internally, but the blessed public surface remains concrete generated modules with stable identities and step ids.
- **D-04:** The host owns the generated modules and may edit copy, links, thresholds, and enabled host-wired capabilities.
- **D-05:** Runbook schemas must stay bounded and predictable so the Phase 6 workbench contract remains deterministic.

### Recovery action contract
- **D-06:** Bless a small named capability contract as the public recovery API, not arbitrary callback hooks as the primary surface.
- **D-07:** Parapet owns the capability vocabulary; the host owns whether a capability exists, how preview is computed, and whether execution is allowed.
- **D-08:** Recovery capabilities remain optional and host-wired. If the host does not register a capability, Parapet shows guidance only.
- **D-09:** Runbook steps should reference capability names, not raw `{module, step}` pairs, as the blessed path.
- **D-10:** Initial capability set stays intentionally tiny:
  - `retry_async_item`
  - `requeue_dead_letter`
  - `request_manual_provider_check`
- **D-11:** Keep a compatibility escape hatch for bespoke host actions, but treat it as secondary/internal rather than the public Phase 7 contract.

### Preview and execution flow
- **D-12:** Default recovery flow is `preview -> confirm in Parapet -> execute`.
- **D-13:** `preview only -> execute elsewhere` remains supported for investigate-only or externalized actions.
- **D-14:** Native approval workflow is not the default v0.7 operator path.
- **D-15:** Every executable mitigation must expose a preview contract before it can expose an execute contract.
- **D-16:** Confirm must execute against a reviewed preview token or snapshot and fail closed if the preview is stale or the target set changed.
- **D-17:** The LiveView UI should use a dedicated preview/confirm panel or modal for mutating recovery actions.

### Incident-level guidance vs exact-item recovery
- **D-18:** Runbooks remain primarily incident-level guidance. `ActionItem` remains the exact-item recovery seam.
- **D-19:** Retry, replay, resend, requeue, unsuppress, and other object-level recovery must require an exact target reference and should default to `ActionItem`-scoped execution.
- **D-20:** Incident-level executable mitigations are limited to read-only evidence collection and reversible bounded control-plane actions.
- **D-21:** Incident-level executable steps must be explicitly host-wired, preview-first, idempotency-aware, and denied when the host cannot provide a bounded selector and preflight summary.
- **D-22:** Incident labels, titles, and free-form prose are never sufficient selectors for mutation.
- **D-23:** Broad bulk replay, queue-wide retry, or provider-wide mutation stays manual or host-specific unless the host can preview exact scope and prove safety.

### Preview, audit, and evidence shape
- **D-24:** Mitigation preview must include capability, target kind, exact refs or `ActionItem` refs, count or estimated scope, preconditions, warnings, idempotency caveats, and staleness information.
- **D-25:** Execute must require `ActionPayload` audit context plus an `idempotency_key` for mutating recovery actions.
- **D-26:** Preview and execution must both be auditable. Timeline should record reviewed scope and execution result, and `ToolAudit` should capture actor, reason, capability, selector or scope, and outcome.
- **D-27:** Ecto evidence stays compact: summary in `runbook_data`, chronology in `TimelineEntry`, exact work in `ActionItem`.
- **D-28:** Do not persist broad target sets or raw provider/job streams in Ecto just to support runbook execution.
- **D-29:** Exact high-cardinality targets belong in `ActionItem.external_id`, preview payload refs, or timeline or audit payloads, never metrics labels.

### Safety and product posture
- **D-30:** Optimize for safe investigation and scoped recovery, not fewer clicks at any cost.
- **D-31:** Do not normalize automation-engine behavior, arbitrary script execution, or opaque recovery magic.
- **D-32:** Exact-item recovery is the default built-in action unit because blast radius and idempotency usually live at the object level.
- **D-33:** Incident-scoped capabilities are acceptable only when reversible or read-only, have explicit success criteria, and do not depend on inferred exact targets.

### Deferred Ideas (OUT OF SCOPE)
- Generic end-user runbook DSL or workflow engine.
- Native approval queue as a first-class Phase 7 control plane.
- Broad bulk replay, queue-wide retry, or provider-wide mutation as normalized built-ins.
- Autonomous remediation or auto-executed recovery policy.
- Persisting wide execution target sets or raw provider/job streams in Ecto.
- Provider-console-style forensic UIs.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RNBK-01 | System provides host-generated runbook templates for stalled executors, dead-letter handling, safe retry decisions, provider outage triage, and callback-delay investigation. | `## Summary`, `## File Recommendations`, `## Architecture Patterns`, `## Validation Architecture` |
| RNBK-02 | System scopes any built-in recovery action behind explicit host wiring, audit logging, and preview-first safety guidance rather than autonomous replay or mutation. | `## Summary`, `## Standard Stack`, `## Architecture Patterns`, `## Common Pitfalls`, `## Validation Architecture` |
</phase_requirements>

## Summary

Phase 7 should evolve the existing module-backed runbook seam rather than replace it. The repo already stores runbook schemas in `incident.runbook_data`, already routes operator mutations through `Parapet.Operator`, already requires audit payloads through `Parapet.Operator.ActionPayload`, and already keeps exact-object follow-up work in `Parapet.Spine.ActionItem`. The missing work is to make those seams explicit about preview-first recovery instead of direct step execution: generate a fixed host-owned runbook catalog, represent executable steps in terms of named capabilities, and interpose a preview contract before any mutating host action. [VERIFIED: lib/parapet/runbook.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/operator/action_payload.ex] [VERIFIED: lib/parapet/spine/action_item.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md]

The current code reveals three concrete migration pressures. First, `Parapet.Runbook` still models steps only as `{id, label, description, type}` and only exposes `execute_mitigation/2`, which is too narrow for Phase 7 preview metadata, capability names, or stale-preview rejection. Second, `Parapet.Operator.execute_runbook_step/3` dynamically dispatches straight into `execute_mitigation/2` and records only `mitigation_executed`, so there is no first-class preview, no preview token, and no way to fail closed on staleness. Third, the generated UI still renders a one-click `Execute` button for mitigation steps, which directly conflicts with the locked preview/confirm rule. [VERIFIED: lib/parapet/runbook.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex]

The safest Phase 7 shape is a three-layer upgrade:
1. add a fixed generated runbook catalog and richer runbook schema that can express capability-backed steps and guidance-only steps;
2. add a public recovery registry plus `preview -> confirm -> execute` operator seam that records reviewed scope and requires `idempotency_key` for mutation;
3. update the generated operator UI and docs to surface preview state, exact-item targeting, and guidance-first behavior while preserving the Phase 6 chronology-first evidence model. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/v0.7-phases/6/6-CONTEXT.md] [VERIFIED: docs/operator-ui.md]

**Primary recommendation:** implement Phase 7 with a new `mix parapet.gen.runbooks` generator for the fixed catalog, a capability registry that stores preview and execute callbacks per named capability, and an operator recovery API that replaces direct `execute_runbook_step/3` UX with preview-backed confirmation using exact `ActionItem` or bounded incident selectors. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: lib/parapet/capabilities.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Fixed generated runbook catalog | Tooling / Generator | API / Backend | Host-owned modules fit the repo's existing Igniter-based generation model and preserve inspectable source. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] |
| Runbook schema and step metadata | API / Backend | Tooling / Generator | `Parapet.Runbook` already owns the module contract, so Phase 7 should enrich that schema rather than invent a parallel format. [VERIFIED: lib/parapet/runbook.ex] |
| Capability registration and preview/execute callbacks | API / Backend | Host application | The library owns the named vocabulary, while hosts own whether a capability is wired and how preview or execution is performed. [VERIFIED: lib/parapet/capabilities.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md] |
| Preview snapshot validation and audit trail | API / Backend | Database / Storage | Preview and execution both need durable timeline and audit records, but target sets must stay compact. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/operator/action_payload.ex] |
| Preview-first recovery UI | Frontend Server (SSR) | API / Backend | The generated LiveView workbench already consumes `incident_detail/1`; it should render preview/confirm from durable operator state instead of invoking one-click mitigation buttons. [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Igniter` task pattern | in-repo usage | Host-owned generation of runbook modules and config notices | Existing Parapet generators already use `Igniter.Mix.Task`, so Phase 7 can add another generator without introducing a new tooling model. [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex] [VERIFIED: lib/mix/tasks/parapet.gen.spine.ex] |
| `Parapet.Runbook` | in-repo seam | Concrete module-backed runbook schema | The current DSL already gives stable module identity and schema extraction. Phase 7 should enrich it, not discard it. [VERIFIED: lib/parapet/runbook.ex] |
| `Parapet.Operator` + `Parapet.Evidence` | in-repo seams | Audited operator commands and timeline persistence | Existing mutations already flow through audited transactions and should remain the only blessed recovery execution seam. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: lib/parapet/evidence.ex] |
| `ActionPayload` | in-repo seam | Actor, reason, correlation, and idempotency metadata | Phase 7 explicitly requires `ActionPayload` plus `idempotency_key` for mutating recovery actions. [VERIFIED: lib/parapet/operator/action_payload.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Parapet.Capabilities` | in-repo seam | Existing mitigation registry | Evolve this into the named recovery capability registry instead of creating a second registry abstraction. [VERIFIED: lib/parapet/capabilities.ex] |
| `Parapet.Spine.ActionItem` | in-repo seam | Exact-item recovery targeting | Use for object-level preview and execution like dead-letter retry or stalled executor retry. [VERIFIED: lib/parapet/spine/action_item.ex] |
| `Parapet.Operator.WorkbenchContract` | in-repo seam | Deterministic detail payload for generated UI | Extend it for preview state and recovery affordances, but keep chronology authoritative. [VERIFIED: lib/parapet/operator/workbench_contract.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Fixed generator-backed runbook catalog | Generic runtime runbook DSL | Rejected because the context explicitly locks a small fixed catalog and stable step ids. [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md] |
| Named capability registry | Raw `{module, step}` callback dispatch | Rejected because it leaks host internals into the public contract and makes preview policy harder to enforce. [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md] |
| Preview snapshot or token checked on confirm | One-click execute from the detail page | Rejected because Phase 7 requires reviewed preview scope and stale-preview failure. [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md] |

## File Recommendations

| File | Recommendation | Why |
|------|----------------|-----|
| `lib/parapet/runbook.ex` | Extend the DSL schema so steps can carry `kind`, `capability`, `guidance`, `target_kind`, and `requires_preview` metadata. | This is the existing module contract and the right place to bless capability-backed steps. |
| `lib/mix/tasks/parapet.gen.runbooks.ex` | Add a new fixed-catalog generator that writes host-owned runbook modules for `stalled_executor`, `dead_letter`, `provider_outage`, and `callback_delay`. | Host generation is required by `RNBK-01`, and the repo already uses Igniter for host-owned codegen. |
| `priv/templates/parapet.gen.runbooks/*.eex` | Add one template per built-in catalog member plus any shared helper template. | Concrete generated modules keep identities stable and editable by the host. |
| `lib/parapet/capabilities.ex` | Replace `register_mitigation/3`-only semantics with named recovery capability registration that can expose preview and execute callbacks plus metadata. | The current registry is close, but too thin for preview-first recovery. |
| `lib/parapet/operator.ex` | Add preview and confirm APIs and keep a compatibility wrapper for the older direct execute path. | This is the public operator boundary and must own stale-preview rejection and audit flow. |
| `lib/parapet/operator/action_payload.ex` | Add Phase 7 action types and enforce `idempotency_key` for mutating recovery confirm paths. | Phase 7 requires auditable reviewed execution with idempotency. |
| `lib/parapet/operator/workbench_contract.ex` | Derive previewable runbook steps, action-item targeting hints, and recovery state for the generated UI. | The UI should consume deterministic derived state, not raw schema maps only. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Replace one-click mitigation execution with preview and confirm events. | Current generated UI violates the locked preview-first posture. |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Render guidance-only versus executable runbook steps, preview panes, warnings, and exact-item scope. | The current `Execute` button model is too coarse for Phase 7. |
| `docs/operator-ui.md` | Document the new preview-first recovery UX and exact-item recovery posture. | Phase 7 changes operator-facing semantics and must update doctrine docs. |

## Architecture Patterns

### System Architecture Diagram

```text
Phase 6 triage summary + action items
  -> runbook selection or generated runbook module attachment
  -> incident.runbook_data contains bounded runbook schema + triage summary
  -> operator detail derives recovery-ready view model
  -> user clicks Preview
  -> Parapet.Operator.preview_runbook_step(...)
     -> resolve capability by name
     -> compute bounded scope from ActionItem or explicit incident selector
     -> return preview snapshot/token, warnings, idempotency caveats
     -> append preview timeline entry + audit
  -> user clicks Confirm
  -> Parapet.Operator.confirm_runbook_step(...)
     -> validate preview token freshness
     -> require ActionPayload.idempotency_key for mutation
     -> invoke host-wired execute callback if present
     -> append execution timeline entry + audit
```

### Recommended Project Structure

```text
lib/parapet/
├── runbook.ex
├── capabilities.ex
├── operator.ex
├── operator/
│   ├── action_payload.ex
│   ├── workbench_contract.ex
│   └── recovery_preview.ex
└── mix/tasks/
    └── parapet.gen.runbooks.ex

priv/templates/
├── parapet.gen.runbooks/
│   ├── stalled_executor.ex.eex
│   ├── dead_letter.ex.eex
│   ├── provider_outage.ex.eex
│   └── callback_delay.ex.eex
└── parapet.gen.ui/
    ├── operator_detail_live.ex.eex
    └── operator_components.ex.eex
```

### Pattern 1: Use Generated Modules As the Public Runbook Identity

**What:** keep runbook identity tied to host-owned modules generated from a fixed catalog, then attach those modules into incident `runbook_data` the same way the current `AlertProcessor` already attaches module-backed runbook schemas.

**Why:** this preserves stable step ids, lets hosts edit copy or links, and matches the repo's explicit generation posture. [VERIFIED: lib/parapet/runbook.ex] [VERIFIED: lib/parapet/spine/alert_processor.ex] [VERIFIED: lib/mix/tasks/parapet.gen.ui.ex]

### Pattern 2: Separate Guidance Steps From Capability Steps

**What:** runbook steps should explicitly declare whether they are guidance-only, previewable-only, or preview-and-confirm executable.

**Why:** Phase 7 allows non-mutating incident-level investigation steps and exact-item mutation steps, but the current single `type: :mitigation` model collapses those into one bucket. [VERIFIED: lib/parapet/runbook.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md]

### Pattern 3: Preview Is a First-Class Audited Event

**What:** treat preview as its own operator action with its own timeline and audit payload, not just transient UI state.

**Why:** the context explicitly requires recording reviewed scope and execution result while keeping Ecto compact. Timeline and audit already exist as the durable evidence path. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: .planning/v0.7-phases/7/7-CONTEXT.md]

## Common Pitfalls

- Reusing the current direct `execute_mitigation/2` path as the primary contract. That skips preview and makes stale-preview rejection impossible.
- Treating incident titles or generic triage strings as mutation selectors. Exact targets must come from `ActionItem.external_id`, explicit refs, or bounded preview selectors.
- Expanding the capability surface beyond the three locked names in Phase 7.
- Persisting raw target lists in `runbook_data` instead of keeping previews compact and exact refs in preview or audit payloads.
- Turning the generated UI into a broad action center with queue-wide replay controls.

## Validation Architecture

Phase 7 validation should prove four things:
1. generated runbook modules exist and expose stable schemas for the fixed catalog;
2. preview is required before any mutating confirm path and stale previews fail closed;
3. built-in capabilities remain optional and guidance-only rendering works when hosts do not wire execution;
4. exact-item recovery stays exact-item scoped, audited, and idempotent.

Recommended validation slices:
- generator tests for `mix parapet.gen.runbooks`
- runbook DSL tests for new step metadata and schema output
- operator boundary tests for preview, confirm, stale token rejection, and audit payload shape
- capability registry tests for named registration and missing-capability fallbacks
- generated UI tests or template assertions for preview-first buttons and warning panels

## Open Questions (RESOLVED)

1. **Where should preview scope live between preview and confirm?**
   Resolved: use a bounded preview token or snapshot payload carried through the operator seam and recorded in timeline or audit payloads; do not add a dedicated broad target table.

2. **Should Phase 7 add a brand-new generator framework for runbooks?**
   Resolved: no. Follow the existing Igniter-based host-owned generation pattern with a dedicated `mix parapet.gen.runbooks` task.

## RESEARCH COMPLETE
