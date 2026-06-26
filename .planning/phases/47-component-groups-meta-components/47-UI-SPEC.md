---
phase: 47
slug: component-groups-meta-components
status: draft
shadcn_initialized: false
preset: none
created: 2026-06-26
---

# Phase 47 — UI Design Contract: Component Groups / Meta-Components

> Visual, interaction, responsive, keyboard, and motion contracts for the composed
> meta-components of the generated Operator UI: `response_cockpit`, `incident_summary`,
> `runbook_card`, `preview_panel`, `action_rail`, `action_item_list` / `action_item_card`.
>
> **This contract is ADDITIVE on top of the approved Phase 46 and Phase 45 primitive
> contracts.** All token values (palette, type, spacing, radius, motion, focus ring) are
> inherited verbatim from `46-UI-SPEC.md`, `45-UI-SPEC.md`, and
> `brandbook/tokens/tokens.css`. Do NOT re-litigate any primitive- or shell-level decision.
> This spec covers only the ADDITIVE composition, behavior, and interaction contracts for
> Phase 47 in-scope requirements: GROUP-01..06, A11Y-05, MOTION-03.
>
> All 18 implementation decisions (D-01..D-18) are LOCKED from `47-CONTEXT.md`.
> None are re-opened here. References below are authoritative citations, not re-derivations.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (EEx templates + inline CSS custom properties) |
| Preset | not applicable |
| Component library | Phoenix HEEx function components (host-owned, generated) |
| Icon library | Inline SVG, `currentColor`, always with visible text label |
| Font | IBM Plex Sans 400/500 + IBM Plex Mono 400 (self-hosted woff2, vendored Phase 44) |

**Theme mechanism:** `data-parapet-theme` attribute (`"light"` / `"dark"` / `"system"`).
Unchanged. This phase adds NO new CSS variables and NO new variable values — it adds
only new CSS selector rules (`@keyframes`, `.po-preview-reveal`, `[aria-disabled="true"]`)
and modifies markup strings (labels, classes, ARIA attributes).

---

## Spacing Scale

Inherited verbatim from Phase 45 + Phase 46. No new spacing values.
Source: `brandbook/tokens/tokens.css` §9.2 (locked).

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| `--space-1` | 4px | Icon-to-label gap inside risk + audit chips |
| `--space-2` | 8px | Chip inner padding (`px-2 py-1`) in action_item_card |
| `--space-3` | 12px | Chip compact padding (`px-1.5 py-0.5`) for risk/audit-outcome chips |
| `--space-4` | 16px | `preview_panel` outer container padding (`p-4`) — unchanged |
| `--space-5` | 24px | Cockpit section `gap-6` (24px) between grid cells — unchanged |
| `--space-6` | 32px | Page-level `gap-6` — unchanged |
| `--space-7` | 48px | Not directly used in new additions |
| `--space-8` | 64px | Not directly used in new additions |

**Exceptions for this phase:**
- `scroll-pb-72` (288px) is added to the `operator_detail_live` `<main>` container as a
  WCAG 2.4.11 technique C43 scroll-padding-bottom value. This is a layout-mechanics value,
  not a spacing token application. It is cleared at `md:` breakpoint with `md:scroll-pb-0`.
  Start at 288px; tune to `scroll-pb-80` (320px) during gallery walkthrough if the tallest
  fixture sheet overflows. (D-02 — Claude's Discretion.)
- No other spacing exceptions.

---

## Typography

Inherited verbatim from Phase 45. No new font sizes or weights are introduced.
Source: `brandbook/tokens/tokens.css` §8.3 (locked).

> **This phase adds NO new type roles.** All label text in the new risk chips, audit-outcome
> chips, and renamed `incident_summary` section headings uses roles already declared in
> 45-UI-SPEC. The executor must NOT add new font-size values outside the locked set.

| Role | Token | Size | Weight | Line Height | Usage in this phase |
|------|-------|------|--------|-------------|---------------------|
| Caption / label | `--fs-caption` | 12px | 500 | 1.40 | Risk chip text, audit-outcome chip text (`text-xs font-semibold`) |
| Body small | `--fs-body-sm` | 14px | 400 | 1.50 | `incident_summary` section label text, action_item body copy |
| Body | `--fs-body` | 16px | 400 | 1.60 | General card body in `response_cockpit` and `runbook_card` |
| Section heading | `text-xl`/`text-2xl` (existing) | 18–20px | 500 | 1.25 | `incident_summary` renamed section headings (`h4`) |

**Cockpit `<h2>` impact title:** `text-3xl font-semibold` (30px, weight 600, existing).
Phase 47 adds `break-words` — size and weight unchanged. (D-06.)

**Weights in use: 400 regular + 500 medium.** Weight 600 appears only on the cockpit `<h2>`
as a locked brand-token passthrough (unchanged from existing markup). Chip labels use
`font-semibold` (600) as part of the existing `po-chip` class contract — this is also a
passthrough, not a new declaration.

---

## Color Contract

Inherited verbatim from Phases 44/45/46. This section lists ONLY the additive usages
specific to Phase 47 meta-components. No new hex values are introduced.

Source: `brandbook/tokens/tokens.css` (locked) + `45-UI-SPEC.md` Status Triplets table.

### Risk Chip Colors (D-07 — GROUP-04)

Risk is communicated via **color + icon + label** (never color alone — WCAG 1.4.1).
All risk chip colors derive from the existing `po-chip-*` status triplets wired in Phase 44.

| Risk Tier | Derived from `ActionItem.kind` | CSS Class | Semantic color |
|-----------|-------------------------------|-----------|----------------|
| High risk | `"dead_letter"` | `po-chip po-chip-danger` | incident-red triplet (#9F2D2D on #FCE8E2) |
| Medium risk | `"orphaned_callback"`, `"stalled_workflow"` | `po-chip po-chip-warning` | beacon-amber triplet (#92400E on #F8EFD7) |
| Low risk | `"suppressed_delivery"` | `po-chip po-chip-info` | trace-violet triplet (#4F46A5 on #ECEBFF) |
| Routine | `"exact_follow_up"` + fallback | `po-chip` (neutral) | unknown triplet (#2E3A42 on #ECEFF1) |

**Icon glyphs (Claude's Discretion — D-07):**
- High risk (`:danger`): `exclamation-triangle` heroicon, `h-3.5 w-3.5 aria-hidden="true"`
- Medium risk (`:warning`): `exclamation-circle` heroicon, `h-3.5 w-3.5 aria-hidden="true"`
- Low risk (`:info`): `information-circle` heroicon, `h-3.5 w-3.5 aria-hidden="true"`
- Routine (`:neutral`): no icon (label alone is sufficient for routine items)

### Audit-Outcome Chip Colors (D-08 — GROUP-04)

| State | Chip | CSS Class |
|-------|------|-----------|
| `"resolved"` | "Resolved · audited" | `chip_class(:execution, :executed)` → `po-chip po-chip-success` |
| `"open"` (and any other) | "Pending" | `po-chip` (neutral base only) |

**No "failed" state.** `ActionItem` has no failure field. Do not fabricate one. (D-08.)

### `[aria-disabled="true"]` Visual (D-09 — GROUP-04)

For shown-but-unavailable controls: `opacity: 0.5; cursor: not-allowed; pointer-events: none`.
Uses the same visual as `control_base()`'s `disabled:opacity-50 disabled:cursor-not-allowed`.
Applied via the new CSS selector rule — no markup color change.

### 60/30/10 Distribution (unchanged)

- 60% dominant: `var(--parapet-bg)` + `var(--parapet-panel)` page and card surfaces
- 30% secondary: `var(--parapet-panel-muted)` inset surfaces, borders, muted text
- 10% accent: `var(--parapet-accent)` reserved list from Phase 45 unchanged; Phase 47 does
  not add accent to any new element.

---

## Component Composition Contracts

### GROUP-01 — `response_cockpit` Responsive Composition (D-05, D-06)

**Layout:** CSS-grid single-column-by-default. `lg:grid-cols-[...]` two-column layout
above 1024px. No `order-*` classes. No JS. No breakpoint hack.

**Source order at 390px (must not change):**
1. Impact title (`<h2>`) + cockpit header row
2. Impact/severity summary
3. Evidence / fault-plane data
4. Journey counts / stat metrics

**`<h2>` impact title overflow hardening:** Add `break-words` to the existing
`text-3xl font-semibold text-stone-950 text-balance` class string. This matches
`incident_summary`'s existing `whitespace-normal break-words` protection.

**Nothing else changes in `response_cockpit/1` markup structure.**

**Breakpoint behavior:**

| Viewport | Layout |
|----------|--------|
| < 1024px (mobile to tablet) | Single column, source order, `gap-6` between cells |
| ≥ 1024px (`lg:`) | Two-column track layout |

### GROUP-02 — `incident_summary` Brand Voice (D-10, D-11)

**Scope:** Re-author ONLY the body of `incident_summary/1` (≈lines 810–928 of
`operator_components.ex.eex`). Zero data-shape change. All `@detail.*` and
`@detail.derived.*` field accesses remain identical.

**Section label renames (verbatim — D-11):**

| Old label | New label | Sentence case rule |
|-----------|-----------|-------------------|
| "Impact Summary" | "What users are seeing" | Sentence case |
| "Top Facts" | "Evidence on record" | Sentence case |
| "Observability" | "Where to inspect" | Sentence case |
| "Next Step" (heading) | "Safe next step" | Sentence case |
| "Escalation Status" | "Escalation status" | Sentence case |

**Fallback string rewrites (verbatim — D-11):**

| Old fallback | New fallback |
|---|---|
| "No impact summary recorded." | "No user-facing impact has been recorded yet." |
| "No external links attached." | "No trace or external links are attached to this incident yet." |

**Reading order (top-to-bottom MUST trace formula):**
symptom ("What users are seeing") → evidence ("Evidence on record") →
correlation (contained within evidence card) → safe next action ("Safe next step") →
where to inspect ("Where to inspect")

If the current card render order places the escalation/safe-next-action card AFTER
the top-facts/where-to-inspect grid, reorder so evidence appears before safe next action.
Card reordering within `incident_summary/1` is within D-10 scope.

**Voice register (operator-facing, never customer-apology):**
- Blameless, neutral, calm. Not panicked, salesy, cute, or macho.
- Addresses the engineer recovering the system.
- No "oops", "something went wrong", or blame language.
- Phase 47 edits ONLY `incident_summary/1`. All other copy (`runbook_card`, `preview_panel`,
  `_copy/1` helpers) belongs to Phase 48 (D-12). Do NOT touch them.

### GROUP-03 — Runbook Card and Preview Panel Clipping (D-01, D-04)

**N/A-by-design.** There is no scrim. `preview_panel` is an ARIA Disclosure, not a Dialog.
`runbook_card` is an inline `<div>`. No focus-trap, no `aria-modal`, no full-screen backdrop
shall be added. (D-01.)

**Positive-negative guards (verified in test, not implemented):**
- `refute content =~ "role=\"dialog\""` — no dialog
- `refute content =~ "aria-modal"` — no modal
- `refute content =~ ~S|class="fixed inset-0|` — no full-screen scrim
- `assert content =~ "md:relative md:inset-auto"` — Disclosure shape confirmed

**Audit matrix:** Mark GROUP-03 cells as `n/a` with ARIA APG Disclosure vs Dialog rationale,
citing WCAG 2.4.3 (focus order) + 2.4.7 (focus visible) + 2.4.11 (satisfied by D-02). (D-04.)

### GROUP-04 — Action Rail / Action-Item Cards (D-07, D-08, D-09)

**Risk communication (D-07):** Every `action_item_card/1` shows a risk chip derived by
the `action_item_risk/1` private helper. Risk is conveyed by color + icon + label (never
color alone — WCAG 1.4.1).

```
defp action_item_risk("dead_letter")         → :danger   ("High risk")
defp action_item_risk("orphaned_callback")   → :warning  ("Medium risk")
defp action_item_risk("stalled_workflow")    → :warning  ("Medium risk")
defp action_item_risk("suppressed_delivery") → :info     ("Low risk")
defp action_item_risk("exact_follow_up")     → :neutral  ("Routine")
defp action_item_risk(_)                     → :neutral  ("Routine")
```

**Chip layout inside `action_item_card/1`:** risk chip + audit-outcome chip rendered on
the same row using `flex items-center gap-2`. Chips use `rounded px-1.5 py-0.5 text-xs
font-semibold uppercase tracking-wide flex items-center gap-1`.

**Audit-outcome communication (D-08):**

| `item.state` | Chip text | CSS |
|---|---|---|
| `"resolved"` | "Resolved · audited" | `chip_class(:execution, :executed)` = `po-chip po-chip-success` |
| `"open"` (or any) | "Pending" | `po-chip` (neutral) |

**Shown-but-unavailable controls (D-09):** Use `aria-disabled="true"` (not native `disabled`)
so keyboard/AT users can discover the control and hear a reason. The CSS selector rule
`.parapet-ui [aria-disabled="true"]` gives the same `opacity-50 cursor-not-allowed
pointer-events-none` visual as `control_base()`'s disabled utilities. This is an additive
CSS rule — it does not conflict with existing `disabled:opacity-50` in `control_base()`.

**Hide-with-explanation pattern:** Gated escalation controls (truly hidden) keep the
existing hide-with-explanation pattern. D-09 only applies to controls that are shown but
currently unavailable.

### GROUP-05 — Overlay Focus Management (D-01)

**N/A-by-design.** Zero overlays/modals/drawers exist in the codebase. No focus-trap,
no Esc handler, no scrim click handler shall be added. (D-01.)
Verified by `refute content =~ "aria-modal"` guard.

### GROUP-06 — Overlay Stacking Order (D-01)

**N/A-by-design.** Zero overlay elements. `preview_panel` uses `z-50` but has no scrim
element above it. No stacking corrections needed. (D-01.)

---

## `preview_panel` Disclosure Contract (A11Y-05 + D-01..D-04)

**Pattern:** ARIA Disclosure (not Dialog). Non-modal inline disclosure.

| Property | Value | Source |
|----------|-------|--------|
| ARIA role on panel root | `role="region"` | D-03 |
| ARIA label | `aria-label="Recovery Preview"` | D-03 |
| Mobile position | `fixed inset-x-0 bottom-0 z-50 p-4` | Existing, unchanged |
| Desktop position | `md:relative md:inset-auto md:p-0 md:mb-6` | Existing, unchanged |
| Close button | `phx-click="cancel_preview"` + `aria-label="Close Recovery Preview"` + 40×40 hit target + `po-focus` ring | Existing, unchanged |
| Focus-trap | None — Disclosure pattern; focus is NOT trapped | D-01 |
| Scrim | None | D-01 |
| `aria-modal` | Not added | D-01 |

**Outer container class string (after Phase 47):**
```
"po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6"
```

**Inner content wrapper (after Phase 47):**
```
role="region" aria-label="Recovery Preview"
class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden"
```

**WCAG 2.4.11 Focus Not Obscured (D-02):** Add `scroll-pb-72 md:scroll-pb-0` to the
`operator_detail_live` `<main id="parapet-main" tabindex="-1">` container. This is
WCAG technique C43 (CSS scroll-padding-bottom). CSS-only, no JS. Cleared at `md:`.

---

## Motion Contract (MOTION-03)

### Preview Panel Reveal — `@keyframes po-preview-reveal`

**Method:** Pure CSS keyframe. Compositor-only properties (opacity + transform). Auto-fires
the instant `preview_panel` is DOM-inserted by LiveView's conditional diff. No JS. No class
toggle. No `JS.transition`. No `@starting-style` + `allow-discrete`. (D-13, D-14.)

**CSS to add to `operator_theme_bootstrap/1` `<style>` block:**

```css
@keyframes po-preview-reveal {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.parapet-ui .po-preview-reveal {
  animation: po-preview-reveal var(--motion-base) var(--motion-ease) both;
}
```

**No dark-mode override needed.** The keyframe uses only `opacity` and `transform` —
neither is color-dependent. (D-14.)

**Interruptibility:** One-shot 200ms opacity/transform reveal never gates pointer events
or `phx-click` handlers. Confirm/Cancel buttons in `preview_panel` remain live
throughout the animation. (D-14.)

**Reduced-motion:** Already handled. The existing `prefers-reduced-motion` block
(≈lines 466–478 of `operator_components.ex.eex`) sets `animation-duration: 0.01ms
!important` for all `.parapet-ui *` — this neutralizes the reveal automatically.
No new `@media (prefers-reduced-motion)` rule is needed. Add a comment inline
documenting this (following the DATA-06 comment pattern). (D-14.)

### Inherited Motion Contracts (unchanged)

All Phase 44/45/46 motion contracts remain in force:

| Interaction | Duration | Easing |
|-------------|----------|--------|
| Button press scale | `var(--motion-fast)` 120ms | `var(--motion-ease)` |
| Color transitions (hover) | `var(--motion-fast)` 120ms | `var(--motion-ease)` |
| Skeleton pulse | `var(--motion-base)` 200ms | linear |
| **Preview panel reveal** | `var(--motion-base)` 200ms | `var(--motion-ease)` — **NEW Phase 47** |

**Prohibitions (unchanged):**
- No `transition-all` anywhere.
- No animation on non-loading, non-reveal elements.
- No `phx-mounted={JS.transition(...)}` on `preview_panel`.

---

## Keyboard Contract

### Focus ring

Inherited from Phase 45. All interactive elements carry `po-focus focus:outline-none
focus:ring-2 focus:ring-offset-2`. Phase 47 adds no new interactive surfaces beyond the
action_item chip row (chips are non-interactive display elements — no focus ring needed).

**Close button on `preview_panel`:** Already carries `focus:ring-2 focus:ring-offset-2
po-focus aria-label="Close Recovery Preview"`. Unchanged.

### `aria-disabled` keyboard behavior (D-09)

Shown-but-unavailable controls use `aria-disabled="true"` (NOT native `disabled`).
This keeps the control in the tab order so keyboard/AT users can discover it.
`pointer-events: none` in the CSS rule prevents activation.

Native `disabled` is NOT used for shown-but-unavailable controls in Phase 47 scope.
(Native `disabled` is still correct for genuinely-always-disabled controls wired
into `control_base()` — that is the COMP-02 / Phase 45 contract, unchanged.)

### Tab order on detail page (unchanged)

Source order: skip-link → nav → theme switcher → back-link → cockpit → action rail →
preview panel close button (when panel is open).

`preview_panel` is inline in DOM (not a portal), so its close button enters the tab
order at its natural source position. No focus management script needed — Disclosure
pattern, not Dialog pattern.

### Optional Esc-to-cancel (Claude's Discretion — D-02 open question)

`phx-window-keydown="cancel_preview" phx-key="escape"` on `operator_detail_live` adds
keyboard dismiss parity. This is NOT a WCAG conformance requirement — the close button
already satisfies SC 2.4.7. If Wave 47-03 shell edits are added, fold Esc handler in.
If Wave 47-03 is skipped, omit it.

---

## Responsive Layout Contract

### `response_cockpit` at 390px (D-05)

| Property | Contract |
|----------|---------|
| Grid | Single column, source order |
| `<h2>` impact title | `break-words` prevents blow-out on long unbroken strings |
| Gap | `gap-6` (24px) between stacked cells |
| `order-*` | NOT used |
| JS | NOT used |

At 390px, `px-4` on `<main>` gives 358px content width. The cockpit `<h2>` at `text-3xl`
with `break-words` wraps long titles correctly without horizontal overflow.

### `preview_panel` at 390px

- Fixed bottom sheet: `fixed inset-x-0 bottom-0 z-50 p-4` — full-width, bottom-anchored.
- `scroll-pb-72` on `<main>` ensures focused trigger is visible above the sheet.
- No horizontal overflow: panel is full viewport-width minus `p-4` (16px) sides.
- Reveal animation: `po-preview-reveal` lifts 8px upward — same at all widths.

### `action_item_card` at 390px

Chip row uses `flex items-center gap-2` — wraps to two lines at narrow widths
if both risk chip + audit-outcome chip cannot fit on one line. This is correct behavior.

---

## Copywriting Contract

**Phase 47 scope is composition and behavior, not new copy creation for pages, flows,
or shared helpers.** Phase 48 (COPY-01..05) owns page-level microcopy. Phase 47 owns
ONLY the copy changes locked in CONTEXT.md D-11 and D-12.

### New copy introduced by Phase 47 (exact strings — D-11)

#### `incident_summary/1` section headings

| Element | Exact string |
|---------|-------------|
| Section 1 heading | "What users are seeing" |
| Section 2 heading | "Evidence on record" |
| Section 3 heading | "Where to inspect" |
| Section 4 heading | "Safe next step" |
| Section 5 heading | "Escalation status" |

#### `incident_summary/1` fallback strings

| Element | Exact string |
|---------|-------------|
| No impact fallback | "No user-facing impact has been recorded yet." |
| No external links fallback | "No trace or external links are attached to this incident yet." |

#### `action_item_card/1` chip labels

| Element | Exact string |
|---------|-------------|
| Resolved audit outcome | "Resolved · audited" |
| Open audit outcome | "Pending" |
| High risk label | "High risk" |
| Medium risk label | "Medium risk" |
| Low risk label | "Low risk" |
| Routine label | "Routine" |

#### ARIA labels (markup — not visible copy)

| Element | Exact string |
|---------|-------------|
| `preview_panel` region | `aria-label="Recovery Preview"` |
| `preview_panel` close button | `aria-label="Close Recovery Preview"` (already present, unchanged) |

### Copy strings NOT changed by Phase 47

All copy in `runbook_card`, `preview_panel` content, `incident_timeline` empty state,
and `_copy/1` helpers (≈lines 1494–1560) belongs to Phase 48. Do NOT change these in
Phase 47. The `_copy/1` helpers are on-voice already; do not churn them. (D-12.)

### Destructive actions in Phase 47 scope

No new destructive actions are introduced in Phase 47. Existing destructive action copy
("Confirm Recovery", "Suppress Pending Escalation") is owned by Phase 45 / Phase 48 and
must not be changed here.

### Error states

No new error states are added. The `action_item_card` shows "Pending" for all non-resolved
states — this is a neutral pending state, not an error. No "failed" state exists (D-08).

---

## CSS Rules Added to `operator_theme_bootstrap/1`

Three new CSS rules are added in Phase 47. No variable values change.

### Rule 1 — `@keyframes po-preview-reveal` + `.po-preview-reveal` (MOTION-03, D-13)

```css
/* Phase 47 MOTION-03: preview_panel reveal — compositor-only lift (opacity+transform).
   Auto-fires on LiveView DOM insert (no JS toggle needed).
   prefers-reduced-motion: zeroed by animation-duration: 0.01ms !important block above. */
@keyframes po-preview-reveal {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0);   }
}
.parapet-ui .po-preview-reveal {
  animation: po-preview-reveal var(--motion-base) var(--motion-ease) both;
}
```

### Rule 2 — `[aria-disabled="true"]` (D-09, GROUP-04)

```css
/* Phase 47 D-09: shown-but-unavailable controls — matches control_base() disabled visual */
.parapet-ui [aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

### Rule 3 — No new variable values

No `--po-*` or `--parapet-*` variable values are changed or added. All three new rules
use existing variables (`var(--motion-base)`, `var(--motion-ease)`) or CSS primitives
only.

---

## Anti-Patterns (hard prohibitions for Phase 47)

| Anti-pattern | Why prohibited |
|---|---|
| `role="dialog"` on `preview_panel` | Transforms Disclosure into Dialog; would require focus-trap + new JS; breaks milestone boundary. Negative-guard test enforces. |
| `aria-modal` on `preview_panel` | Same reason. Negative-guard test enforces. |
| `class="fixed inset-0` (full-screen scrim) | No scrim exists; would require Dialog pattern. Negative-guard test enforces. |
| `JS.transition` on `preview_panel` | Stateless `:html` component has no `JS` alias. CSS keyframe is the correct approach. |
| `@starting-style` + `allow-discrete` reveal | Not Baseline across all supported browsers. |
| `transition-all` in any new rule | Prohibited by MOTION-02 (catches opacity, layout, color together). |
| Native `disabled` on shown-but-unavailable controls | Drops from tab order; AT users cannot discover it. Use `aria-disabled="true"` instead. |
| Fabricated "failed" audit-outcome state | No failure field in `ActionItem` schema. D-08 explicitly prohibits this. |
| `ActionItem` schema migration | Out of scope — all risk/outcome derivation is component-layer only. |
| Changing `_copy/1` helpers (≈lines 1494–1560) | Phase 48 boundary (D-12). |
| Editing `runbook_card`, `preview_panel`, or `incident_timeline` copy | Phase 48 boundary (D-12). |
| Changing any `--po-*` or `--parapet-*` variable value | Locked from Phases 44/45. |
| Adding new font size or weight | Type scale locked from Phase 45. |

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none — not applicable (Elixir/Phoenix, not React) | not required |
| Third-party | none | not applicable |

No npm/shadcn registry components. All components are host-generated Phoenix HEEx.
No vetting gate needed.

---

## N/A-by-Design Requirement Resolutions

The following requirements are resolved as N/A-by-design, not as missing implementations.
All must be documented in `brandbook/notes/operator-audit-matrix.md` with rationale. (D-04.)

| Requirement | Resolution | Rationale |
|-------------|-----------|-----------|
| GROUP-03 (runbook card + preview panel above scrim, never clipped) | N/A — no scrim | ARIA APG: `preview_panel` is Disclosure, not Dialog. No scrim element exists. WCAG 2.4.3: content follows trigger in DOM order. |
| GROUP-05 (overlay focus trap + Esc + scrim click + restore) | N/A — no overlay | Zero modal/overlay/drawer elements. Disclosure pattern requires no focus-trap. |
| GROUP-06 (overlay stacking order) | N/A — no overlay | `preview_panel` uses `z-50` but no scrim exists above or below it. |
| A11Y-05 (modal/overlay focus management) | N/A — Disclosure, not Dialog | WCAG 2.4.11 gap addressed by D-02 (`scroll-pb-72`). Disclosure pattern: WCAG 2.4.3 + 2.4.7 satisfied by close button + source order. |

**Positive negative-guards verify these resolutions in `operator_ui_contrast_test.exs`:**
`refute role="dialog"`, `refute "aria-modal"`, `refute ~S|class="fixed inset-0|`,
`assert "md:relative md:inset-auto"`, `assert role="region"`, `assert aria-label="Recovery Preview"`.

---

## Implementation Constraints (Phase 47 specific)

1. **Additive-only on Phase 46 output.** Do NOT change any Phase 44/45/46 CSS variable
   values, existing class rules, `control_base()` / `control_class/2` function signatures,
   or `chip_class/2` existing clauses.

2. **Template + demo mirror byte-parity.** All changes apply simultaneously to:
   - `priv/templates/parapet.gen.ui/operator_components.ex.eex`
   - `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` (D-02 scroll-pb edit)
   - `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`
   - `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex`
   Every `.eex` edit is mirrored to its demo counterpart in the same task/commit. (D-18.)

3. **No new files.** All additions are to existing files. No new test files, no new
   template files, no new modules.

4. **No new runtime dependencies.** No JS libraries, no new Elixir runtime deps.

5. **4-wave cadence (D-15):**
   - Wave 47-01: Red test scaffold (additive assertions to `operator_ui_contrast_test.exs`, asserted RED)
   - Wave 47-02: Template + demo-mirror edits flipping RED → GREEN
   - Wave 47-03 (optional): Shell edits (`operator_detail_live` scroll-pb + optional Esc)
   - Wave 47-04 (`autonomous: false`): Full suite gate + audit-matrix flip + **blocking**
     human gallery walkthrough

6. **Human gallery walkthrough (Wave 47-04, blocking):** Verify at `/parapet/_gallery`:
   - 390px cockpit composition (source order, `<h2>` break-words, no overflow)
   - `preview_panel` disclosure: open/close, focus to close button on mobile
   - MOTION-03 reveal feel (lift from 8px, 200ms, both themes, reduced-motion mode)

---

## Pre-Population Sources

| Decision | Source |
|----------|--------|
| All token values (hex/size/radius/motion) | `brandbook/tokens/tokens.css` (locked v1.5) + `45-UI-SPEC.md` + `46-UI-SPEC.md` |
| All 18 locked decisions D-01..D-18 | `47-CONTEXT.md` |
| Verified line numbers | `47-RESEARCH.md` §Current Code State |
| `ActionItem.kind` values | `lib/parapet/spine/action_item.ex` (VERIFIED in 47-RESEARCH.md) |
| `chip_class(:execution, :executed)` return value | `operator_components.ex.eex` lines 1408–1410 |
| `control_base()` disabled pattern | `operator_components.ex.eex` line 1392 |
| Motion token values | `tokens.css` `--motion-fast: 120ms`, `--motion-base: 200ms`, `--motion-ease: cubic-bezier(.2,0,0,1)` |
| Brand voice formula | `brandbook/index.html:253` (VERIFIED in 47-RESEARCH.md) |
| GROUP-01..06, A11Y-05, MOTION-03 requirement text | `.planning/REQUIREMENTS.md` |
| N/A overlay rationale | ARIA APG Disclosure vs Dialog + WCAG 2.4.3/2.4.7/2.4.11 (from 47-CONTEXT.md D-04) |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
