---
phase: 45-primitive-components
plan: "02"
subsystem: operator-ui
status: complete
tags: [css-tokens, semantic-classes, button-variants, accessibility, brand-reskin]
dependency_graph:
  requires: ["45-01"]
  provides: ["45-03", "45-04"]
  affects: ["operator_components.ex.eex", "operator_components.ex (demo mirror)"]
tech_stack:
  added: []
  patterns:
    - ".parapet-ui scoped semantic CSS class rules (.po-button-*, .po-guidance, .po-timeline-badge-*, .po-queue-row-selected)"
    - "CSS custom property variables for button variants (--po-button-primary/recovery/destructive/success-bg/fg/hover)"
    - "Three-block CSS variable sync (light + explicit-dark + media-query-dark)"
    - "disabled affordance via native disabled attribute + Tailwind utilities (COMP-02)"
    - "CSS arbitrary value syntax border-[color:var(--token)] for tokenized borders (COMP-04)"
key_files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
decisions:
  - "dark success overrides added to BOTH dark blocks (explicit-dark + media-query-dark) to maintain three-block CSS variable sync pattern"
  - "primary/recovery button vars use CSS custom-property references (var(--parapet-text) etc.) — no dark override needed since those base vars are already overridden in dark blocks"
  - "destructive button colors (#B13A32/#8C2E27) are theme-invariant — light declaration only"
  - "warning_secondary control_class left unchanged — its ring-amber-300/text-amber-900 are text color utilities intercepted by existing .parapet-ui rule"
  - "catch-all timeline_entry_badge_class(_) returning bg-stone-600 left unchanged — intercepted neutral stone, not a COMP-08 violation"
  - "queue_row_class unselected branch (border-l-transparent bg-stone-50/40 hover:bg-stone-100) left unchanged — intercepted neutral stone utilities"
  - "remaining contrast test failure (bg-indigo-500 in preview_panel header) is Plan 03 inline markup territory per plan spec"
metrics:
  duration_minutes: 6
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
  completed_date: "2026-06-25"
---

# Phase 45 Plan 02: CSS Foundation + Function Re-skin Summary

One-liner: Added nine `.po-button-*/badge/queue-row` semantic CSS rules with `--po-button-*` variables; rewrote `control_base/0` (with disabled affordance + motion token), five `control_class/2` variants, `timeline_entry_badge_class/1`, `queue_row_class/2`, and tokenized escalation amber borders — byte-identical in template and demo mirror.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Add new CSS variables + semantic class rules + fix #042f2e | c9f3b1e | 12 new CSS vars (light + dark overrides), 9 new `.po-*` rule blocks, #042f2e -> var(--po-nav-active-fg) |
| 2 | Rewrite control_base, control_class, timeline/queue functions, tokenize escalation amber borders | fe7c5ef | control_base() updated, 5 control_class variants rewritten, 2 new variants added, timeline/queue functions replaced, 3 amber borders tokenized |

## New CSS Variables Added

### Light `.parapet-ui {}` block (appended after `--po-button-warning-hover`):
- `--po-button-primary-bg`, `--po-button-primary-fg`, `--po-button-primary-hover`
- `--po-button-recovery-bg`, `--po-button-recovery-fg`, `--po-button-recovery-hover`
- `--po-button-destructive-bg`, `--po-button-destructive-fg`, `--po-button-destructive-hover`
- `--po-button-success-bg`, `--po-button-success-fg`, `--po-button-success-hover`

### Both dark blocks (explicit dark + media-query dark, overrides only):
- `--po-button-success-bg: #3F5E28`, `--po-button-success-fg: #EFF6E8`, `--po-button-success-hover: #567236`

## New CSS Class Rules Added

Inserted after `.po-button-warning:hover`, before `.parapet-theme-option`, in both files:
- `.parapet-ui .po-button-primary` + `:hover`
- `.parapet-ui .po-button-recovery` + `:hover`
- `.parapet-ui .po-button-destructive` + `:hover`
- `.parapet-ui .po-button-success` + `:hover`
- `.parapet-ui .po-guidance`
- `.parapet-ui .po-timeline-badge-operator`
- `.parapet-ui .po-timeline-badge-copilot`
- `.parapet-ui .po-timeline-badge-external`
- `.parapet-ui .po-queue-row-selected` + `:hover`

## Functions Rewritten

| Function | Before | After |
|----------|--------|-------|
| `control_base/0` | `duration-100`, no `focus:ring-offset-2`, no `po-focus`, no `disabled:*` | `duration-[--motion-fast]`, `focus:ring-offset-2`, `po-focus`, `disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none` |
| `control_class(:primary, width)` | (did not exist) | `control_base() <> " po-button-primary"` |
| `control_class(:destructive, width)` | (did not exist) | `control_base() <> " po-button-destructive"` |
| `control_class(:recovery, width)` | `bg-indigo-600 text-white hover:bg-indigo-700 focus:ring-indigo-300` | `po-button-recovery` |
| `control_class(:success, width)` | `bg-emerald-600 text-white hover:bg-emerald-700 focus:ring-emerald-300` | `po-button-success` |
| `control_class(:warning, width)` | `po-button-warning focus:ring-amber-300` | `po-button-warning` (dropped focus:ring-amber-300; po-focus now in control_base) |
| `timeline_entry_badge_class(:operator)` | `"bg-indigo-700"` | `"po-timeline-badge-operator"` |
| `timeline_entry_badge_class(:copilot)` | `"bg-violet-700"` | `"po-timeline-badge-copilot"` |
| `timeline_entry_badge_class(:external)` | `"bg-slate-700"` | `"po-timeline-badge-external"` |
| `queue_row_class/2` selected branch | `"border-l-teal-700 bg-teal-50/80 hover:bg-teal-50"` | `"po-queue-row-selected"` |

## Escalation Amber Borders Tokenized (COMP-04)

| Location | Before | After |
|----------|--------|-------|
| Escalation status badge `<span>` (~line 742) | `border-amber-300` | `border-[color:var(--po-chip-warning-border)]` |
| Escalation chain step `<li>` (~line 754) | `border-amber-100` | `border-[color:var(--po-chip-warning-border)]` |
| Runbook step warning `<div>` (~line 1007) | `border-amber-100` | `border-[color:var(--po-chip-warning-border)]` |

## Byte-Mirror Verification

```
diff <(grep -oE '\.po-[a-z-]+' priv/templates/parapet.gen.ui/operator_components.ex.eex | sort -u) \
     <(grep -oE '\.po-[a-z-]+' examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex | sort -u)
```
Result: empty (PASS)

## Contrast Test Status

```
mix test test/parapet/operator_ui_contrast_test.exs
2 tests, 1 failure
```

**Green (Plan 02 gates now passing):**
- `refute content =~ "bg-indigo-600"` — PASS (control_class(:recovery) now po-button-recovery)
- `refute content =~ "bg-emerald-600"` — PASS (control_class(:success) now po-button-success)
- `refute content =~ "bg-indigo-700"` — PASS (timeline_entry_badge_class :operator now po-timeline-badge-operator)
- `refute content =~ "bg-violet-700"` — PASS (timeline_entry_badge_class :copilot now po-timeline-badge-copilot)
- `refute content =~ "bg-slate-700"` — PASS (timeline_entry_badge_class :external now po-timeline-badge-external)
- `refute content =~ "border-amber-"` — PASS (all three amber borders tokenized)
- `refute content =~ "transition-all"` — PASS
- `assert content =~ "duration-[--motion-fast]"` — PASS (control_base updated)
- `assert content =~ "po-focus"` — PASS (control_base now includes po-focus)
- `refute content =~ "#042f2e"` — PASS (dark theme-switcher rule now uses var(--po-nav-active-fg))
- `refute content =~ "hover:ring-teal-700"` — PASS (never present in operator_components)
- `refute content =~ "bg-teal-700"` — PASS (queue_row_class selected branch now po-queue-row-selected)
- All button contrast assertions (primary/destructive/success light+dark) — PASS

**Still red (Plan 03 inline markup territory):**
- `refute content =~ "bg-indigo-500"` — FAIL — `preview_panel` header inline class (Plan 03 fix)

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

### Created files exist:
- `.planning/phases/45-primitive-components/45-02-SUMMARY.md` — FOUND (this file)

### Commits exist:
- c9f3b1e: feat(45-02): add new .po-button-*/badge/queue CSS rules + variables; fix #042f2e
- fe7c5ef: feat(45-02): rewrite control_base/class, timeline/queue functions; tokenize escalation amber borders

## Self-Check: PASSED
