# Operator UI Audit Matrix

**Phase 44 idempotence ledger.** Each cell carries `todo` / `done` / `verified`.
Re-runs revisit only non-`verified` or regressed cells.

This matrix enumerates every operator component × visual/interaction state for the milestone v1.6 (Operator UI Brand & Design-System Audit) phases 44–50. Downstream phase executors walk this matrix to track progress and skip cells already marked `verified`.

---

## Component × State Grid

`—` = not applicable for this component.

| Component | light-default | dark-default | light-empty | dark-empty | light-overflow | dark-overflow | light-disabled | dark-disabled | Notes |
|-----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|-------|
| operator_theme_bootstrap | todo | todo | — | — | — | — | — | — | Token values + @font-face |
| operator_nav | todo | todo | — | — | todo | todo | — | — | |
| theme_control | todo | todo | — | — | — | — | — | — | |
| response_cockpit | todo | todo | todo | todo | — | — | — | — | |
| nav_item | todo | todo | — | — | todo | todo | todo | todo | |
| operator_overview | todo | todo | todo | todo | — | — | — | — | |
| action_center | todo | todo | todo | todo | — | — | todo | todo | |
| incident_list | todo | todo | todo | todo | todo | todo | — | — | |
| incident_row | todo | todo | — | — | todo | todo | todo | todo | |
| incident_summary | todo | todo | todo | todo | todo | todo | — | — | |
| incident_timeline | todo | todo | todo | todo | todo | todo | — | — | |
| suspect_changes_card | todo | todo | todo | todo | — | — | — | — | |
| retrospective_card | todo | todo | todo | todo | — | — | — | — | |
| runbook_card | todo | todo | todo | todo | todo | todo | — | — | |
| preview_panel | todo | todo | todo | todo | — | — | todo | todo | |
| action_rail | todo | todo | — | — | — | — | todo | todo | |
| action_item_list | todo | todo | todo | todo | todo | todo | — | — | |
| action_item_card | todo | todo | todo | todo | todo | todo | todo | todo | |
| critical_journeys | todo | todo | todo | todo | — | — | — | — | |

---

## Notes / Exceptions

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
