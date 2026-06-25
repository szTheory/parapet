---
phase: 45-primitive-components
plan: "04"
subsystem: operator-ui
status: checkpoint
tags: [css-tokens, secondary-templates, off-palette-gate, brand-reskin, accessibility, motion-token, audit-matrix]
dependency_graph:
  requires: ["45-03"]
  provides: ["phase-exit-gate", "45-checkpoint"]
  affects:
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - brandbook/notes/operator-audit-matrix.md
tech_stack:
  added: []
  patterns:
    - "bg-[color:var(--parapet-accent)] + po-focus for queue-refresh button (replacing bg-teal-700 stub)"
    - "hover:text-[color:var(--parapet-accent)] + hover:ring-[color:var(--parapet-border)] for pagination hover (replacing hover:ring-teal-700)"
    - "po-link for operator_detail back-link (replacing text-teal-800/hover:text-teal-950 stub)"
    - "duration-[--motion-fast] for all remaining duration-100 in secondary templates (MOTION-02 complete)"
    - "Removed redundant focus:ring-amber-300 from control_class(:warning_secondary) — po-focus in control_base() supersedes"
key_files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - brandbook/notes/operator-audit-matrix.md
decisions:
  - "bg-[color:var(--parapet-accent)] inline token expression used for queue-refresh button — operator_live.ex.eex does not call control_class/2, so inline expression preferred per 45-RESEARCH.md Open Question 3"
  - "duration-100 → duration-[--motion-fast] applied to ALL duration-100 in operator_live.ex.eex (5 occurrences), not just the three listed stubs — task-1 verify grep required zero hits and these were in scope of MOTION-02"
  - "focus:ring-amber-300 removed from control_class(:warning_secondary) — Rule 1 auto-fix, redundant with po-focus in control_base()"
  - "bg-indigo-50 at operator_components.ex.eex line 280 is a CSS interceptor SELECTOR (maps legacy Tailwind class to var(--parapet-info-bg)), not a color usage violation — documented as known gate false-positive"
  - "Audit matrix primitive-component cells marked done (light-default + dark-default) — automated-verified via 547 passing tests"
metrics:
  duration_minutes: 7
  tasks_completed: 2
  tasks_total: 3
  files_modified: 7
  completed_date: "2026-06-25"
---

# Phase 45 Plan 04: Secondary Template Stubs + Phase-Wide Off-Palette Gate Summary

One-liner: Cleared all three Phase-44 secondary-template stubs (queue-refresh button, pagination hover, back-link) with tokenized inline expressions + po-link; ran phase-wide off-palette gate dry-run (zero signal-color violations — one known CSS-interceptor false-positive documented); full suite green at 547 tests / 0 failures; primitive-component audit-matrix cells marked done.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | Re-skin operator_live + operator_detail secondary stubs (templates + mirrors) | 098d187 | 5 class replacements across 4 files; all duration-100 → duration-[--motion-fast] |
| 2 | Phase-wide off-palette gate dry-run + full suite + audit matrix update | 3bca2e2 | Removed focus:ring-amber-300 from warning_secondary; 547 tests green; matrix cells done |
| 3 | Human gallery walkthrough | PENDING | Awaiting human verification checkpoint |

## Secondary Template Stubs Re-skinned

### Task 1 — Three Phase-44 Deferred Stubs

| # | File | Location | Before | After |
|---|------|----------|--------|-------|
| 18 | operator_live.ex.eex | line 211 (queue-refresh button) | `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300 duration-100` | `bg-[color:var(--parapet-accent)] hover:bg-[color:var(--parapet-accent-strong)] po-focus duration-[--motion-fast] transition-colors` |
| 19 | operator_live.ex.eex | line 469 (pagination link helper) | `hover:ring-teal-700 hover:text-teal-700` | `hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]` |
| 20 | operator_detail_live.ex.eex | line 211 (back-link) | `text-teal-800 hover:text-teal-950` | `po-link` |

### Additional MOTION-02 Fixes (Task 1 — auto-extended per task verify criterion)

Four additional `duration-100` instances in `operator_live.ex.eex` were also on the verify grep:
- Line 158: "Return to Response" nav link  
- Lines 175, 185, 246, 256: Pagination container links (wrapping `pagination_link_class()` helper)

These were `duration-100` on neutral-stone buttons (not off-palette color violations but in scope of MOTION-02 and the task verify criterion requiring 0 `duration-100` hits).

### Task 2 — focus:ring-amber-300 Cleanup

`control_class(:warning_secondary, width)` contained `focus:ring-amber-300` which is both off-palette AND redundant with `po-focus` in `control_base()`. Removed from both template and demo mirror.

## Byte-Mirror Verification

All edits applied identically to demo mirrors in the same commit.

Verification:
```
# Task 1 — secondary templates
grep "bg-\[color:var(--parapet-accent)\]" priv/templates/.../operator_live.ex.eex
grep "bg-\[color:var(--parapet-accent)\]" examples/.../operator_live.ex
# → identical class strings on matching lines (line 211)

grep "po-link" priv/templates/.../operator_detail_live.ex.eex
grep "po-link" examples/.../operator_detail_live.ex
# → identical class strings on matching lines (line 211/212)

# Task 2 — operator_components
grep "warning_secondary" priv/templates/.../operator_components.ex.eex
grep "warning_secondary" examples/.../operator_components.ex
# → both now lack focus:ring-amber-300
```

## Phase-Wide Off-Palette Gate Dry-Run

Gate command (Task 2 verify):
```bash
grep -rnoE 'bg-indigo-[0-9]|bg-emerald-[0-9]|bg-purple-100|bg-violet-(100|700)|bg-blue-50|bg-teal-700|bg-slate-700|bg-indigo-700|border-amber-[0-9]|#042f2e|focus:ring-(teal|indigo|emerald|amber)-300' \
  priv/templates/parapet.gen.ui/ examples/demo_app/lib/demo_app_web/live/parapet/ \
  | grep -v '#7FB4C6'
```

Result: Two hits — **both are false positives** (the same interceptor CSS selector in template and mirror):
```
priv/templates/parapet.gen.ui/operator_components.ex.eex:280:bg-indigo-5
examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex:280:bg-indigo-5
```

Line 280 content:
```css
.parapet-ui .bg-indigo-50,
.parapet-ui .bg-violet-50\/50 { background-color: var(--parapet-info-bg); }
```

This is the CSS INTERCEPTOR selector — the rule that maps the `bg-indigo-50` Tailwind class to `var(--parapet-info-bg)` when inside `.parapet-ui`. This is not a usage violation; it is the remediation mechanism. The Phase-50 GUARD-04 gate should scope its grep to exclude the CSS style block (or add an explicit allowlist for this interceptor selector).

**Verdict: Phase-wide off-palette gate PASSES** — zero signal-color utility usages in HTML/Elixir markup; one known CSS-interceptor false-positive at line 280.

## Full Test Suite

```
mix test --exclude unboxed
547 tests, 0 failures (10 excluded)
```

Specific operator UI tests:
```
mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs
7 tests, 0 failures
```

## Audit Matrix Updates

All operator component rows updated from `todo` to `done` for `light-default` and `dark-default` states. These are marked `done` (automated-verified) — pending `verified` status until human gallery walkthrough checkpoint is approved.

Rows updated: operator_theme_bootstrap, operator_nav, theme_control, response_cockpit, nav_item, operator_overview, action_center, incident_list, incident_row, incident_summary, incident_timeline, suspect_changes_card, retrospective_card, runbook_card, preview_panel, action_rail, action_item_list, action_item_card, critical_journeys.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Additional duration-100 instances in operator_live.ex.eex**
- **Found during:** Task 1 (verify grep includes `duration-100`)
- **Issue:** 5 additional `duration-100` occurrences on nav/pagination buttons at lines 158, 175, 185, 246, 256 — not listed as stubs but in scope of MOTION-02 requirement and the task verify criterion
- **Fix:** Replaced with `duration-[--motion-fast]` across all 5 occurrences + demo mirror
- **Files modified:** operator_live.ex.eex, operator_live.ex (demo mirror)
- **Commit:** 098d187

**2. [Rule 1 - Bug] focus:ring-amber-300 redundant in control_class(:warning_secondary)**
- **Found during:** Task 2 off-palette gate scan
- **Issue:** `focus:ring-amber-300` in `:warning_secondary` control class is both off-palette AND redundant with `po-focus` in `control_base()` (COMP-06)
- **Fix:** Removed `focus:ring-amber-300` from `:warning_secondary` class string + demo mirror
- **Files modified:** operator_components.ex.eex, operator_components.ex (demo mirror)
- **Commit:** 3bca2e2

## Known Stubs

None. All Phase-44 secondary-template stubs (items 18–20 from 45-RESEARCH.md) are fully resolved.

## Human Checkpoint — Pending

The Task 3 human gallery walkthrough has been surfaced as a `checkpoint:human-verify`. See the checkpoint block in the executor's return message for the exact verification steps.

## Threat Flags

No new threat surface introduced. All changes are static CSS class strings in HEEx markup, with no user/incident data interpolated into class or style attributes (T-45-06, T-45-07 accepted).

## Self-Check

### Files exist:
- `priv/templates/parapet.gen.ui/operator_live.ex.eex` — MODIFIED (verified)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex` — MODIFIED (verified)
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — MODIFIED (verified)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — MODIFIED (verified)
- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — MODIFIED (verified)
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` — MODIFIED (verified)
- `brandbook/notes/operator-audit-matrix.md` — MODIFIED (verified)
- `.planning/phases/45-primitive-components/45-04-SUMMARY.md` — CREATED (this file)

### Commits exist:
- 098d187: feat(45-04): re-skin secondary template stubs — queue-refresh, pagination, back-link
- 3bca2e2: feat(45-04): phase-wide off-palette gate clean + audit matrix primitive cells done

## Self-Check: PASSED
