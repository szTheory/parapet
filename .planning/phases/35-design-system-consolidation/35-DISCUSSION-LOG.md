# Phase 35: design-system-consolidation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-03T22:22:55Z
**Phase:** 35-design-system-consolidation
**Mode:** assumptions
**Areas analyzed:** Implementation Surface, Consolidation Shape, Visual And Interaction Rules, Action Safety Copy, Verification

## Assumptions Presented

### Implementation Surface

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep the work generator/template-first inside `priv/templates/parapet.gen.ui/operator_components.ex.eex`, with only companion updates to copied demo LiveViews/components where needed. Do not add a runtime design-system package, Phoenix UI dependency, icon dependency, Tailwind config contract, or Parapet-owned router. | Confident | `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md`; `.planning/phases/34-operator-ia-navigation-foundation/34-CONTEXT.md`; `lib/mix/tasks/parapet.gen.ui.ex`; `test/parapet/operator_ui_compile_out_test.exs` |

### Consolidation Shape

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Introduce local helper families in the generated component template for repeated surfaces: overview cards, action cards, status chips, control buttons/links, queue rows, empty states, and compact timeline badges. Keep helpers private/local to the generated component module. | Likely | `priv/templates/parapet.gen.ui/operator_components.ex.eex`; `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md` |

### Visual And Interaction Rules

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat the approved UI spec as locked design tokens: stone/white/teal dominant palette, semantic amber/emerald/blue/indigo/violet/red only for named meanings, 4px spacing scale, `min-h-[40px]` controls, visible focus rings, no `transition-all`, and press scaling only on explicit buttons/action links. | Confident | `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md`; `priv/templates/parapet.gen.ui/operator_components.ex.eex`; `priv/templates/parapet.gen.ui/operator_live.ex.eex`; `test/parapet/operator_ui_integration_test.exs` |

### Action Safety Copy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Mutating action cards should keep or add adjacent pre-click audit/risk copy before controls, using the specific text from the UI spec and active-response language around impact, evidence, next safe action, audit, and recovery. | Confident | `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md`; `priv/templates/parapet.gen.ui/operator_components.ex.eex`; `.planning/phases/25-wire-confirm-through-claimservice-preview-confirm-ux/25-CONTEXT.md` |

### Verification

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Verify with source-contract and generator tests, not browser screenshots in this phase. Extend `test/parapet/operator_ui_integration_test.exs`, `test/mix/tasks/parapet.gen.ui_test.exs`, and possibly demo smoke/source checks to pin helper names/classes, copy, focus/hover/selection states, and absence of `transition-all`. Leave browser screenshot proof to Phase 36. | Likely | `.planning/phases/35-design-system-consolidation/35-UI-SPEC.md`; `.planning/phases/34-operator-ia-navigation-foundation/34-CONTEXT.md`; `test/parapet/operator_ui_integration_test.exs`; `test/mix/tasks/parapet.gen.ui_test.exs` |

## Corrections Made

No corrections - all assumptions confirmed.
