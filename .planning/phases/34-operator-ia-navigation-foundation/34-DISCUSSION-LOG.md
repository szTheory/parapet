# Phase 34: operator-ia-navigation-foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-03T21:50:47Z
**Phase:** 34-operator-ia-navigation-foundation
**Mode:** assumptions
**Areas analyzed:** Scope Boundary, Route Strategy, Implementation Surface, Auth And Install Ownership, Verification

## Assumptions Presented

### Scope Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 34 should stay IA/navigation only: `/parapet` active response landing, explicit `Respond / Actions / History`, preferred detail route, and compatibility route. | Likely | `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`; `.planning/phases/34-operator-ia-navigation-foundation/34-UI-SPEC.md` |

### Route Strategy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Generated guidance should mount `/parapet`, `/parapet/actions`, `/parapet/history`, `/parapet/incidents/:id`, and `/parapet/:id`; generated links should prefer `/parapet/incidents/:id`. | Confident | `priv/templates/parapet.gen.ui/router_snippet.ex.eex`; `.planning/phases/34-operator-ia-navigation-foundation/34-UI-SPEC.md` |

### Implementation Surface

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Changes should be generator/template-first, not core API-first. Use existing `Parapet.Operator.*` and `Parapet.Operator.WorkbenchContract` seams. | Likely | `lib/mix/tasks/parapet.gen.ui.ex`; `priv/templates/parapet.gen.ui/*.eex`; `lib/parapet/operator/workbench_contract.ex` |

### Auth And Install Ownership

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep auth host-owned. Router guidance remains comments/notices, and Parapet must not add its own auth layer or router module. | Confident | `priv/templates/parapet.gen.ui/router_snippet.ex.eex`; `test/parapet/operator_ui_integration_test.exs`; `.planning/PROJECT.md` |

### Verification

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 34 proof should be generator/source contract tests and route guidance assertions. Browser screenshots belong to Phase 36. | Likely | `.planning/REQUIREMENTS.md`; `test/mix/tasks/parapet.gen.ui_test.exs`; `test/parapet/operator_ui_integration_test.exs` |

## Corrections Made

No corrections - all assumptions confirmed by user choice `1` / `Yes, proceed`.
