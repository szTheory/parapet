---
phase: 45-primitive-components
plan: "03"
subsystem: operator-ui
status: complete
tags: [css-tokens, semantic-classes, inline-markup, brand-reskin, accessibility, preview-panel, badge-chips]
dependency_graph:
  requires: ["45-02"]
  provides: ["45-04"]
  affects: ["operator_components.ex.eex", "operator_components.ex (demo mirror)"]
tech_stack:
  added: []
  patterns:
    - "po-chip po-chip-info for suspect_changes_card icon and scope badges (replacing raw purple/violet utilities)"
    - "po-guidance for runbook_card guidance block and preview_panel info block (replacing raw indigo/blue utilities)"
    - "style=background:var(--parapet-accent) for preview_panel header (replacing bg-indigo-500)"
    - "ring-[color:var(--parapet-border)] for preview_panel outer ring (replacing ring-indigo-500)"
    - "hover:opacity-80 for preview_panel close button hover (replacing hover:text-indigo-100)"
    - "control_class(:primary) for three standalone navigation buttons (action_center, retrospective_card, action_rail)"
key_files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
decisions:
  - "Three always-active navigation anchors (Return to response, Back to history) use control_class(:primary) with no aria-disabled branch since they are unconditionally active — COMP-02 disabled branch only applies when surrounding logic conditions the link's availability"
  - "Copy retrospective <button> uses control_class(:primary) via class={[\"shrink-0\", control_class(:primary)]} — native disabled attribute is correct for buttons, not aria-disabled"
  - "COMP-05 stat/metric cards confirmed zero cursor-pointer in both files — no additions needed"
  - "scope badge (px-2 py-1 rounded-full) replaced entirely with po-chip po-chip-info since po-chip supplies the padding, border-radius, and color semantics"
metrics:
  duration_minutes: 5
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
  completed_date: "2026-06-25"
---

# Phase 45 Plan 03: Inline Markup Re-skin Summary

One-liner: Remediated all remaining off-palette inline markup in operator_components (preview_panel indigo, suspect_changes badges purple/violet, runbook_card blue-50 guidance, three standalone bg-stone-950 nav buttons) — contrast test now fully green for the operator_components corpus.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Re-skin preview_panel, suspect_changes_card, runbook_card (template + mirror) | 947a4af | 5 inline markup blocks replaced with po-guidance / po-chip po-chip-info / var(--parapet-accent) |
| 2 | Migrate three standalone primary-tier buttons to control_class(:primary), confirm COMP-05 | 927e8e1 | 3 inline bg-stone-950/duration-100 buttons replaced with control_class(:primary); cursor-pointer confirmed 0 |

## Inline Markup Blocks Re-skinned

### Task 1 — Items 7-12 from off-palette inventory (45-RESEARCH.md)

| # | Component | Location | Before | After |
|---|-----------|----------|--------|-------|
| 7 | preview_panel | outer ring | `ring-indigo-500` | `ring-[color:var(--parapet-border)]` |
| 7 | preview_panel | header div | `bg-indigo-500` | `style="background: var(--parapet-accent);"` |
| 8 | preview_panel | close button | `hover:text-indigo-100` | `hover:opacity-80` |
| 9 | preview_panel | info block `<p>` | `bg-indigo-50 px-3 py-2 text-xs text-indigo-900 ring-1 ring-indigo-100` | `po-guidance mb-3 rounded-lg px-3 py-2 text-xs ring-1` |
| 10 | suspect_changes_card | icon badge `<span>` | `bg-purple-100 text-purple-800` (+ sizing) | `po-chip po-chip-info` (+ sizing) |
| 11 | suspect_changes_card | scope badge `<span>` | `bg-violet-100 text-violet-800 ring-1 ring-violet-200/50` | `po-chip po-chip-info` |
| 12 | runbook_card | guidance block `<div>` | `bg-blue-50 border border-blue-100 text-violet-800` | `po-guidance mt-2 p-2 rounded text-xs italic` |

### Task 2 — Items 4-6 from off-palette inventory (inline nav buttons)

| # | Component | Location | Before | After |
|---|-----------|----------|--------|-------|
| 4 | action_center | "Return to response" `.link` | `bg-stone-950 ... duration-100 ... hover:bg-stone-800` | `control_class(:primary)` |
| 5 | retrospective_card | "Copy retrospective" `<button>` | `bg-stone-950 ... duration-100 ... focus:ring-teal-300` | `["shrink-0", control_class(:primary)]` |
| 6 | action_rail | "Back to history" `<a>` | `bg-stone-950 ... duration-100 ... hover:bg-stone-800` | `["mt-4", control_class(:primary)]` |

## COMP-05 Stat/Metric Card Confirmation

`grep -c 'cursor-pointer'` returned 0 in both template and demo mirror. No spurious pointer affordance exists on non-interactive stat/metric containers. No changes needed.

## Byte-Mirror Verification

All Task 1 and Task 2 edits applied identically to the demo mirror in the same commit.

```
diff <(grep -oE '\.po-[a-z-]+|po-guidance|po-chip-info' priv/templates/parapet.gen.ui/operator_components.ex.eex | sort -u) \
     <(grep -oE '\.po-[a-z-]+|po-guidance|po-chip-info' examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex | sort -u)
```
Result: empty (PASS)

## Contrast Test Final Status

```
mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs
7 tests, 0 failures
```

**All refutes green after Plan 03:**
- `refute content =~ "bg-indigo-500"` — PASS (preview_panel header now uses style=background:var(--parapet-accent))
- `refute content =~ "bg-indigo-50 ring-indigo-100"` — PASS (preview_panel info block now po-guidance)
- `refute content =~ "bg-purple-100"` — PASS (suspect_changes_card icon badge now po-chip po-chip-info)
- `refute content =~ "bg-violet-100"` — PASS (suspect_changes_card scope badge now po-chip po-chip-info)
- `refute content =~ "bg-blue-50"` — PASS (runbook_card guidance now po-guidance)
- `refute content =~ "bg-stone-950"` — PASS (all three standalone buttons now control_class(:primary))
- `refute content =~ "duration-100"` — PASS (all three buttons now use motion token via control_class(:primary))
- `refute content =~ "focus:ring-teal-300"` — PASS (retrospective_card button focus ring removed)
- `refute content =~ "cursor-pointer"` — PASS (COMP-05: zero pointer affordance on stat containers)
- All Plan 02 refutes/asserts remain green (bg-indigo-600, bg-emerald-600, bg-indigo-700, bg-violet-700, bg-slate-700, bg-teal-700, border-amber-, transition-all, #042f2e, hover:ring-teal-700)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. All off-palette items 4-12 from 45-RESEARCH.md are fully resolved in operator_components.ex.eex and its demo mirror.

## Threat Flags

No new threat surface introduced. All changes are static CSS class/style strings in HEEx markup. The `style="background: var(--parapet-accent);"` attribute is a static CSS custom-property reference with no user-data interpolation (T-45-04 accepted: no injection surface).

## Self-Check

### Files exist:
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — MODIFIED (verified)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — MODIFIED (verified)

### Commits exist:
- 947a4af: feat(45-03): re-skin preview_panel/suspect_changes_card/runbook_card inline markup (template + mirror)
- 927e8e1: feat(45-03): migrate three standalone primary-tier buttons to control_class(:primary) (template + mirror)

## Self-Check: PASSED
