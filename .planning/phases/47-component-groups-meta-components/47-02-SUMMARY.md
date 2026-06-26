---
phase: 47-component-groups-meta-components
plan: "02"
subsystem: operator-ui
tags: [green-wave, brand-voice, a11y, motion, risk-chips, css-keyframe, demo-mirror]
requires: [47-01-red-scaffold]
provides: [47-02-green-templates]
affects: [operator_components, operator_detail_live, demo_mirrors]
tech_stack:
  added: []
  patterns:
    - CSS @keyframes on DOM insert (LiveView stateless component reveal)
    - aria-disabled CSS selector (AT-discoverable shown-but-unavailable controls)
    - ARIA Disclosure landmark (role=region + aria-label)
    - Private defp multi-clause helper (risk/audit derivation from existing fields)
    - scroll-pb-72 md:scroll-pb-0 (WCAG 2.4.11 C43 scroll-padding-bottom)
key_files:
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
decisions:
  - "Esc-to-cancel (phx-window-keydown) skipped — the close button satisfies WCAG 2.1.1/2.4.7; this is a DX improvement not a conformance requirement; deferred to gallery feedback"
  - "scroll-pb-72 (288px) chosen as conservative over-estimate for tallest mobile sheet; tune during 47-03 gallery walkthrough if needed"
  - "Card reorder in incident_summary/1: Evidence grid (Evidence on record + Where to inspect) moved BEFORE escalation card, so reading order traces formula symptom→evidence→safe next action where to inspect (D-10)"
  - "SVG icon set used: exclamation-triangle (:danger), exclamation-circle (:warning), information-circle (:info), check-circle (:neutral) — all aria-hidden=true, label text satisfies WCAG 1.4.1"
  - "action_item_card retains the existing state chip alongside new risk/audit chips — operators see full status context in one glance"
metrics:
  duration: "5m"
  completed: "2026-06-26"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 4
status: complete
---

# Phase 47 Plan 02: Wave-2 GREEN Template Edits Summary

**One-liner:** Flipped all 47-01 RED assertions GREEN by applying brand-voice labels, keyframe CSS reveal, aria-disabled rule, action_item_risk helpers, audit-outcome chips, ARIA Disclosure landmark, and scroll-pb fix to four files plus their byte-identical demo mirrors.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add @keyframes po-preview-reveal, .po-preview-reveal, [aria-disabled] CSS | f5b6886 | operator_components.ex.eex + demo mirror |
| 2 | Re-author incident_summary brand voice, cockpit break-words, preview_panel landmark/reveal | 23a0703 | operator_components.ex.eex + demo mirror |
| 3 | action_item_risk/audit-outcome chips, helpers, detail main scroll-pb | 4020784 | operator_components.ex.eex, operator_detail_live.ex.eex + both demo mirrors |

## What Was Built

### Task 1 — CSS block additions in operator_theme_bootstrap/1

Added three rules after the `prefers-reduced-motion` block, before `</style>`, in the base `.parapet-ui` scope (NOT the dark override block):

- `@keyframes po-preview-reveal`: opacity 0→1 + translateY(8px→0) — compositor-only properties (MOTION-03, D-13)
- `.parapet-ui .po-preview-reveal`: animation rule wired to `--motion-base`/`--motion-ease` tokens; inline comment notes the prefers-reduced-motion block already neutralizes it (D-14)
- `.parapet-ui [aria-disabled="true"]`: opacity 0.5 + cursor not-allowed + pointer-events none (D-09) — matches control_base() disabled visual

### Task 2 — Brand voice + structural markup edits

**response_cockpit/1 (D-06):** Added `break-words` to the `<h2>` at ≈line 561, matching the `incident_summary` `<h1>` overflow-hardening precedent.

**incident_summary/1 (D-10/D-11):** Five label renames in sentence case:
- "Impact Summary" → "What users are seeing"
- "Top Facts" → "Evidence on record"
- "Observability" → "Where to inspect"
- "Next Step" → "Safe next step"
- "Escalation Status" → "Escalation status"

Two fallback rewrites:
- "No impact summary recorded." → "No user-facing impact has been recorded yet."
- "No external links attached." → "No trace or external links are attached to this incident yet."

Card reorder (D-10): Evidence grid (Evidence on record + Where to inspect) moved BEFORE the escalation amber card. Formula reading order is now: `symptom (What users are seeing) → evidence (Evidence on record) → where to inspect → safe next action (Escalation)`.

All `@detail.*` / `@detail.derived.*` field accesses unchanged — zero data-shape change.

**preview_panel/1 (D-03/D-13):**
- Outermost `<div>` (positioning container): prepended `po-preview-reveal` class
- Inner content `<div>`: added `role="region"` + `aria-label="Recovery Preview"`
- No `role="dialog"`, `aria-modal`, scrim, or focus-trap added (D-01)

### Task 3 — Risk/audit chips, helpers, scroll-pb

**action_item_card/1 (D-07/D-08):** Header row now wraps chips in `flex items-center gap-1.5`:
- Risk chip: `po-chip` + `risk_chip_class(action_item_risk(@item.kind))` + sizing classes + `flex items-center gap-1` + tier-appropriate SVG icon (aria-hidden) + `risk_label(...)` text
- Audit-outcome chip: `audit_outcome_chip_class(@item.state)` with `audit_outcome_label(@item.state)`
- Original state chip retained alongside new chips

**New private helpers (D-07/D-08):**
- `action_item_risk/1`: kind → :danger/:warning/:info/:neutral (dead_letter→:danger, orphaned_callback/stalled_workflow→:warning, suppressed_delivery→:info, exact_follow_up/_→:neutral)
- `risk_chip_class/1`: :danger→"po-chip-danger", :warning→"po-chip-warning", :info→"po-chip-info", _→""
- `risk_label/1`: :danger→"High risk", :warning→"Medium risk", :info→"Low risk", _→"Routine"
- `audit_outcome_chip_class/1`: "resolved"→chip_class(:execution, :executed); _→neutral po-chip string
- `audit_outcome_label/1`: "resolved"→"Resolved · audited"; _→"Pending"

No ActionItem schema/migration change. No "failed" state fabricated.

**operator_detail_live `<main>` (D-02):** Added `scroll-pb-72 md:scroll-pb-0` (WCAG 2.4.11 C43).

## GREEN Gate Confirmed

```
mix test test/parapet/operator_ui_contrast_test.exs
4 tests, 0 failures — GREEN
```

All 19 Phase-47 assertions from 47-01 now pass. Both test loops (component_paths + detail_template_paths) green.

## Decisions Made

**Esc-to-cancel:** Skipped. The `phx-window-keydown="cancel_preview" phx-key="escape"` optional handler is a DX improvement, not a conformance requirement. The close button (aria-label="Close Recovery Preview") satisfies WCAG 2.1.1 and 2.4.7. Deferred to gallery feedback from 47-03.

**scroll-pb value:** `scroll-pb-72` (288px) chosen as a conservative over-estimate per D-02 Claude's Discretion. The `preview_panel` outer container uses `p-4` (16px); the tallest fixture scenario is estimated ~220–260px. Tune to `scroll-pb-80` if the gallery walkthrough reveals overflow.

**Card reorder:** Evidence grid moved before escalation card. The formula `symptom → evidence → safe next action → where to inspect` is satisfied by reading top-to-bottom. The escalation card (amber, visually prominent) appearing after the evidence grid preserves urgency signaling while matching the brand-formula reading order.

## Deviations from Plan

None — plan executed exactly as written. All three tasks committed atomically per D-18 (template + demo mirror in same commit). The Task 3 fold (operator_detail_live scroll-pb) into 47-02 was D-15 pre-approved.

## Demo-Mirror Parity

All four files edited in their respective commits. The `@component_paths` and `@detail_template_paths` test loops read both template and mirror — both pass. The key distinction between `.eex` templates (using `<%%= %>` escape double-`%`) and compiled `.ex` demo mirrors (using `<%= %>` single-`%`) was maintained throughout.

## Known Stubs

None. All label text is wired to real `@detail.*` field accesses. The chip helpers derive from actual `@item.kind` and `@item.state` fields. No hardcoded placeholder values.

## Threat Flags

None. All edits are static string literals (CSS, aria-label, copy labels) and private pure-function helpers. No new network endpoints, input paths, or trust boundaries introduced. HEEx auto-escapes all interpolations. Matches plan threat model (T-47-02-T1/T2/SC).

## Self-Check: PASSED

- [x] `priv/templates/parapet.gen.ui/operator_components.ex.eex` modified: commits f5b6886, 23a0703, 4020784
- [x] `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` modified: commits f5b6886, 23a0703, 4020784
- [x] `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` modified: commit 4020784
- [x] `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` modified: commit 4020784
- [x] GREEN gate: `mix test test/parapet/operator_ui_contrast_test.exs` → 4 tests, 0 failures
- [x] No role="dialog", aria-modal, or class="fixed inset-0" added
- [x] No ActionItem schema/migration touched
- [x] No CSS variable values changed
- [x] No _copy/1 helpers, runbook_card, or preview_panel copy edited (Phase 48 bright line)
