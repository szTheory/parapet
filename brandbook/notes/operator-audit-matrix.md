# Operator UI Audit Matrix

**Phase 44 idempotence ledger.** Each cell carries `todo` / `done` / `verified`.
Re-runs revisit only non-`verified` or regressed cells.

This matrix enumerates every operator component × visual/interaction state for the milestone v1.6 (Operator UI Brand & Design-System Audit) phases 44–50. Downstream phase executors walk this matrix to track progress and skip cells already marked `verified`.

---

## Component × State Grid

`—` = not applicable for this component.

| Component | light-default | dark-default | light-empty | dark-empty | light-overflow | dark-overflow | light-disabled | dark-disabled | Notes |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|-------|
| operator_theme_bootstrap | verified | verified | — | — | — | — | — | — | Token values + @font-face — Phase 44 complete; Phase 45 adds button/badge/queue vars |
| operator_nav | verified | verified | — | — | todo | todo | — | — | Primitive buttons/links tokenized Phase 45 |
| theme_control | verified | verified | — | — | — | — | — | — | po-theme-option + po-focus wired Phase 44 |
| response_cockpit | verified | verified | done | done | — | — | — | — | Phase 47: break-words overflow hardening on cockpit `<h2>` (D-06) |
| nav_item | verified | verified | — | — | todo | todo | done | done | disabled:opacity-50/cursor-not-allowed via control_base() |
| operator_overview | verified | verified | todo | todo | — | — | — | — | |
| action_center | verified | verified | todo | todo | — | — | done | done | control_class(:primary) for Return-to-response; disabled via control_base() |
| incident_list | verified | verified | todo | todo | todo | todo | — | — | |
| incident_row | verified | verified | — | — | todo | todo | done | done | po-queue-row-selected; disabled via control_base() |
| incident_summary | verified | verified | done | done | done | done | — | — | Phase 47: brand-voice re-author — formula labels + fallback copy (D-10/D-11) |
| incident_timeline | verified | verified | todo | todo | todo | todo | — | — | po-timeline-badge-* for actor badges |
| suspect_changes_card | verified | verified | todo | todo | — | — | — | — | po-chip po-chip-info for icon + scope badges |
| retrospective_card | verified | verified | todo | todo | — | — | — | — | control_class(:primary) for Copy retrospective |
| runbook_card | verified | verified | todo | todo | todo | todo | — | — | po-guidance for guidance block |
| preview_panel | verified | verified | done | done | — | — | done | done | Phase 47: CSS @keyframes reveal + ARIA Disclosure landmark role=region (D-03/D-13); style=var(--parapet-accent); po-guidance; hover:opacity-80 |
| action_rail | verified | verified | — | — | — | — | done | done | control_class(:primary); disabled via control_base() |
| action_item_list | verified | verified | done | done | done | done | — | — | Phase 47: action_item_risk + audit-outcome chips; aria-disabled affordance (D-07/D-08/D-09) |
| action_item_card | verified | verified | done | done | done | done | done | done | Phase 47: risk chip (color+icon+label, WCAG 1.4.1) + audit-outcome chip derived from state (D-07/D-08) |
| critical_journeys | verified | verified | todo | todo | — | — | — | — | |

---

## Notes / Exceptions

### Phase-47 N/A-by-Design Overlay Exception: GROUP-03, GROUP-05, GROUP-06, A11Y-05

**Decisions:** D-01 / D-04 (Phase 47 `47-CONTEXT.md`)

Requirements GROUP-03 (focus-trap), GROUP-05 (scrim/backdrop), GROUP-06 (drawer/sheet modal), and
A11Y-05 (overlay a11y — `role="dialog"`, `aria-modal`, Esc handler) are **N/A-by-design** for this
codebase. They are not `todo` (pending implementation) and are not `done` (implemented). They are
documented as intentional absences, not gaps.

**Rationale:**

A repo-wide grep for `modal|overlay|drawer|scrim|dialog|aria-modal|role="dialog"` across all
`.eex` files returns **zero matches**. There are no true modals, overlays, drawers, or scrims in
the generated Operator UI. The only layered surface is `preview_panel`, which is the **ARIA
Disclosure pattern** (not the Dialog pattern):

- On mobile: `fixed inset-x-0 bottom-0 z-50` bottom sheet with a working close button
- On desktop: `md:relative md:inset-auto` inline panel
- Has `role="region"` + `aria-label="Recovery Preview"` (Disclosure landmark, Phase 47 D-03)
- Has a close button with `aria-label="Close Recovery Preview"` and visible focus ring (WCAG 2.4.7)
- `runbook_card` is a plain inline `<div>` with no layering

**Why adding focus-trap / scrim / aria-modal is intentionally NOT done:**

1. Adding a focus-trap to a non-modal Disclosure would **trap keyboard users** in content that is
   not a dialog — a direct WCAG violation, not a compliance improvement.
2. Adding `role="dialog"` to a Disclosure misrepresents the widget role to assistive technology
   and contradicts ARIA APG guidance (Disclosure vs Dialog patterns).
3. Adding new JS (focus-trap library or `phx-hook`) would break the milestone boundary
   (`no new Parapet-owned runtime UI/JS dependency` — 44-CONTEXT.md locked).

**ARIA / WCAG citations:**

- **ARIA APG Disclosure vs Dialog:** [Disclosure pattern](https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/)
  does not use `role="dialog"`, `aria-modal`, focus-trap, or Esc. The Dialog pattern does.
  The preview_panel is a Disclosure; treating it as a Dialog is architecturally incorrect.
- **WCAG 2.4.3 Focus Order:** Content follows trigger in DOM source order — the
  `preview_panel` is positioned after its trigger in the page, satisfying focus order natively.
- **WCAG 2.4.7 Focus Visible:** Satisfied by the close button's `focus:ring-2` and the
  existing `po-focus` ring system.
- **WCAG 2.4.11 Focus Not Obscured:** Satisfied by the `scroll-pb-72 md:scroll-pb-0`
  scroll-padding fix shipped in Phase 47-02 (D-02, WCAG technique C43) — the just-activated
  trigger is never fully covered by the opened bottom sheet.

**Negative-guard tests (D-16):** `test/parapet/operator_ui_contrast_test.exs` enforces the
Disclosure shape via `refute role="dialog"`, `refute aria-modal`, `refute class="fixed inset-0"`
(full-screen scrim guard), and `assert md:relative md:inset-auto` + `assert
aria-label="Close Recovery Preview"`. These turn red if a future edit accidentally adds modal
machinery.

---

### GUARD-04 Off-Palette Exception: operator dark `--po-link` / `--link` = `#7FB4C6`

**Decision:** D-07 / D-08 (locked in `44-CONTEXT.md`)

The operator UI dark mode link color uses `#7FB4C6`, which is **not** the brand book's `#6FA8BC`.

**Rationale:**
- Brand book token `#6FA8BC` is tuned for the deep-slate background `#18232B` (7.04:1 contrast).
- Operator panels use the lighter wall-slate surface `#2E3A42`, where `#6FA8BC` drops to ~4.3:1 — below WCAG AA (4.5:1) for links on surface.
- `#7FB4C6` achieves 5.14:1 on wall-slate `#2E3A42` (panel surface) and 7.04:1 on deep-slate `#18232B` (background), satisfying AA on **both** surfaces as required by GUARD-02.
- The brand book token (`brandbook/tokens/tokens.css` + `brandbook/tokens/tokens.json`) remains **untouched** — this is an operator-UI-scoped a11y refinement, not a palette re-litigation.

**Phase-50 GUARD-04 gate instruction:**
The Phase-50 off-palette-hex gate **must admit `#7FB4C6` as an explicit operator-specific exception** in its allowed-hex list. Any off-palette scanner that rejects `#7FB4C6` without this allowance is incorrectly flagging a deliberate, documented a11y decision.

**Variables affected:**
- `--po-link` (dark mode)
- `--po-link-hover` → `#A8D0DE` (also lightened from brand `#A8D0DE`, consistent with the same a11y refinement direction)
- `--po-header-muted` (dark mode)
- `--parapet-accent` (dark mode) → `#7FB4C6`

**Contrast ratios (verified — source: `brandbook/notes/accessibility.md`):**
| Surface | Color | Background | Ratio | Verdict |
|---------|-------|------------|-------|---------|
| panel | `#7FB4C6` | wall-slate `#2E3A42` | 5.14:1 | AA ✓ |
| bg | `#7FB4C6` | deep-slate `#18232B` | 7.04:1 | AA ✓ |

---

## Column Definitions

| Column | Meaning |
|--------|---------|
| `light-default` | Component in light theme, fully populated with realistic data |
| `dark-default` | Same as light-default but in dark theme |
| `light-empty` | Component in light theme with empty/nil data (zero-state) |
| `dark-empty` | Same as light-empty but in dark theme |
| `light-overflow` | Component in light theme with unusually long strings or many items |
| `dark-overflow` | Same as light-overflow but in dark theme |
| `light-disabled` | Component in light theme in a non-interactive/resolved/completed state |
| `dark-disabled` | Same as light-disabled but in dark theme |

## Status Vocabulary

| Status | Meaning |
|--------|---------|
| `todo` | Not yet audited for this milestone |
| `done` | Implementation complete; visual check done but not formally verified |
| `verified` | Screenshot captured, contrast checked, and signed off by milestone gate |
