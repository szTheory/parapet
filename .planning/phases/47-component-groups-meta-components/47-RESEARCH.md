# Phase 47: Component groups / meta-components - Research

**Researched:** 2026-06-26
**Domain:** Phoenix EEx meta-component composition — brand-voice copy, responsive layout hardening, ARIA Disclosure pattern, CSS keyframe reveal, aria-disabled affordance
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Overlay / disclosure reality (GROUP-03, GROUP-05, GROUP-06, A11Y-05)**
- D-01: Treat overlay/modal/drawer/scrim + focus-trap requirements as N/A-by-design. Keep `preview_panel` a non-modal inline disclosure (ARIA Disclosure pattern). Do NOT add focus-trap, scrim, `aria-modal`, or a full-screen backdrop.
- D-02: Fix the one genuine residual a11y gap (WCAG 2.2 SC 2.4.11 Focus Not Obscured): add `scroll-padding-bottom` on the mobile page scroll container (e.g. `scroll-pb-72 md:scroll-pb-0`). WCAG technique C43, CSS-only, no JS.
- D-03: Add `role="region"` + `aria-label="Recovery Preview"` to the `preview_panel` root.
- D-04: Document overlay-absence as intentional in `brandbook/notes/operator-audit-matrix.md`. Mark GROUP-03/05/06 + A11Y-05 overlay cells as `n/a`.

**Meta-component re-skin + responsive composition (GROUP-01, GROUP-04)**
- D-05: `response_cockpit` stays a CSS-grid single-column-by-default layout; no breakpoint hack, no JS. Source order at 390px: title → impact → evidence → journeys/counts.
- D-06: Add `break-words` to the cockpit `<h2>` impact title (≈line 561) to match `incident_summary` overflow hardening.
- D-07: Convey action RISK by color + icon + label, reusing `po-chip-{success,warning,danger,info,neutral}` status triplets and `severity_color/1`. Derive risk tier via a new `defp action_item_risk(kind)` component-layer helper. No `ActionItem` schema change.
- D-08: Surface AUDIT OUTCOME using `chip_class(:execution, :executed)` success chip + a neutral "Pending" sibling, mapped from `state`: `resolved` → "Resolved · audited", `open` → "Pending". Do not fabricate a "failed" state.
- D-09: Disabled affordance: use `aria-disabled="true"` (not native `disabled`) for shown-but-unavailable controls. Add an `[aria-disabled='true']` CSS rule giving the same `opacity-50` + `cursor-not-allowed` as `control_base()`'s `:disabled`. Values/CSS-only.

**Incident-summary brand voice (GROUP-02)**
- D-10: Re-author only the body of `incident_summary/1` (≈lines 810–928) so reading top-to-bottom traces the brand formula: symptom → evidence → correlation → safe next action → where to inspect.
- D-11: Rename five section labels in sentence case: "Impact Summary" → "What users are seeing"; "Top Facts" → "Evidence on record"; "Observability" → "Where to inspect"; "Next Step" → "Safe next step"; "Escalation Status" → "Escalation status". Rewrite two fallbacks.
- D-12: 47-vs-48 bright line: Phase 47 edits only `incident_summary/1`. Phase 48 owns everything else (runbook_card/preview_panel copy, _copy/1 helpers, etc.).

**Motion — preview_panel reveal (MOTION-03)**
- D-13: Add a pure CSS `@keyframes po-preview-reveal` (opacity 0→1 + translateY(8px→0), compositor-only) applied via a `.po-preview-reveal` class on the `preview_panel` container, driven by `animation: po-preview-reveal var(--motion-base) var(--motion-ease) both;`. Keyframe auto-fires on LiveView insert; no class toggle, no JS.
- D-14: Reject `phx-mounted={JS.transition(...)}` and `@starting-style` + `allow-discrete`. The existing `prefers-reduced-motion` block (≈lines 466–478) already neutralizes it; no new reduced-motion rule needed.

**Verification / test-gate strategy**
- D-15: 4-wave cadence, no new test files: 47-01 (red scaffold) → 47-02 (template + mirror edits, green) → 47-03 (optional shell edits) → 47-04 (autonomous: false, full-suite gate + audit-matrix flip + human gallery walkthrough).
- D-16: Verify N/A overlay requirements as positive negative-guards in `@component_paths` loop: `refute role="dialog"`, `refute aria-modal`, `refute "fixed inset-0"` (no scrim), AND `assert "md:relative md:inset-auto"` + `assert aria-label="Close Recovery Preview"`.
- D-17: Verify GROUP-02/04 via literal string assertions (formula labels, audit-outcome copy, `disabled:opacity`/`aria-disabled`). Verify MOTION-03 with `assert "@keyframes po-preview-reveal"`, `assert "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"`, `refute "transition-all"`, plus reduced-motion zeroing already asserted.
- D-18: Demo-mirror parity by assertion-pairing — every `.eex` edit regenerated into its `examples/demo_app/.../*.ex` mirror in the same task. Human gallery walkthrough reserved for: 390px cockpit composition, preview-panel disclosure open/close + focus-to-close on mobile, and MOTION-03 reveal feel.

### Claude's Discretion
- Exact `scroll-padding-bottom` value (D-02) — tune to the measured tallest sheet height.
- Whether to also add optional Esc-to-cancel (`phx-window-keydown="cancel_preview" phx-key="escape"` — pure LiveView attr, keyboard parity only, not a conformance need).
- Exact icon glyphs for the risk / audit-outcome chips (D-07/D-08).
- Whether the live/detail shell edits warrant a separate wave 47-03 or fold into 47-02.

### Deferred Ideas (OUT OF SCOPE)
- A real modal/dialog pattern with scrim + focus-trap + Esc + restore — out of scope permanently for this UI unless a genuine modal surface is introduced.
- A "failed" audit-outcome state and any `risk`/`outcome` column on `ActionItem` — needs a future API milestone.
- Page-level microcopy, `runbook_card`/`preview_panel` copy, `incident_timeline` empty state, and shared `_copy/1` voice tuning — Phase 48 (COPY-02).
- Literal byte-diff demo-mirror parity gate — Phase 50 (PARITY).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GROUP-01 | The response cockpit composes header/summary/actions coherently across all breakpoints | D-05: grid already collapses to single column below `lg`; D-06: add `break-words` to `<h2>` at ≈line 561; no structural change |
| GROUP-02 | Incident summary copy follows the brand voice formula (symptom → evidence → correlation → safe next action → where to inspect) | D-10/D-11: re-author `incident_summary/1` body (lines 810–928); rename five section labels; rewrite two fallback strings; zero data-shape change |
| GROUP-03 | The runbook card and preview panel render fully above their scrim and are never clipped or hidden | N/A-by-design (D-01): there is no scrim; `preview_panel` is a disclosure, `runbook_card` is inline `<div>`; documented in audit matrix |
| GROUP-04 | The action rail and action-item cards communicate risk and audit outcome; disabled actions are clearly disabled | D-07: `action_item_risk/1` helper for risk chips; D-08: audit-outcome chips from `state`; D-09: `aria-disabled` for shown-but-unavailable controls |
| GROUP-05 | Every overlay/modal/drawer traps focus, is dismissible via Esc + close button + scrim click, and restores focus on close | N/A-by-design (D-01): zero overlays/modals/drawers exist in the codebase |
| GROUP-06 | Overlays have correct stacking order | N/A-by-design (D-01): zero overlay elements; `preview_panel` uses `z-50` but no scrim above it |
| A11Y-05 | Modal/overlay focus management (trap + restore) is correct and verified | N/A-by-design (D-01): Disclosure pattern, not Dialog pattern; no focus-trap; WCAG 2.4.11 gap fixed by D-02 (scroll-padding-bottom) |
| MOTION-03 | Reveal/confirm/orient transitions (preview panel) use brand easing, are interruptible, and are reduced-motion-safe | D-13: `@keyframes po-preview-reveal` + `.po-preview-reveal` class on the container; D-14: no JS; existing prefers-reduced-motion block neutralizes automatically |
</phase_requirements>

---

## Summary

Phase 47 is a surgical pass over `operator_components.ex.eex` — the composed meta-components file — plus its byte-mirror counterpart in `examples/demo_app/`. The phase has four concrete deliverables:

1. **Brand-voice re-author of `incident_summary/1`** (GROUP-02): rename five section labels, rewrite two fallback strings, reorder the three card containers to trace symptom → evidence → correlation → safe next action → where to inspect top-to-bottom. Zero data-shape or field access change; pure label and connective-copy surgery.

2. **Action-item risk + audit-outcome chips** (GROUP-04): add `defp action_item_risk/1` deriving a risk tier from the five `ActionItem.kind` values; surface it via color+icon+label chips; add `chip_class(:execution, :executed)` for `resolved` items ("Resolved · audited") and a neutral "Pending" chip for `open` items. No schema migration.

3. **CSS keyframe reveal for `preview_panel`** (MOTION-03): add `@keyframes po-preview-reveal` and the `.po-preview-reveal` class to the theme bootstrap; apply it to the `preview_panel` outer container. The keyframe auto-fires on LiveView DOM insert because `preview_panel` is a stateless `:html` component diffed in/out by `operator_detail_live`'s `@incident.derived.active_preview` conditional.

4. **N/A overlay resolution** (GROUP-03/05/06 + A11Y-05): add `role="region"` + `aria-label="Recovery Preview"` to `preview_panel`; add `scroll-pb-72 md:scroll-pb-0` to the `operator_detail_live` `<main>` container (WCAG 2.4.11, technique C43); document overlay-absence in the audit matrix.

The ground-truth codebase verification confirms all line-number ranges cited in CONTEXT.md hold: `incident_summary/1` at lines 810–928, `preview_panel` at lines 1166–1229, `control_base()` at line 1392, motion tokens at lines 109–111, prefers-reduced-motion block at lines 466–478. The `response_cockpit` `<h2>` impact title is at line 561 (confirmed: currently lacks `break-words`).

**Primary recommendation:** Process in the 4-wave cadence locked by D-15. All template edits land in `operator_components.ex.eex` + its demo mirror. The `scroll-pb-72` edit lands in `operator_detail_live.ex.eex` + its demo mirror. No new files. No new packages.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Brand-voice labels in `incident_summary/1` | EEx template function body | Demo mirror (byte-identical) | Static label strings in the HEEx render function |
| `action_item_risk/1` helper + risk chips | EEx template private Elixir function | Demo mirror | New `defp` derived entirely from existing `ActionItem.kind` field |
| Audit-outcome chip rendering | EEx template `action_item_card/1` markup + `chip_class/2` | Demo mirror | `chip_class(:execution, :executed)` already exists; new "Pending" neutral sibling added inline |
| `aria-disabled` CSS rule for shown-but-unavailable controls | CSS rule in `operator_theme_bootstrap/1` `<style>` | — | CSS rule reads existing `--po-*` variables; markup adds `aria-disabled="true"` attribute |
| `@keyframes po-preview-reveal` + `.po-preview-reveal` class | CSS rule in `operator_theme_bootstrap/1` `<style>` | — | CSS keyframes belong in the theme bootstrap so dark-mode switching is automatically handled |
| `preview_panel` outer container class | `preview_panel/1` function markup | Demo mirror | Add `.po-preview-reveal` class to the outermost `<div>` at line 1169 |
| `role="region"` + `aria-label="Recovery Preview"` on `preview_panel` root | `preview_panel/1` function markup | Demo mirror | ARIA Disclosure landmark announcement |
| `scroll-pb-72 md:scroll-pb-0` (D-02) | `operator_detail_live.ex.eex` `<main>` | Demo mirror (`operator_detail_live.ex`) | WCAG 2.4.11 C43 — page-scroll container owns scroll-padding |
| Overflow hardening: `break-words` on cockpit `<h2>` | `response_cockpit/1` markup at ≈line 561 | Demo mirror | Matches existing `incident_summary` `break-words` pattern |
| N/A overlay documentation | `brandbook/notes/operator-audit-matrix.md` | — | Audit matrix is the idempotence ledger; no code change |
| Test assertions (GROUP-02/04, MOTION-03, N/A guards) | `test/parapet/operator_ui_contrast_test.exs` | — | Additive to existing test; no new test files |

---

## Standard Stack

No new library or package dependencies for Phase 47. The entire implementation uses:

- Phoenix HEEx (already a project dependency) [VERIFIED: in-use throughout all templates]
- Tailwind CSS (already compiled into demo app) [VERIFIED: present in demo app assets config]
- ExUnit (already the test framework) [VERIFIED: `operator_ui_contrast_test.exs` exists and passing]
- CSS Custom Properties + CSS `@keyframes` (native browser features) [VERIFIED: already used in `operator_theme_bootstrap/1`]

**Installation:** No `mix deps.get` or `npm install` needed for Phase 47.

---

## Package Legitimacy Audit

No external packages are introduced in Phase 47.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | N/A |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious SUS:** none

---

## Architecture Patterns

### System Architecture Diagram

```
operator_components.ex.eex ─────────────────────────────────────────────┐
  operator_theme_bootstrap/1 <style>                                     │
    @keyframes po-preview-reveal { opacity 0→1, translateY 8px→0 }       │  ← MOTION-03
    .po-preview-reveal { animation: po-preview-reveal var(--motion-base)  │
                                    var(--motion-ease) both; }            │
    [aria-disabled='true'] { opacity-50; cursor-not-allowed; }           │  ← D-09
    /* prefers-reduced-motion block (lines 466-478) already zeros        │
       animation-duration: 0.01ms !important — no new rule needed */     │
                                                                         │  templates
  response_cockpit/1                                                      │  (source)
    <h2> + break-words  ← D-06                                           │
                                                                         │
  incident_summary/1 (lines 810-928)                                     │
    section 1: "What users are seeing"  (was: "Impact Summary")          │  ← GROUP-02
    section 2: "Evidence on record"     (was: "Top Facts")               │
    section 3: "Where to inspect"       (was: "Observability")           │
    section 4: "Safe next step"         (was: "Next Step")               │
    section 5: "Escalation status"      (was: "Escalation Status")       │
                                                                         │
  action_item_card/1                                                      │
    action_item_risk/1 helper → color+icon+label chip  ← D-07/GROUP-04  │
    audit-outcome chip: resolved→"Resolved · audited",                   │
                       open→"Pending"               ← D-08/GROUP-04     │
                                                                         │
  preview_panel/1 (lines 1166-1229)                                      │
    <div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 ...      │  ← MOTION-03
          md:relative md:inset-auto ...">                                 │
      <div role="region" aria-label="Recovery Preview">  ← D-03         │
        ... (close button, content unchanged)                             │
                                                                         │
operator_detail_live.ex.eex ────────────────────────────────────────────┘
  <main id="parapet-main" tabindex="-1"
        class="... scroll-pb-72 md:scroll-pb-0">  ← D-02 WCAG 2.4.11   │
                                                                         │
          │ byte-mirror (every change)                                   │
          ▼                                                              │
examples/demo_app/lib/demo_app_web/live/parapet/                         │
  operator_components.ex     (mirror)                                    │
  operator_detail_live.ex    (mirror)                                    │

test/parapet/operator_ui_contrast_test.exs
  @component_paths loop ← EXTEND with 47 assertions
  @detail_template_paths loop ← EXTEND with D-02 scroll-pb assert
```

### Recommended File Edit Order

Process in this order (all within the 4-wave cadence):

```
Wave 47-01 (red scaffold — Wave 0 test additions, asserted RED):
  1. test/parapet/operator_ui_contrast_test.exs
     - Add GROUP-02 label assertions (asserted RED, labels not yet renamed)
     - Add GROUP-04 audit-outcome + aria-disabled assertions (RED)
     - Add MOTION-03 keyframe assertions (RED)
     - Add N/A negative-guard assertions for GROUP-03/05/06 + A11Y-05

Wave 47-02 (green — template + mirror edits flipping RED→GREEN):
  2. operator_components.ex.eex — CSS block: @keyframes, .po-preview-reveal, [aria-disabled] rule
  3. operator_components.ex.eex — incident_summary/1: rename labels, rewrite fallbacks
  4. operator_components.ex.eex — action_item_card/1: add action_item_risk/1 helper + chips
  5. operator_components.ex.eex — preview_panel/1: add .po-preview-reveal + role="region" + aria-label
  6. operator_components.ex.eex — response_cockpit/1: add break-words to <h2>
  For each above: apply IDENTICAL changes to demo mirror in the SAME commit.

Wave 47-03 (optional — shell edits):
  7. operator_detail_live.ex.eex — <main> + scroll-pb-72 (D-02)
     Mirror to: examples/demo_app/.../operator_detail_live.ex
  If shell edit is trivial, fold into Wave 47-02 task 2.

Wave 47-04 (autonomous: false — gate):
  8. mix test --exclude unboxed (full suite green)
  9. brandbook/notes/operator-audit-matrix.md — flip GROUP-02/04/MOTION-03 cells to "done";
     flip GROUP-03/05/06 + A11Y-05 to "n/a" with rationale
  10. Human gallery walkthrough: 390px cockpit, preview-panel open/close on mobile, MOTION-03
      reveal feel
```

### Pattern 1: CSS Keyframe Reveal for `preview_panel` (MOTION-03)

**What:** `@keyframes po-preview-reveal` auto-fires the instant the `preview_panel` component is inserted by LiveView's conditional diff.
**When to use:** Any stateless `:html` Phoenix.Component that is diffed in/out by a conditional — no `JS` alias possible; no class toggle available.

```css
/* Source: CONTEXT.md D-13; pattern from CSS-Tricks keyframes-on-insert approach [ASSUMED] */
/* Add to operator_theme_bootstrap/1 <style> block, after the prefers-reduced-motion block */

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

**Why this fires on insert:** LiveView diffs the DOM. When `@incident.derived.active_preview` transitions from `nil` to a value, LiveView inserts the `preview_panel` node from scratch. A CSS `@keyframes` animation with `animation-fill-mode: both` begins executing the moment the element enters the layout — no JavaScript toggle needed, no class change, no `display:` manipulation. [ASSUMED — based on CSS animation spec: animations on elements begin when the element gains a display context]

**Why prefers-reduced-motion is already handled:** The existing block at lines 466–478 sets `animation-duration: 0.01ms !important` for all `.parapet-ui *` children, which effectively zeroes the reveal without removing it. No new media-query rule is needed (D-14). [VERIFIED: actual template file read, lines 466-478]

**Why `phx-mounted={JS.transition(...)}` is rejected (D-14):** `preview_panel` is a stateless `attr(:html)` Phoenix.Component — it cannot alias `JS` from `Phoenix.LiveView.JS`. Trying to use `JS.transition/2` on a stateless component that has no access to the LiveView socket would require restructuring it as a stateful LiveComponent, which contradicts the no-new-JS-dependency boundary.

**Interruptibility:** A one-shot opacity/transform reveal that completes in 200ms never gates pointer events or `phx-click` handlers. Confirm/Cancel buttons remain live throughout the animation.

### Pattern 2: ARIA Disclosure — `preview_panel` Landmark (D-03)

**What:** Add `role="region"` + `aria-label="Recovery Preview"` to the `preview_panel` inner container so assistive technology announces the surface.

```heex
<%!-- operator_components.ex.eex ~line 1169 — CURRENT --%>
<div class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">

<%!-- REPLACE outermost div with .po-preview-reveal + inner wrapper with role/aria-label --%>
<div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div role="region" aria-label="Recovery Preview"
       class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
```

**Why `role="region"` on the inner div, not the outer:** The outer container is positional only (fixed/inset/z-index). The semantic landmark should wrap the visible content card. ARIA landmark roles require an accessible name when there is more than one landmark of the same type; `aria-label="Recovery Preview"` provides this. [ASSUMED — based on ARIA APG Landmark Regions guidance]

### Pattern 3: `aria-disabled` for Shown-but-Unavailable Controls (D-09)

**What:** For controls that are shown but currently unavailable (not hidden), use `aria-disabled="true"` rather than native `disabled`. This keeps the control in the tab order so keyboard/AT users can discover it and hear a reason.

**CSS rule to add to `operator_theme_bootstrap/1`:**
```css
/* D-09: shown-but-unavailable controls — matches control_base() :disabled visual */
.parapet-ui [aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

**Markup pattern:**
```heex
<%!-- D-09: use aria-disabled, NOT native disabled, on shown-but-unavailable controls --%>
<button
  aria-disabled={if condition_not_met?, do: "true", else: nil}
  phx-click="some_action"
  class={control_class(:recovery)}
>
  Action Label
</button>
```

**Why not native `disabled`:** Native `disabled` on `<button>` removes the element from the tab order entirely. A keyboard user navigating Actions would skip the control and never discover it exists. `aria-disabled="true"` keeps it focusable and AT-announced with its label, but its `pointer-events: none` + `phx-click` precondition ensures it does nothing when activated. [ASSUMED — based on Kitty Giraudel / CSS-Tricks aria-disabled vs disabled guidance cited in CONTEXT.md specifics section]

**Important scoping note (D-09 vs COMP-02):** COMP-02 (Phase 45) wired native `disabled` into `control_base()` for `<button>` elements that are genuinely always-disabled. D-09 is for controls that are shown to the user specifically because they want to discover them — the hide-with-explanation pattern already handles truly hidden controls. The `[aria-disabled='true']` CSS rule is an additive selector; it does not conflict with the existing `disabled:opacity-50` utilities already in `control_base()`.

### Pattern 4: `action_item_risk/1` Helper — Deriving Risk from `ActionItem.kind` (D-07)

**What:** A new private Elixir function deriving a risk tier from the five existing `ActionItem.kind` values. No schema change.

```elixir
# Source: ActionItem schema — @kinds = ["exact_follow_up", "suppressed_delivery",
# "stalled_workflow", "orphaned_callback", "dead_letter"]
# [VERIFIED: lib/parapet/spine/action_item.ex read directly]

defp action_item_risk("dead_letter"), do: :danger
defp action_item_risk("orphaned_callback"), do: :warning
defp action_item_risk("stalled_workflow"), do: :warning
defp action_item_risk("suppressed_delivery"), do: :info
defp action_item_risk("exact_follow_up"), do: :neutral
defp action_item_risk(_), do: :neutral
```

**Chip rendering in `action_item_card/1`:**
```heex
<%!-- D-07: Risk chip — color + icon + label, never color alone (WCAG 1.4.1) --%>
<span class={["po-chip", risk_chip_class(action_item_risk(@item.kind)), "rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide flex items-center gap-1"]}>
  <%!-- SVG icon appropriate to tier (aria-hidden="true") --%>
  <svg aria-hidden="true" .../>
  <%%= risk_label(action_item_risk(@item.kind)) %>
</span>
```

Where `risk_chip_class(:danger)` → `"po-chip-danger"`, `:warning` → `"po-chip-warning"`, `:info` → `"po-chip-info"`, `:neutral` → `""` (plain po-chip). And `risk_label(:danger)` → `"High risk"`, `:warning` → `"Medium risk"`, `:info` → `"Low risk"`, `:neutral` → `"Routine"`.

The icon glyph is at Claude's discretion (see Locked Decisions). Suggested defaults:
- `:danger` — exclamation triangle (heroicon `exclamation-triangle`)
- `:warning` — exclamation circle (`exclamation-circle`)
- `:info` — information circle (`information-circle`)
- `:neutral` — check circle (`check-circle`) or no icon

### Pattern 5: Audit-Outcome Chip (D-08)

**What:** Surface AUDIT OUTCOME on `action_item_card/1` using existing `chip_class/2` variants.

```heex
<%!-- D-08: Audit outcome derived honestly from state --%>
<span class={audit_outcome_chip_class(@item.state)}>
  <%%= audit_outcome_label(@item.state) %>
</span>
```

```elixir
defp audit_outcome_chip_class("resolved"),
  do: chip_class(:execution, :executed)  # po-chip po-chip-success — already exists

defp audit_outcome_chip_class(_state),
  do: "po-chip rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"
  # neutral chip — "Pending"

defp audit_outcome_label("resolved"), do: "Resolved · audited"
defp audit_outcome_label(_state), do: "Pending"
```

**Why no "failed" state (D-08):** The `ActionItem` schema has only `state` values `"open"` and `"resolved"`. There is no `outcome` or `error` field. Fabricating a "failed" chip from absence of `resolved` is misleading; "Pending" accurately describes `open` items. A future API milestone would need to add an outcome field first.

### Pattern 6: `incident_summary/1` Brand-Voice Re-author (D-10/D-11)

**What:** Reorder and relabel the three card containers in `incident_summary/1` (lines 810–928) to trace the brand formula top-to-bottom. The three existing cards are:
1. Impact/intro header (lines 812–821)
2. Escalation status card (amber, lines 823–889)
3. Two-column grid: "Top Facts" + "Observability" (lines 891–925)

**Formula mapping to card structure:**
- symptom → "What users are seeing" (rename Impact Summary header)
- evidence → "Evidence on record" (rename Top Facts)
- correlation → implied by the fault-plane data already in Evidence on record
- safe next action → "Safe next step" (now surfaces from Escalation section data)
- where to inspect → "Where to inspect" (rename Observability)

**Note:** The existing three-card structure already has roughly correct semantic groupings. D-10 re-authors the ordering so reading top-to-bottom traces the formula. The planner may need to reorder the escalation card vs the top-facts/observability grid to match the intended reading order.

**Label changes (verbatim from D-11):**
- `"Impact Summary"` → `"What users are seeing"`
- `"Top Facts"` → `"Evidence on record"`
- `"Observability"` → `"Where to inspect"`
- `"Next Step"` → `"Safe next step"` (inside escalation card)
- `"Escalation Status"` → `"Escalation status"` (sentence case)

**Fallback string changes (verbatim from D-11):**
- `"No impact summary recorded."` → `"No user-facing impact has been recorded yet."`
- `"No external links attached."` → `"No trace or external links are attached to this incident yet."`

**Zero data-shape change:** All `@detail.*` and `@detail.derived.*` field accesses remain identical.

### Pattern 7: `scroll-padding-bottom` for D-02 (WCAG 2.4.11, Technique C43)

**What:** On the `operator_detail_live` `<main>` container, add `scroll-pb-72 md:scroll-pb-0` to prevent the fixed bottom sheet from fully covering the keyboard-focused trigger element.

```heex
<%!-- operator_detail_live.ex.eex ~line 224 — CURRENT --%>
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">

<%!-- UPDATED — D-02 WCAG 2.4.11 SC: scroll-padding-bottom on mobile, cleared on md+ --%>
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8 scroll-pb-72 md:scroll-pb-0">
```

**Value reasoning:** The `preview_panel` outer container has `p-4` (16px padding) wrapping the content card. The tallest observed sheet on mobile is approximately 280px. `scroll-pb-72` = 288px (18rem), which gives a small margin. The planner may tune this via Claude's Discretion (D-02). At `md:` breakpoints the panel is `md:relative md:inset-auto` (inline, not fixed), so `md:scroll-pb-0` clears the padding. [ASSUMED — exact pixel measurement not done in research; tune from gallery]

**Why this is WCAG technique C43:** CSS `scroll-padding-bottom` causes the browser's scroll-into-view behavior to stop scrolling with the specified offset from the bottom, ensuring the focused element is visible above the fixed sheet. This is a CSS-only implementation of WCAG SC 2.4.11 (Focus Not Obscured) using technique C43 (Using CSS scroll-padding to un-obscure focused elements). [ASSUMED — based on WCAG C43 description cited in CONTEXT.md D-02]

### Pattern 8: `break-words` on Cockpit `<h2>` (D-06)

```heex
<%!-- operator_components.ex.eex ~line 561 — CURRENT --%>
<h2 class="text-3xl font-semibold text-stone-950 text-balance"><%%= @detail.incident.title %></h2>

<%!-- UPDATED — D-06: match incident_summary overflow hardening --%>
<h2 class="text-3xl font-semibold text-stone-950 text-balance break-words"><%%= @detail.incident.title %></h2>
```

**Precedent:** `incident_summary/1` already uses `whitespace-normal break-words` on its `<h1>` (line 815, VERIFIED). This is the same protection extended to the cockpit heading. [VERIFIED: actual template file read]

### Anti-Patterns to Avoid

- **Adding `role="dialog"` or `aria-modal` to `preview_panel`:** This would transform the Disclosure into a Dialog, require a focus-trap, and break the no-new-JS boundary. The negative-guard test (D-16) enforces this — `refute content =~ "role=\"dialog\""` and `refute content =~ "aria-modal"` go red if anyone adds these by mistake.
- **Using `JS.transition/2` on `preview_panel`:** The component is a stateless `:html` Phoenix.Component with no access to `Phoenix.LiveView.JS`. The CSS keyframe approach (D-13) is the correct solution.
- **Adding a `@starting-style` + `allow-discrete` reveal:** Not yet Baseline across all supported browsers (D-14). The `@keyframes` approach has superior compatibility.
- **Using `transition-all` on the reveal:** Prohibited by MOTION-02. The keyframe uses only compositor-layer properties (opacity, transform).
- **Fabricating a "failed" audit-outcome state:** D-08 explicitly prohibits this. `open` maps to "Pending" only.
- **Changing `ActionItem` schema / adding a migration:** Scope boundary. All risk/outcome derivation is component-layer only.
- **Editing `_copy/1` helpers (lines ≈1494–1560):** Phase 47 boundary (D-12). Those helpers are on-voice already; do not churn them.
- **Editing `runbook_card` copy, `preview_panel` copy, or `incident_timeline` empty state copy:** Phase 48 (COPY-02) boundary (D-12).
- **Adding `disabled` to `<button>` elements for shown-but-unavailable controls:** Use `aria-disabled="true"` instead (D-09).
- **Changing any CSS variable values:** Locked by Phases 44/45. Phase 47 only ADDS CSS rules and modifies markup strings/classes.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preview panel CSS reveal | `JS.transition`, `phx-mounted`, custom hook | CSS `@keyframes po-preview-reveal` on `.po-preview-reveal` class | `preview_panel` is a stateless component with no JS access; keyframe fires on DOM insert automatically |
| Dark-mode-aware reveal animation | JS-detected dark mode + separate animation | `var(--motion-base)` + `var(--motion-ease)` in the keyframe animation property | CSS variables already resolve correctly in both themes via the existing cascade |
| Risk color logic | Custom if/else tree checking `kind` | `action_item_risk/1` helper → `chip_class/2` (po-chip-danger/warning/info) | `chip_class/2` is already fully tokenized for dark mode |
| Audit-outcome chip from scratch | New CSS class for "executed" | `chip_class(:execution, :executed)` — already defined and asserting `po-chip-success` | Phase 44/45 already wired this |
| Focus-not-obscured polyfill | IntersectionObserver JS | `scroll-pb-72 md:scroll-pb-0` Tailwind arbitrary value on `<main>` | CSS-only; no runtime dependency; zeroed automatically at md+ breakpoint |
| ARIA modal for `preview_panel` | `role="dialog"` + focus-trap + Esc | `role="region"` + `aria-label` (Disclosure pattern) | There is no scrim, no modal; Dialog pattern would require new JS and violates the milestone boundary |

**Key insight:** Every deliverable in Phase 47 is an additive string change (label rename, new class, new CSS rule, new private helper). The codebase's existing infrastructure — the chip system, the motion tokens, the prefers-reduced-motion block, the control_base helpers — absorbs all new features without structural changes.

---

## Runtime State Inventory

Phase 47 is template markup, CSS, and copy-string edits only. No rename, migration, or data change.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no data stored for CSS class names or label strings | None |
| Live service config | None — template-only changes | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — no compiled binaries affected | None |

**Nothing found in any category** — verified by nature of the phase (additive HEEx/CSS/Elixir string edits only).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | Running tests | ✓ | (project already running) | — |
| ExUnit | Contrast + demo-contract tests | ✓ | built-in | — |
| Browser (gallery walkthrough) | MOTION-03 visual verify + 390px verify | ✓ | demo app running locally | — |

No external tools beyond the normal Elixir development toolchain.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` |
| Full suite command | `mix test --exclude unboxed` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Automatable? |
|--------|----------|-----------|-------------------|-------------|
| GROUP-01 | `response_cockpit` `<h2>` has `break-words` | string search assert | `assert content =~ "break-words"` in `@component_paths` | YES |
| GROUP-01 | Cockpit grid collapses correctly | visual | gallery at 390px | GALLERY ONLY |
| GROUP-02 | `incident_summary` uses formula label "What users are seeing" | string search assert | `assert content =~ "What users are seeing"` in `@component_paths` | YES |
| GROUP-02 | `incident_summary` uses "Evidence on record" | string search assert | `assert content =~ "Evidence on record"` in `@component_paths` | YES |
| GROUP-02 | `incident_summary` uses "Where to inspect" | string search assert | `assert content =~ "Where to inspect"` in `@component_paths` | YES |
| GROUP-02 | `incident_summary` uses "Safe next step" | string search assert | `assert content =~ "Safe next step"` in `@component_paths` | YES |
| GROUP-02 | Updated fallback strings present | string search assert | `assert content =~ "No user-facing impact has been recorded yet."` and `assert content =~ "No trace or external links are attached to this incident yet."` in `@component_paths` | YES |
| GROUP-02 | Old label strings absent | string search refute | `refute content =~ "Impact Summary"` and `refute content =~ "Top Facts"` and `refute content =~ ">Observability<"` in `@component_paths` | YES |
| GROUP-03 | No `role="dialog"` in components | string search refute | `refute content =~ "role=\"dialog\""` in `@component_paths` | YES (N/A guard) |
| GROUP-03 | No `aria-modal` in components | string search refute | `refute content =~ "aria-modal"` in `@component_paths` | YES (N/A guard) |
| GROUP-03 | No full-screen scrim (`fixed inset-0` without the disclosure suffix) | string search refute | `refute content =~ "fixed inset-0"` in `@component_paths` | YES (N/A guard — note: preview_panel uses `fixed inset-x-0 bottom-0`, not `fixed inset-0`) |
| GROUP-03 | `preview_panel` has Disclosure shape (`md:relative md:inset-auto`) | string search assert | `assert content =~ "md:relative md:inset-auto"` in `@component_paths` | YES |
| GROUP-03 | Close button present with correct `aria-label` | string search assert | `assert content =~ ~S|aria-label="Close Recovery Preview"|` already in contrast test | YES — already asserted |
| GROUP-04 | `action_item_risk` helper present | string search assert | `assert content =~ "action_item_risk"` in `@component_paths` | YES |
| GROUP-04 | Audit-outcome "Resolved · audited" label present | string search assert | `assert content =~ "Resolved · audited"` in `@component_paths` | YES |
| GROUP-04 | Audit-outcome "Pending" label present | string search assert | `assert content =~ ~S|>Pending<|` (or similar) in `@component_paths` | YES |
| GROUP-04 | `aria-disabled` CSS rule present | string search assert | `assert content =~ ~S|[aria-disabled="true"]|` in `@component_paths` | YES |
| GROUP-04 | `aria-disabled` CSS gives opacity-50 | string search assert | `assert content =~ "opacity: 0.5"` (or `"opacity: 50%"`) in `@component_paths` | YES |
| GROUP-05 | N/A guard: no focus-trap in codebase | string search refute | `refute content =~ "aria-modal"` (same as GROUP-03 guard) | YES (N/A guard) |
| GROUP-06 | N/A guard: no overlay scrim | same refutes as GROUP-03 | covered by GROUP-03 guards | YES (N/A guard) |
| A11Y-05 | N/A guard: Disclosure, not Dialog, shape confirmed | `assert "md:relative md:inset-auto"` + `assert "role=\"region\""` + `assert "aria-label=\"Recovery Preview\""` | YES |
| MOTION-03 | `@keyframes po-preview-reveal` defined | string search assert | `assert content =~ "@keyframes po-preview-reveal"` in `@component_paths` | YES |
| MOTION-03 | Animation applied via `.po-preview-reveal` class | string search assert | `assert content =~ "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"` in `@component_paths` | YES |
| MOTION-03 | No `transition-all` (already asserted) | string search refute | `refute content =~ "transition-all"` — already in test | YES — already asserted |
| MOTION-03 | prefers-reduced-motion zeroes animation | string search assert | `assert content =~ "animation-duration: 0.01ms"` — already in test | YES — already asserted |
| MOTION-03 | Reveal feel, interruptibility | visual | gallery preview-panel open/close + button activation mid-animation | GALLERY ONLY |
| D-02 (A11Y-05) | `scroll-pb-72 md:scroll-pb-0` on `<main>` | string search assert | `assert content =~ "scroll-pb-72"` in `@detail_template_paths` | YES |

### New Assertions to Add to `operator_ui_contrast_test.exs`

**In the `@component_paths` test loop (additive):**

```elixir
# GROUP-01: cockpit break-words overflow hardening
assert content =~ "break-words"

# GROUP-02: brand-voice formula labels (D-11)
assert content =~ "What users are seeing"
assert content =~ "Evidence on record"
assert content =~ "Where to inspect"
assert content =~ "Safe next step"
# Updated fallback strings
assert content =~ "No user-facing impact has been recorded yet."
assert content =~ "No trace or external links are attached to this incident yet."
# Old label strings must be absent
refute content =~ "Impact Summary"
refute content =~ "Top Facts"
# Note: "Observability" may appear elsewhere in the codebase; use more specific match
# e.g. check the h4 context: refute content =~ ~S|<h4 class="text-sm font-medium|  + "Observability"
# Safer: assert the replacement is present (above asserts) rather than refuting the old

# GROUP-03/05/06 + A11Y-05: N/A negative-guards (D-16)
refute content =~ "role=\"dialog\""
refute content =~ "aria-modal"
# Note: preview_panel uses "fixed inset-x-0 bottom-0" NOT "fixed inset-0"
# The guard is specifically for a full-screen scrim pattern
refute content =~ ~S|class="fixed inset-0|
assert content =~ "md:relative md:inset-auto"
# Close button aria-label already asserted — no new assertion needed
assert content =~ ~S|aria-label="Close Recovery Preview"|  # already passing

# A11Y-05: Disclosure shape confirmed
assert content =~ ~S|role="region"|
assert content =~ ~S|aria-label="Recovery Preview"|

# GROUP-04: risk/audit-outcome chips + aria-disabled rule (D-07/D-08/D-09)
assert content =~ "action_item_risk"
assert content =~ "Resolved · audited"
assert content =~ ~S|[aria-disabled="true"]|

# MOTION-03: keyframe reveal (D-13)
assert content =~ "@keyframes po-preview-reveal"
assert content =~ "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"
# (transition-all refute already passing; reduced-motion assert already passing)
```

**In the `@detail_template_paths` test loop (additive):**

```elixir
# D-02: WCAG 2.4.11 scroll-padding-bottom fix
assert content =~ "scroll-pb-72"
```

### Sampling Rate

- **Per task commit:** `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **Per wave merge:** `mix test --exclude unboxed`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps (Tasks for Wave 47-01)

All test additions are to the existing `operator_ui_contrast_test.exs` file — no new test files.

- [ ] Add GROUP-02 label assertions (RED until Wave 47-02 template edits)
- [ ] Add GROUP-03/05/06 N/A negative-guard refutes (note: `fixed inset-0` guard only — not `inset-x-0`)
- [ ] Add A11Y-05 Disclosure-shape asserts (`role="region"`, `aria-label="Recovery Preview"`)
- [ ] Add GROUP-04 `action_item_risk`, audit-outcome, `[aria-disabled="true"]` CSS asserts
- [ ] Add MOTION-03 keyframe asserts
- [ ] Add D-02 `scroll-pb-72` assert to `@detail_template_paths` test

---

## Common Pitfalls

### Pitfall 1: `refute "fixed inset-0"` Guard Too Broad

**What goes wrong:** `preview_panel` uses `fixed inset-x-0 bottom-0 z-50` — which contains the substring `inset-` but NOT `inset-0` literally. However, a naive `refute content =~ "fixed inset-0"` might pass when it should not, or a poorly scoped guard might accidentally refute the existing correct classes.
**Why it happens:** The scrim pattern uses `fixed inset-0 z-50` (four sides). The preview panel uses `fixed inset-x-0 bottom-0 z-50` (horizontal sides + bottom only). The strings are different.
**How to avoid:** Use `refute content =~ ~S|class="fixed inset-0|` to guard the full-screen pattern. Do NOT use `refute content =~ "inset-0"` (too broad — could match `inset-auto` negation). [VERIFIED: actual template `preview_panel` at line 1169 uses `fixed inset-x-0 bottom-0 z-50`]

### Pitfall 2: Demo Mirror Divergence

**What goes wrong:** Template edit applied to `operator_components.ex.eex` but not to `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`. The `@component_paths` contrast test reads BOTH files — the assertion fails on the mirror only.
**Why it happens:** Phase 47 has higher surface area than prior phases: `incident_summary/1` labels, `action_item_card/1` chips, `preview_panel` classes, `@keyframes` CSS, and `<h2>` class strings all need mirroring.
**How to avoid:** Apply every template edit to the demo mirror in the SAME commit. The contrast test assertion pattern (string search on `@component_paths` which includes both paths) provides continuous parity checking.

### Pitfall 3: "Observability" String Refute May Be Too Broad

**What goes wrong:** `refute content =~ "Observability"` would fail if "Observability" appears elsewhere in the template (e.g., in a comment, a different component, or a helper function body). The template is 1,753 lines — there may be other occurrences.
**Why it happens:** Single-word string refutes are fragile.
**How to avoid:** Instead of refuting the old label, assert the new label is present. The positive asserts (`assert content =~ "Where to inspect"`) are sufficient to prove the rename happened. If refute is needed, use a more specific context string that includes surrounding markup.
**Warning signs:** `refute content =~ "Observability"` fails on a valid template because the word appears in a comment or a copy helper.

### Pitfall 4: Three-Card Reorder vs Label-Only Change

**What goes wrong:** D-10 says "re-author only the body of `incident_summary/1` so reading top-to-bottom traces the brand formula." The three cards currently are: (1) impact header, (2) escalation amber card, (3) two-column top-facts/observability grid. The brand formula order is: symptom → evidence → correlation → safe next action → where to inspect. The planner may need to reorder card 2 and card 3 to get "Evidence on record" BEFORE "Escalation status" + "Safe next step."
**Why it happens:** The formula sequence does not match the current card render order.
**How to avoid:** Plan the exact new card ordering before editing. Verify by reading `incident_summary/1` lines 810–928 (VERIFIED above) and tracing the formula. The planner decision is at Claude's Discretion — the research confirms the current order and the target formula; the planner determines the optimal card sequence.

### Pitfall 5: `po-preview-reveal` Applied to Wrong Element

**What goes wrong:** The `.po-preview-reveal` class is added to the inner content `<div>` (line 1170) instead of the outermost positioning container (line 1169). If applied to the inner div, the translateY reveal would cause a layout jump because the outer fixed/absolute container has already been inserted.
**Why it happens:** There are two wrapping `<div>` elements in `preview_panel`.
**How to avoid:** Add `.po-preview-reveal` to the OUTERMOST `<div>` at line 1169 (the one with `fixed inset-x-0 bottom-0 z-50`). The animation runs on the entire positioned container, providing a unified lift-up reveal. [VERIFIED: template structure at lines 1169–1229]

### Pitfall 6: Dark-Mode Override Not Needed for Keyframe

**What goes wrong:** A developer adds a separate dark-block override for `.po-preview-reveal`. Not necessary.
**Why it happens:** Phase 44 pattern required dark-block overrides for color variables. But the keyframe uses only `opacity` and `transform` — neither is color-dependent. The animation timing vars (`--motion-base`, `--motion-ease`) are defined in the base `.parapet-ui` block and are not theme-dependent.
**How to avoid:** The `.po-preview-reveal` class rule in the base `.parapet-ui` block is sufficient. No dark override is needed. Trust the variable cascade.

### Pitfall 7: `chip_class(:execution, :executed)` Assertion vs New Neutral Chip

**What goes wrong:** The existing contrast test already asserts `chip_class(:execution, :executed)` returns `po-chip po-chip-success`. Adding a NEW neutral audit-outcome chip may use different class strings that need their own assertion.
**Why it happens:** Phase 47 adds a "Pending" neutral chip that may or may not use `chip_class/2`. If it uses inline classes, the test must assert those inline strings instead.
**How to avoid:** If the "Pending" neutral chip is rendered via `"po-chip rounded px-1.5 py-0.5 ..."` inline, assert that specific string fragment. If extracted to a `chip_class/2` variant, assert the variant. The planner must choose and make the assertion match the implementation.

---

## Code Examples

### Complete `.po-preview-reveal` CSS + Keyframe (MOTION-03)

```css
/* Source: CONTEXT.md D-13; add to operator_theme_bootstrap/1 <style> block
   after the .parapet-ui .po-timeline-list > li:last-child rule (end of component classes) */

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
/* No dark override needed — opacity + transform are theme-independent.
   prefers-reduced-motion block at lines 466-478 already sets
   animation-duration: 0.01ms !important which neutralizes this reveal. */
```

### `[aria-disabled='true']` CSS Rule (D-09)

```css
/* Source: CONTEXT.md D-09; add to operator_theme_bootstrap/1 <style> block
   near control_base disabled pattern */

/* D-09: shown-but-unavailable controls — matches control_base() disabled visual */
.parapet-ui [aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

### `preview_panel` Outer Container Update (D-03 + D-13)

```heex
<%!-- operator_components.ex.eex — CURRENT line 1169 --%>
<div class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">

<%!-- REPLACE (D-03 + D-13): add .po-preview-reveal + role="region" + aria-label --%>
<div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div role="region" aria-label="Recovery Preview"
       class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
```

### `action_item_risk/1` Helper (D-07)

```elixir
# Add as a private defp after action_item_card/1 in operator_components.ex.eex
# [VERIFIED: ActionItem @kinds = ["exact_follow_up","suppressed_delivery",
#  "stalled_workflow","orphaned_callback","dead_letter"] — lib/parapet/spine/action_item.ex]

defp action_item_risk("dead_letter"),        do: :danger
defp action_item_risk("orphaned_callback"),  do: :warning
defp action_item_risk("stalled_workflow"),   do: :warning
defp action_item_risk("suppressed_delivery"), do: :info
defp action_item_risk("exact_follow_up"),    do: :neutral
defp action_item_risk(_),                    do: :neutral

defp risk_chip_class(:danger),  do: "po-chip-danger"
defp risk_chip_class(:warning), do: "po-chip-warning"
defp risk_chip_class(:info),    do: "po-chip-info"
defp risk_chip_class(_),        do: ""

defp risk_label(:danger),  do: "High risk"
defp risk_label(:warning), do: "Medium risk"
defp risk_label(:info),    do: "Low risk"
defp risk_label(_),        do: "Routine"
```

### Audit-Outcome Chip Helpers (D-08)

```elixir
defp audit_outcome_chip_class("resolved"),
  do: chip_class(:execution, :executed)
  # → "po-chip po-chip-success rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"

defp audit_outcome_chip_class(_state),
  do: "po-chip rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"

defp audit_outcome_label("resolved"), do: "Resolved · audited"
defp audit_outcome_label(_state),     do: "Pending"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `preview_panel` appears instantly with no entrance feedback | CSS `@keyframes po-preview-reveal` lift from 8px (D-13) | Phase 47 | Operators perceive the panel as appearing in response to their action; compositor-only, no jank |
| `action_item_card` shows state text only (no risk signal) | Risk chip via `action_item_risk/1` — color + icon + label (D-07) | Phase 47 | Color-blind-safe; WCAG 1.4.1 compliant |
| `action_item_card` shows state ("open"/"resolved") only | Audit-outcome chip ("Resolved · audited" / "Pending") (D-08) | Phase 47 | Operators see explicit audit confirmation, not raw state |
| `incident_summary` labels are technical ("Top Facts", "Observability") | Brand-formula labels ("Evidence on record", "Where to inspect") (D-11) | Phase 47 | Matches the voice formula; operators trace symptom → action top-to-bottom |
| `preview_panel` has no ARIA landmark | `role="region"` + `aria-label="Recovery Preview"` (D-03) | Phase 47 | Screen-reader users can navigate to the preview surface by landmark |
| Fixed bottom sheet can cover focused trigger on short mobile viewports | `scroll-pb-72 md:scroll-pb-0` on `<main>` (D-02) | Phase 47 | WCAG 2.2 SC 2.4.11 satisfied via technique C43 |

**Deprecated/outdated:**
- Old `incident_summary` label strings ("Impact Summary", "Top Facts", "Observability", "Next Step" as a heading, "Escalation Status" in title case): replaced by D-11 labels.
- Old fallback string "No impact summary recorded.": replaced by "No user-facing impact has been recorded yet."
- Old fallback string "No external links attached.": replaced by "No trace or external links are attached to this incident yet."

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | CSS `@keyframes` auto-fires when the element is DOM-inserted by LiveView diff | Pattern 1 (MOTION-03) | LOW: This is the fundamental CSS animation spec behavior — animations begin when an element gains a computed display context. Well-established cross-browser behavior. If wrong, the reveal simply doesn't animate (no functional regression) |
| A2 | `scroll-pb-72` (288px) is sufficient to un-obscure a focused trigger above the tallest mobile sheet height | Pattern 7 (D-02) | MEDIUM: Exact sheet height is not pixel-measured in this research. Value is a conservative over-estimate. Claude's Discretion (D-02) permits tuning. If too large, extra scroll space is added but nothing breaks |
| A3 | `role="region"` belongs on the inner content `<div>` (line 1170), not the outermost positioning container (line 1169) | Pattern 2 (D-03) | LOW: Either would technically work, but `role="region"` on the positioned outer div would announce the positioning wrapper as a landmark, not the content card. Inner div is semantically cleaner |
| A4 | `refute content =~ ~S|class="fixed inset-0|` is a safe guard that won't accidentally catch `preview_panel`'s `fixed inset-x-0` | Pitfall 1, Test assertions | LOW: `"fixed inset-0"` and `"fixed inset-x-0"` are distinct strings. Verified by reading the template at line 1169 |
| A5 | The "Observability" string is unique enough in `incident_summary/1` that its absence can be inferred by the presence of "Where to inspect" | Pitfall 3 | MEDIUM: Other components or helpers may use the word "Observability." Positive-assert approach (asserting new label) is safer than negative-refute |
| A6 | Reordering `incident_summary` card order (escalation card vs top-facts/observability grid) to trace the formula is within D-10 scope | Pattern 6 | LOW: D-10 explicitly says "re-author only the body" — reordering card order within the same component is in scope. Planner confirms |

**If this table is empty:** N/A — see above assumptions.

---

## Open Questions

1. **Exact `scroll-padding-bottom` value (Claude's Discretion per D-02)**
   - What we know: `preview_panel` outer container has `p-4` (16px) padding. The tallest sheet depends on content. `scroll-pb-72` = 288px is a conservative estimate.
   - What's unclear: The rendered height of the tallest preview panel content (warnings, idempotency caveats, targeting hints all affect height).
   - Recommendation: Start with `scroll-pb-72`. Tune during gallery walkthrough. If the tallest fixture scenario overflows, increase to `scroll-pb-80` (320px).

2. **Whether optional Esc-to-cancel improves the mobile experience (Claude's Discretion)**
   - What we know: `phx-window-keydown="cancel_preview" phx-key="escape"` on the `operator_detail_live` LiveView (not on the stateless component) would add keyboard dismiss parity.
   - What's unclear: Whether the current `phx-click="cancel_preview"` close button is sufficient for WCAG 2.2 AA (yes — SC 2.4.7 focus visible + SC 2.1.1 keyboard are already met by the close button).
   - Recommendation: The Esc handler is a DX improvement, not a conformance requirement. Fold it into Wave 47-03 if the shell edit is added. If Wave 47-03 is omitted, skip it.

3. **Card ordering in `incident_summary/1` rewrite (D-10 intent)**
   - What we know: Current order: (1) header/impact, (2) escalation amber card, (3) two-column top-facts/observability. Formula order: symptom → evidence → correlation → safe next action → where to inspect.
   - What's unclear: Whether the planner should reorder so "Evidence on record" (top-facts) appears BEFORE "Escalation status" to match the formula sequence.
   - Recommendation: The formula has `evidence` before `safe next action`. Moving the evidence card above the escalation card would better match the formula reading order. However, the escalation card is visually prominent (amber); moving it after may reduce urgency. The planner should keep the structure that best serves the tired-Phoenix-developer reader. This is within Claude's Discretion (D-10 says "re-author only the body").

---

## Security Domain

Phase 47 introduces no new network endpoints, authentication paths, user input handling, or data access patterns.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | All edits are static label strings and CSS rules; no new user input |
| V6 Cryptography | no | — |

### Known Threat Patterns for Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via `aria-*` attribute injection | Tampering | Phoenix HEEx auto-escapes all interpolations; `aria-label="Recovery Preview"` is a static string — no interpolation |
| XSS via `role` attribute injection | Tampering | `role="region"` is a static string — no interpolation |

No new threat surface. Phase 44 threat scan remains the applicable baseline.

---

## Current Code State: Verified Line Numbers

These locations were confirmed by reading the actual template files. Plans must search for these patterns rather than relying on fixed line numbers (prior edits shift lines).

### `operator_components.ex.eex` (1,753 lines, VERIFIED)

| Component | Location Pattern | Current State | Phase 47 Action |
|-----------|-----------------|---------------|-----------------|
| Motion tokens | Lines 109–111 | `--motion-fast: 120ms`, `--motion-base: 200ms`, `--motion-ease: cubic-bezier(...)` | No change — used by new keyframe |
| `prefers-reduced-motion` block | Lines 466–478 | Zeros `--motion-fast`, `--motion-base`; sets `animation-duration: 0.01ms !important` | No change — already neutralizes new keyframe |
| `response_cockpit/1` `<h2>` | ≈Line 561 | `class="text-3xl font-semibold text-stone-950 text-balance"` — NO `break-words` | ADD `break-words` |
| `incident_summary/1` body | Lines 810–928 | Three card containers; labels "Impact Summary", "Top Facts", "Observability", "Next Step", "Escalation Status"; fallbacks "No impact summary recorded.", "No external links attached." | Rename labels, rewrite fallbacks (D-11); reorder if needed (D-10) |
| `action_item_card/1` | Lines 1305–1337 | No risk chip; shows `@item.state` text chip via `state_color/1` only | ADD `action_item_risk/1` + audit-outcome chip (D-07/D-08) |
| `chip_class(:execution, :executed)` | Lines 1408–1410 | Returns `po-chip po-chip-success rounded px-1.5 py-0.5 ...` | REUSE for "Resolved · audited" audit-outcome chip |
| `control_base()` | Line 1392 | `disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none` wired | No change — `[aria-disabled]` rule is a NEW CSS selector addition |
| `preview_panel/1` outer `<div>` | Line 1169 | `class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6"` | ADD `.po-preview-reveal` class |
| `preview_panel/1` inner `<div>` | Line 1170 | `class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden"` | ADD `role="region" aria-label="Recovery Preview"` |

### `operator_detail_live.ex.eex`

| Element | Location Pattern | Current State | Phase 47 Action |
|---------|-----------------|---------------|-----------------|
| `<main>` container | ≈Line 224 | `class="flex-1 bg-stone-50 px-4 py-6 md:px-8"` (with `id="parapet-main" tabindex="-1"`) | ADD `scroll-pb-72 md:scroll-pb-0` |

---

## Sources

### Primary (HIGH confidence — VERIFIED against actual file contents)

- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — Full file read: motion tokens at lines 109–111, prefers-reduced-motion block at lines 466–478, `response_cockpit/1` at lines 552–628, `incident_summary/1` at lines 810–928, `action_item_card/1` at lines 1305–1337, `chip_class/2` helpers at lines 1399–1410, `control_base()` at line 1392, `preview_panel/1` at lines 1166–1229 [VERIFIED: file read]
- `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` — `<main>` container at line 224, `preview_panel` mount conditional at lines 246–248 [VERIFIED: file read]
- `lib/parapet/spine/action_item.ex` — `@kinds` list (`["exact_follow_up", "suppressed_delivery", "stalled_workflow", "orphaned_callback", "dead_letter"]`) and `state` field (`"open"/"resolved"`) [VERIFIED: file read]
- `test/parapet/operator_ui_contrast_test.exs` — Current `@component_paths`, `@live_template_paths`, `@detail_template_paths`, existing assertion patterns [VERIFIED: file read, full 270-line file]
- `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` — Confirmed `id="parapet-main"` at line 225, `aria-label="Incident actions"` at line 237, skip-link at line 209 [VERIFIED: grep + file read]
- `brandbook/index.html` — Brand voice formula at line 253: "symptom → measured evidence → likely correlation → safe next action → where to inspect" [VERIFIED: grep]
- `.planning/phases/47-component-groups-meta-components/47-CONTEXT.md` — All 18 locked decisions D-01..D-18 [VERIFIED: full file read]

### Secondary (MEDIUM confidence — cited from planning docs)

- `.planning/REQUIREMENTS.md` — GROUP-01..06, A11Y-05, MOTION-03 requirement definitions [VERIFIED: file read]
- `.planning/phases/45-primitive-components/45-RESEARCH.md` — Precedent structure, demo-mirror sync protocol, contrast test extension patterns
- `.planning/phases/46-navigation-shell-data-display/46-RESEARCH.md` — Precedent structure, `@detail_template_paths` test group pattern
- `.planning/phases/46-navigation-shell-data-display/46-VALIDATION.md` — VALIDATION.md structure and shape precedent

### Tertiary (LOW confidence — N/A for this research)

No external web sources required. All findings are derived from codebase inspection and CONTEXT.md decisions.

---

## Metadata

**Confidence breakdown:**
- Current code state / line numbers: HIGH — every location verified by reading actual files
- CSS keyframe auto-fire mechanism: MEDIUM (tagged [ASSUMED]) — behavior is CSS spec but not exercised in the codebase yet; risk is negligible (no functional regression if wrong)
- WCAG 2.4.11 C43 technique (scroll-padding-bottom): MEDIUM (tagged [ASSUMED]) — well-documented WCAG technique; exact pixel value is Claude's Discretion
- Test assertion patterns: HIGH — existing test helpers verified; new assertions follow exact same patterns

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 (stable Elixir/Phoenix project; template structure is stable; brand voice formula locked)
