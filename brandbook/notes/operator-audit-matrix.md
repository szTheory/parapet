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
| operator_nav | verified | verified | — | — | verified | verified | — | — | Phase 48: banner `<h1>`→`<p class="po-operator-title">` demotion (D-05), single-h1 per page (FLOW-02), keyboard focus-visibility human-verified (A11Y-06). Evidence: contrast `text-white">Active response workbench` refute + demo smoke `FLOW-02: each operator page renders exactly one h1` |
| theme_control | verified | verified | — | — | — | — | — | — | po-theme-option + po-focus wired Phase 44 |
| response_cockpit | verified | verified | verified | verified | — | — | — | — | Phase 48: single-h1 (Response sr-only h1, FLOW-02) + empty-during-load gate (`@socket_connected and Enum.empty?`, FLOW-03) human-verified empty-state design. Evidence: demo smoke `FLOW-03: empty state renders only on the connected render, not during disconnected load` |
| nav_item | verified | verified | — | — | verified | verified | done | done | Phase 48: 390px overflow discipline (min-w-0/break-all/break-words, D-16/D-17, FLOW-05) human-verified zero-horizontal-scroll at 390px |
| operator_overview | verified | verified | verified | verified | — | — | — | — | Phase 48: page semantics (single h1 + :page_title + landmarks, FLOW-02/A11Y-06) + standardized empty-state anatomy (FLOW-03). Evidence: lib integration `FLOW-02: ...assign :page_title via a page_title/ helper`, `A11Y-06: main id + nav landmarks...`; demo smoke `A11Y-06: connected detail mount exposes the main + nav landmarks` |
| action_center | verified | verified | verified | verified | — | — | done | done | Phase 48: Action queue `<h1>` (FLOW-02) + uniform `list_skeleton/1` + designed Actions-empty (FLOW-03). Evidence: demo smoke `FLOW-03: disconnected static render carries the uniform skeleton on all list pages` |
| incident_list | verified | verified | verified | verified | verified | verified | — | — | Phase 48: token-driven standardized empty-state anatomy migrated off bare `text-stone-*` + page_mode-aware History-empty (D-11, FLOW-03); 390px overflow (FLOW-05). Human-verified empty-state feels designed not broken |
| incident_row | verified | verified | — | — | verified | verified | done | done | Phase 48: `truncate` retained (R6, full value reachable on detail page), 390px discipline confirmed (D-16/D-17, FLOW-05) |
| incident_summary | verified | verified | done | done | verified | verified | — | — | Phase 48: additive `heading_level` prop (default h2; detail passes h1 — single-h1, FLOW-02); trace span `break-all min-w-0` (R7, FLOW-05). Phase 47: brand-voice re-author (D-10/D-11) |
| incident_timeline | verified | verified | verified | verified | verified | verified | — | — | Phase 48: empty/loading states gated on connected render (FLOW-03) + 390px overflow discipline (FLOW-05). po-timeline-badge-* for actor badges |
| suspect_changes_card | verified | verified | verified | verified | — | — | — | — | Phase 48: flag chip `break-all min-w-0` (R4, FLOW-05) + standardized empty anatomy (FLOW-03) |
| retrospective_card | verified | verified | verified | verified | — | — | — | — | Phase 48: empty-state anatomy + microcopy on-voice (COPY, FLOW-03). control_class(:primary) for Copy retrospective |
| runbook_card | verified | verified | verified | verified | verified | verified | — | — | Phase 48: D-13 microcopy — `Untitled runbook` title + `No runbook description was recorded...` body fallbacks (COPY-03); step wrapper `flex-1 min-w-0` + `break-words` (R5, FLOW-05). Evidence: lib integration `COPY-03: the 10+1 re-authored microcopy strings are pinned verbatim (D-13)` |
| preview_panel | verified | verified | done | done | verified | verified | done | done | Phase 48: D-13 microcopy line (`This preview reflects scoped changes only...`, COPY-03) + R1 height-bound bottom sheet `max-h-[100dvh]`/`overflow-y-auto overscroll-contain` + R3 `grid-cols-1 sm:grid-cols-2` (FLOW-05). Phase 47: Disclosure landmark (D-03/D-13) |
| action_rail | verified | verified | — | — | — | — | done | done | control_class(:primary); disabled via control_base() — COPY-05 action-side (risk + safe next step) pinned, kept verbatim Phase 48 |
| action_item_list | verified | verified | done | done | done | done | — | — | Phase 47: action_item_risk + audit-outcome chips; aria-disabled affordance (D-07/D-08/D-09) |
| action_item_card | verified | verified | done | done | verified | verified | done | done | Phase 48: id value `break-all font-mono` + header `min-w-0` (R2, FLOW-05). Phase 47: risk chip + audit-outcome chip (D-07/D-08) |
| incident_not_found | verified | verified | verified | verified | verified | verified | — | — | Phase 48 NEW (D-02, FLOW-03/COPY-03): designed in-page not-found panel (heading + body + back/history links + escaped `@requested_id`); absorbs both stale-link classes (unknown-UUID `NoResultsError` + malformed-id `CastError`/500) via `fetch_incident_detail/1`. Human-verified empty-state design + keyboard focus. Evidence: lib integration `COPY-03: not-found heading + body copy pinned verbatim (D-02)`; demo smoke `FLOW-03: detail with unknown UUID renders the not-found panel in-page` + `...malformed id...(not a 500)` |
| critical_journeys | verified | verified | verified | verified | — | — | — | — | Phase 48: end-to-end flow navigable (response→actions→history→detail, FLOW-01) with page titles + monotonic heading order (FLOW-02). Human-verified heading-hierarchy legibility after the h1 demotion |

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

### Phase-48 N/A-by-Design Exception: FLOW-03 `unavailable` (infra) + `permission-denied`

**Decisions:** D-03 / D-12 (Phase 48 `48-CONTEXT.md`)

FLOW-03 enumerates three not-found/no-data conditions. Phase 48 ships the **no-data** condition as
the designed in-page `incident_not_found` panel (see the matrix row above). The other two are
**N/A-by-design** for this codebase — intentional absences with grep proof, **never stubbed panes**,
reusing the Phase-47 GROUP-03/05/06 N/A convention.

**Row 1 — `unavailable` (infra failure) → N/A-by-Design.**

All Parapet operator data loads **synchronously in `mount`/`handle_params`** — there is no
`assign_async`, `Task.async`, or `start_async` anywhere in the operator templates. A DB/process
outage is therefore genuinely the **host's 5xx concern**, not an in-page "incident not found" state;
rescuing `DBConnection` errors into the not-found panel would dishonestly mask an outage as a missing
incident (D-03). No pane is rendered for this condition.

- **Grep proof:** `grep -rEn "assign_async|Task\.(async|start)|start_async"
  priv/templates/parapet.gen.ui/operator_live.ex.eex
  priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
  priv/templates/parapet.gen.ui/operator_components.ex.eex` → **zero matches** (synchronous in-node
  repo reads confirmed; infra failure is the host's 5xx, not an operator-UI state).

**Row 2 — `permission-denied` → N/A-by-Design.**

Authorization is **host-owned at the router**. Parapet ships no auth of its own; the route snippet
instructs the host to place operator routes inside an authenticated scope/pipeline
(`pipe_through [:browser, :require_authenticated_user]`, `on_mount {…UserAuth, :ensure_authenticated}`).
LiveViews are only reached **post-authorization**, so a permission-denied state inside the operator UI
would be unreachable — and the not-found panel must not imply authz (D-03). No pane is rendered.

- **Grep proof:** `grep -nE "pipe_through|require_authenticated|on_mount|auth"
  priv/templates/parapet.gen.ui/router_snippet.ex.eex` → the auth pipeline guidance
  (`# Parapet does not provide its own auth.`, `pipe_through [:browser, :require_authenticated_user]`,
  `on_mount: [{…UserAuth, :ensure_authenticated}]`) confirms host-owned authz at the router seam
  (`router_snippet.ex.eex:1-3, 8, 11, 28, 31`).

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

### GUARD-04 Off-Palette Exception: dark link-hover / accent-strong = `#A8D0DE`

**Decision:** D-07 (Phase 50, same a11y refinement direction as `#7FB4C6`)

`#A8D0DE` is used as `--po-link-hover`, `--parapet-accent-strong`, and `--parapet-accent-text` in dark mode. It is a further lightening from the brand hover token, ensuring sufficient contrast on dark operator panel surfaces (`#2E3A42`). Documented as an operator-UI-scoped a11y refinement — brand tokens remain untouched.

---

### GUARD-04 Off-Palette Exception: light link-hover / accent-strong = `#1A5066`

**Decision:** D-07 (Phase 50)

`#1A5066` is used as `--parapet-accent-strong` and `--po-link-hover` in light mode. It is a darkened derivative of Watch Blue (`#256C82`) that achieves ≥ 4.5:1 contrast on the limestone background (`#F8F4EC`) and mortar panel surfaces, satisfying WCAG AA for interactive states where the base link color would be insufficient. Operator-UI-scoped a11y refinement — brand tokens remain untouched.

---

### GUARD-04 Off-Palette Exception: dark chip-neutral border = `#556B77`

**Decision:** D-07 (Phase 50)

`#556B77` is used as `--po-chip-neutral-border` in dark mode. It is a mid-tone wall-slate derivative that provides sufficient border contrast for neutral status chips against the dark panel surface (`#2E3A42`). Operator-UI-scoped structural color — brand tokens remain untouched.

---

### GUARD-04 Off-Palette Exception: destructive-hover (dark) = `#8C2E27`

**Decision:** D-07 (Phase 50)

`#8C2E27` is used as `--po-button-destructive-hover` in light mode. It is a darkened derivative of Incident Red (`#B13A32`), used for the destructive button hover state to achieve a visible active-state contrast shift without leaving the red family. Operator-UI-scoped interaction refinement — brand tokens remain untouched.

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
