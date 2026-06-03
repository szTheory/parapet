# Phase 4: Operator UI Surfacing - Research

**Researched:** 2026-05-19
**Domain:** Escalation visibility, actor-distinct operator evidence, and bounded manual escalation controls
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Phase Boundary

Expose automated actions and pending escalations to human operators inside the generated Phoenix LiveView Incident detail surface.

This phase adds operator-facing escalation and automation visibility, distinct system-action styling, and bounded manual escalation controls. It does not add a second scheduler, a broad incident-control plane, or vendor-console breadth.

### Locked Decisions

#### Information hierarchy
- D-01 through D-04: summary-first layout, chronology directly below, and risky controls only after enough current-state context is visible.

#### Escalation surfacing
- D-05 through D-08: hybrid summary panel plus canonical timeline, with any countdown or next-step UI treated as a read-only projection of durable truth.

#### Actor distinction
- D-09 through D-12: one canonical timeline with strong but calm distinction between human, system, and AI/copilot actors without relying on color alone.

#### Manual controls
- D-13 through D-17: provide bounded manual `trigger next escalation` and temporary suppression/cancel semantics, model them separately from acknowledge/resolve, and persist them as durable command state checked by workers rather than UI-only state or direct Oban surgery.

#### Product posture
- D-18 through D-24: optimize for evidence-first operator clarity, preserve host-owned generated UI posture, and keep exact wording or component names at agent discretion as long as the durable-truth and single-chronology rules hold.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Operator UI displays the active escalation chain and time-until-next-escalation on the Incident detail page. | `## Summary`, `## File Recommendations`, `## Architecture Patterns`, `## Validation Architecture` |
| UI-01 | Operator UI highlights system-executed mitigations distinctly from human-executed ones. | `## Summary`, `## Architectural Responsibility Map`, `## Common Pitfalls` |
| UI-01 | Operator UI provides a manual `Trigger Next Escalation` panic button. | `## Summary`, `## File Recommendations`, `## Validation Architecture` |
</phase_requirements>

## Summary

The repo already has most of the right seams for this phase, but they currently stop short of escalation-aware operator surfacing. `Parapet.Operator.WorkbenchContract` already derives compact current-state fields from durable evidence, `Parapet.Operator` already owns the audited command boundary, and the generated LiveView templates already render a summary-first detail page over a single canonical chronology. That means Phase 4 should extend those seams rather than create a parallel UI-specific escalation state machine. [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: lib/parapet/operator.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex]

The missing foundation is a bounded escalation command state that workers and UI can both trust. `Parapet.Escalation.Worker` currently short-circuits only on incident state and records only `escalation_short_circuited` or `escalation_executed`. There is no durable notion of suppression, no explicit manual trigger command, and no workbench projection for "next escalation", "suppressed until", or "system already acted". The safest way to add that is to keep current-state escalation metadata in a narrow incident-owned summary map and keep operator intent plus execution chronology in typed timeline entries written through the existing audited operator seam. [VERIFIED: lib/parapet/escalation/worker.ex] [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: .planning/milestones/v0.8-phases/4/4-CONTEXT.md]

The generated UI is also close, but not yet phase-complete. It already renders a summary-first mobile detail view and a single timeline, but timeline rows still dump generic event payloads for most entry types, and actor distinction is effectively ad hoc. The templates should render typed escalation cards, visible system-actor markers, and a bounded manual-control surface that calls into `Parapet.Operator` instead of embedding direct DB behavior in LiveView. [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] [VERIFIED: test/parapet/operator_ui_integration_test.exs]

**Primary recommendation:** split execution into three plans:
1. add the durable escalation command seam and worker semantics;
2. derive an escalation-aware workbench contract from incident summary plus chronology;
3. update generated LiveView/UI and docs to surface escalation status, actor distinction, and bounded manual controls without violating the single-chronology rule. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v0.8-phases/4/4-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Escalation command persistence | API / Backend | Database / Storage | Manual trigger and suppression must be durable operator commands, not UI-only toggles. |
| Escalation execution gating | Worker | API / Backend | `Parapet.Escalation.Worker` remains the scheduler-facing truth gate and must honor suppression or manual command state. |
| Escalation summary projection | API / Backend | Frontend Server (SSR) | `WorkbenchContract` should project current escalation status from durable evidence so templates stay read-oriented. |
| Actor distinction and typed chronology rendering | Frontend Server (SSR) | API / Backend | Templates should render explicit actor classes and typed escalation rows over the existing detail payload. |
| Bounded manual controls | Frontend Server (SSR) | API / Backend | LiveView emits intents; `Parapet.Operator` owns audit, timeline, and any incident-state mutation. |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| `Parapet.Operator` | in-repo seam | Audited operator command boundary | Already owns incident mutations and should absorb escalation commands instead of LiveView or workers writing state directly. |
| `Parapet.Operator.WorkbenchContract` | in-repo seam | Deterministic detail payload derivation | Already projects current-state operator facts from durable evidence. |
| `Parapet.Escalation.Worker` | in-repo seam | Durable escalation execution | Already owns queue-time short-circuiting and execution evidence. |
| Generated LiveView templates | in-repo seam | Host-owned operator surface | Preserve generator-first posture by editing templates rather than shipping a hidden internal console. |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| `Parapet.Evidence.run_operator_command/1` | in-repo seam | Atomic incident/timeline/audit writes | Use for all risky manual controls so suppression and trigger intents are durably logged. |
| `Parapet.Spine.Incident.runbook_data` | in-repo seam | Narrow current-state storage | Use for bounded escalation summary fields like suppression expiry or latest next-step metadata, not raw job state. |
| `Parapet.Spine.TimelineEntry` | in-repo seam | Canonical chronology | Use for manual suppression, manual trigger, worker skip, and system execution evidence. |

## File Recommendations

| File | Recommendation | Why |
|------|----------------|-----|
| `lib/parapet/operator.ex` | Add bounded manual escalation APIs such as `trigger_next_escalation/2` and `suppress_pending_escalation/3`. | Manual controls must flow through the existing audited Phoenix-free boundary. |
| `lib/parapet/escalation/worker.ex` | Honor durable suppression state and emit typed chronology for suppressed, manual, and automatic escalation outcomes. | Worker execution remains the authoritative gate for scheduled escalation. |
| `lib/parapet/operator/workbench_contract.ex` | Derive `escalation_summary`, `system_action_state`, and actor/timeline presentation hints from incident state plus chronology. | Templates should render a deterministic workbench contract instead of re-deriving logic in HEEx. |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | Wire escalation-trigger and suppression events through `Parapet.Operator`, then refresh the derived detail payload. | LiveView should submit operator intent but not own mutation semantics. |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | Add escalation summary panel, typed timeline rows, system-action styling, and bounded control affordances. | This is the host-owned rendering seam for Phase 4. |
| `docs/operator-ui.md` | Update operator guidance for escalation status, system actor visibility, and manual override posture. | The docs currently describe preview-first recovery but not v0.8 escalation surfacing. |

## Architecture Patterns

### Pattern 1: Keep one canonical chronology

Use the current summary plus single timeline model already present in the workbench. Escalation state should be projected from durable evidence into a compact summary card, while every manual or automatic escalation event still lands in the canonical timeline. Do not create a parallel escalation history panel with independent semantics. [VERIFIED: lib/parapet/operator/workbench_contract.ex] [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex]

### Pattern 2: Treat suppression as a durable, expiring command state

Suppression should not mean deleting or mutating Oban jobs. The operator boundary should persist an expiring suppression command and append timeline evidence; the worker should consult that state when it wakes up and either short-circuit or continue. This preserves restart safety and keeps the worker as the final truth gate. [VERIFIED: lib/parapet/evidence.ex] [VERIFIED: lib/parapet/escalation/worker.ex] [VERIFIED: .planning/milestones/v0.8-phases/4/4-CONTEXT.md]

### Pattern 3: Use explicit actor classes, not generic payload dumps

The current timeline template special-cases one event type and otherwise prints `inspect(entry.payload)`. Phase 4 should replace that with typed rendering plus explicit actor labels for `operator_ui`, `system:automation:executor`, and future AI/copilot actors. The distinction should come from payload semantics and derived helper functions, not from free-form string parsing in the template. [VERIFIED: priv/templates/parapet.gen.ui/operator_components.ex.eex] [VERIFIED: lib/parapet/automation/executor.ex]

### Pattern 4: Put risky controls behind the existing operator seam

The current generated LiveView already uses `Parapet.Operator` for acknowledge, preview, confirm, and note flows. Escalation trigger and suppression should follow the same pattern so audit and timeline writes stay atomic and testable. [VERIFIED: priv/templates/parapet.gen.ui/operator_detail_live.ex.eex] [VERIFIED: lib/parapet/operator.ex]

## Common Pitfalls

- Storing scheduler-specific or unbounded job state in the UI layer or raw `runbook_data`.
- Deriving "system acted" by string-matching `entry.type` in templates without explicit actor semantics.
- Treating countdown UI as authoritative instead of a read-only projection of durable truth.
- Implementing suppression by direct Oban job cancellation, which loses the durable operator-intent trail.
- Splitting escalation evidence into a separate console-like history instead of the canonical incident timeline.

## Validation Architecture

Phase 4 validation needs to prove four things:
1. manual escalation commands are durably recorded and worker-visible;
2. the workbench contract can project current escalation status and system action state without inventing alternate truth;
3. generated UI renders escalation status and actor distinction from the derived payload rather than generic payload dumps;
4. all risky controls remain bounded, auditable, and separate from acknowledge or resolve semantics.

Recommended validation slices:
- `test/parapet/escalation/worker_test.exs` for suppression and short-circuit behavior
- `test/parapet/operator_test.exs` for manual trigger and suppression commands
- `test/parapet/operator/workbench_contract_test.exs` for escalation summary derivation
- `test/parapet/operator_ui_integration_test.exs` and `test/parapet/operator_ui_compile_out_test.exs` for generated UI posture

## Open Questions (RESOLVED)

1. **Where should current escalation status live?**
   - Resolution: store only a narrow current-state escalation summary on the incident and keep chronology in timeline entries. This matches the existing triage pattern and avoids a second state machine.

2. **Should manual override mean Oban job manipulation?**
   - Resolution: no. Persist operator intent durably and let `Parapet.Escalation.Worker` enforce it at execution time.

3. **Should system actions get a second narrative surface?**
   - Resolution: no. Render them distinctly inside the canonical timeline and expose only a compact current-state summary above it.

## RESEARCH COMPLETE
