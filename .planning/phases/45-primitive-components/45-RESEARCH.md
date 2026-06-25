# Phase 45: Primitive Components - Research

**Researched:** 2026-06-25
**Domain:** Phoenix EEx template re-skin — Tailwind CSS class remediation + semantic CSS class extension
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMP-01 | Buttons (primary/secondary/ghost/destructive/warning) have tokenized, visually distinct rest/hover/active/focus-visible/disabled states in both themes | `control_class/2` function remediation; add `:primary`, `:destructive`, `:ghost` variants; wire `po-focus`; update `control_base()` motion token |
| COMP-02 | Disabled controls are both visually and semantically disabled | Add `disabled` attr to `<button>` elements; `aria-disabled="true"` + `pointer-events-none` on `<a>` links; `opacity-50 cursor-not-allowed` visual |
| COMP-03 | Links meet WCAG AA on their actual surface — watch-blue on light, brightened `#7FB4C6` on dark | `.po-link` already wired to `--po-link` token (already correct); verify no hard-coded link colors remain |
| COMP-04 | Badges, chips, and status pills use the brand status triplets and remain legible (AA) in dark mode | `chip_class/2` and `state_color/1` functions already return `.po-chip` semantic classes; fix `escalation_chain_status_class/1` raw `border-amber-*` uses |
| COMP-05 | Stat/metric cards use the metric type tokens and carry no spurious hover/pointer affordance | Verify `text-stone-950` on stat numbers is intercepted; add `cursor-default` on non-interactive card containers if missing |
| COMP-06 | Every interactive primitive shows a visible `:focus-visible` ring using limestone ring on dark surfaces | Replace `focus:ring-teal-300`, `focus:ring-indigo-300`, `focus:ring-emerald-300`, `focus:ring-amber-300` with `po-focus` on all buttons |
| COMP-07 | Icons, dividers, and separators follow border-over-shadow philosophy with tokenized borders | `bg-stone-200` on timeline spine intercepted (verify); fix `suspect_changes_card` and `runbook_card` icon/info badges |
| COMP-08 | No off-palette/raw-Tailwind hex remains in the templates for color (gate-enforced) | 17-item remediation inventory fully catalogued in UI-SPEC.md; three templates + demo mirrors must be updated |
| FORM-01 | Theme switcher and action-confirmation inputs have tokenized states, accessible labels, and AA-contrast focus indicators | Fix `color: #042f2e` raw hex at line 378; `theme_control` buttons already carry `po-focus` and `po-theme-option` |
| FORM-02 | Form/confirmation controls expose correct accessible names and error/disabled states (not color-only) | Verify `role="group" aria-label="Operator color theme"` present; add `aria-disabled` to relevant action buttons |
| A11Y-02 | All text meets 4.5:1 (3:1 for large text) and UI components/graphics meet 3:1 in both themes | Extend contrast test to assert new button/chip/metric token pairings; all six chip triplets already passing |
| MOTION-02 | Hover/press micro-interactions are fast (~120ms) and purposeful, no `transition-all` thrash | Replace `duration-100` with `duration-[--motion-fast]` in `control_base()` and all standalone button `class=` strings; scan for `transition-all` |
</phase_requirements>

---

## Summary

Phase 45 is a surgical re-skin of existing Phoenix HEEx function components — not a rebuild. The core architectural work is two-part: (1) remediating 17 specific off-palette color utility occurrences across three EEx templates (and their byte-mirror counterparts in `examples/demo_app/`), and (2) extending the CSS class ruleset in `operator_theme_bootstrap/1` with five new semantic classes (`.po-guidance`, `.po-timeline-badge-operator`, `.po-timeline-badge-copilot`, `.po-timeline-badge-external`, `.po-queue-row-selected`) plus three new `--po-button-*` CSS variable sets for the `:destructive`, `:success`, and updated `:primary` variants.

Phase 44 completed all token variable values and built the verification apparatus (contrast test, demo-contract test, gallery route, audit matrix). Phase 45 does NOT change any CSS variable values — it only adds new CSS class rules and replaces class strings in component markup. The brand token system is complete; this phase applies it.

The critical constraint is byte-parity: every change to `priv/templates/parapet.gen.ui/operator_components.ex.eex` must be mirrored identically to `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex`. Secondary templates (`operator_live.ex.eex`, `operator_detail_live.ex.eex`) and their mirrors also have pending stubs from Phase 44 that this phase must clear.

**Primary recommendation:** Process all re-skin changes in logical groups (button variants, chip/badge, icons/dividers, theme switcher, motion token) and apply each group to BOTH template + demo mirror in a single commit. Run `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs` after each group.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| CSS variable definitions (tokens) | Template inline `<style>` (`operator_theme_bootstrap/1`) | — | Phase 44 completed; no changes in Phase 45 |
| Semantic CSS class rules (new `.po-*` classes) | Template inline `<style>` (`operator_theme_bootstrap/1`) | Demo mirror (byte-identical) | All new class rules must live in the theme bootstrap to support dark-mode switching |
| Button variant class strings (`control_class/2`) | EEx template Elixir function bodies | Demo mirror Elixir function bodies | Functions return class strings; must update both files |
| Chip/badge class strings (`chip_class/2`, `state_color/1`, etc.) | EEx template private Elixir functions | Demo mirror | Already uses `.po-chip` system; fix remaining raw-class gaps |
| Icon badge classes (`timeline_entry_badge_class/1`) | EEx template private functions | Demo mirror | Currently returns `bg-indigo-700`, `bg-violet-700`, `bg-slate-700` — must replace |
| Off-palette classes in secondary templates | `operator_live.ex.eex`, `operator_detail_live.ex.eex` | Their demo mirrors | Queue-refresh button, pagination link hover, back-link hover — deferred stubs from Phase 44 |
| Motion token wiring (`control_base()`) | EEx template `control_base/0` private function | Demo mirror | Replace `duration-100` with `duration-[--motion-fast]` |
| WCAG AA verification | `test/parapet/operator_ui_contrast_test.exs` | — | Add new button/icon pairings to the existing contrast test |
| Off-palette-hex gate (preview) | Grep scan of template files | — | Phase 50 GUARD-04 builds the gate; Phase 45 must leave no violations for it to catch |

---

## Standard Stack

No new library or package dependencies for Phase 45. The entire implementation uses:

- Phoenix HEEx (already a project dependency) [VERIFIED: actual project dependency in mix.exs]
- Tailwind CSS (already compiled into demo app) [VERIFIED: present in demo app assets config]
- ExUnit (already the test framework) [VERIFIED: used in existing test files]
- CSS Custom Properties (native browser feature, no dependency) [VERIFIED: already used throughout operator_theme_bootstrap/1]

**Installation:** No `mix deps.get` or `npm install` needed for Phase 45.

---

## Package Legitimacy Audit

No external packages are introduced in Phase 45. This section is N/A.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | N/A |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious SUS:** none

---

## Architecture Patterns

### System Architecture Diagram

```
[operator_components.ex.eex] ──generates──> [host: operator_components.ex]
        |                                              |
        |── <style> block ──────────────────────────> CSS vars + new .po-* class rules
        |── control_class/2 functions ──────────────> class strings for buttons
        |── chip_class/2 / state_color/1 ───────────> class strings for chips/badges
        |── timeline_entry_badge_class/1 ───────────> class strings for icon badges
        |── markup EEx blocks ──────────────────────> component HTML
        |
        └── demo mirror must be byte-identical ──> [demo_app/operator_components.ex]

[operator_live.ex.eex] ──(stubs to fix)──> queue-refresh button, pagination links
[operator_detail_live.ex.eex] ──(stubs to fix)──> back-link hover

[test/operator_ui_contrast_test.exs] reads @component_paths (BOTH files)
[test/operator_ui_demo_contract_test.exs] reads router + font/matrix assertions
[gallery_live.ex] renders all 19 components from demo mirror ──> visual audit surface
```

### Recommended File Edit Order

Process in this order to respect logical dependencies:

```
Wave 1 (independent):
  1. operator_components.ex.eex — CSS block: add new .po-* rules + new --po-button-* vars
  2. operator_components.ex.eex — Elixir: fix control_class/2, control_base(), timeline_entry_badge_class/1
  3. operator_components.ex.eex — markup: fix suspect_changes_card, runbook_card, preview_panel inline classes
  4. operator_live.ex.eex + operator_detail_live.ex.eex — fix secondary template stubs
  
  For each above: apply IDENTICAL changes to its demo mirror immediately after.

Wave 2 (depends on Wave 1):
  5. operator_ui_contrast_test.exs — extend @themes + new assertions for button variants
  6. Manual gallery walkthrough: mark audit matrix cells done/verified
```

### Pattern 1: Semantic Class Extension in `operator_theme_bootstrap/1`

**What:** New `.po-*` CSS class rules added inside the existing `<style>` block, using variables that already exist in the light/dark theme blocks.
**When to use:** For any re-skin that needs dark-mode switching (all cases).

```elixir
# Source: existing .po-button-warning pattern (line 356-363 of operator_components.ex.eex)
# Apply this pattern for new classes:

.parapet-ui .po-button-primary {
  background: var(--parapet-text);
  color: var(--parapet-panel);
}
.parapet-ui .po-button-primary:hover {
  background: var(--parapet-text-muted);
}

.parapet-ui .po-button-destructive {
  background: var(--po-button-destructive-bg);
  color: var(--po-button-destructive-fg);
}
.parapet-ui .po-button-destructive:hover {
  background: var(--po-button-destructive-hover);
}
```

**Pattern for new CSS variables** (must also add to BOTH dark blocks):
```css
/* Light block (.parapet-ui): */
--po-button-primary-bg: var(--parapet-text);
--po-button-primary-fg: var(--parapet-panel);
--po-button-primary-hover: var(--parapet-text-muted);
--po-button-destructive-bg: #B13A32;
--po-button-destructive-fg: #FFFFFF;
--po-button-destructive-hover: #8C2E27;
--po-button-success-bg: #567236;
--po-button-success-fg: #FFFFFF;
--po-button-success-hover: #3F5E28;
--po-button-ghost-bg: transparent;
--po-button-ghost-fg: var(--parapet-accent);
--po-button-ghost-hover-bg: var(--parapet-accent-soft);

/* Dark blocks (both [data-parapet-theme="dark"] AND @media prefers-color-scheme: dark): */
--po-button-primary-bg: var(--parapet-text);    /* limestone in dark = #F8F4EC */
--po-button-primary-fg: var(--parapet-panel);   /* wall-slate in dark = #2E3A42 */
--po-button-primary-hover: var(--parapet-text-muted); /* #D8D0C3 */
/* destructive, ghost stay same in dark */
--po-button-success-bg: #EFF6E8;               /* inverted: light fg becomes dark bg */
--po-button-success-fg: #101820;               /* parapet-black as fg on light success-bg */
--po-button-success-hover: #3F5E28;            /* healthy-text as hover bg */
```

### Pattern 2: `control_class/2` Function Replacement

**What:** Private Elixir function returning a string of Tailwind class names. Replace raw color utilities with semantic `.po-button-*` classes.

```elixir
# Source: operator_components.ex.eex lines 1258-1284 (VERIFIED: file read)
# Current (off-palette):
defp control_class(:recovery, width),
  do: control_width(width) <> " " <> control_base() <>
      " bg-indigo-600 text-white hover:bg-indigo-700 focus:ring-indigo-300"

# Replace with (tokenized):
defp control_class(:primary, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-primary"

defp control_class(:recovery, width),
  do: control_width(width) <> " " <> control_base() <>
      " bg-[color:var(--parapet-accent)] text-white hover:bg-[color:var(--parapet-accent-strong)] po-focus"

# Or use a .po-button-recovery CSS class (same pattern as po-button-warning)
```

**`control_base()` motion token fix:**
```elixir
# Current (line 1283-1285 — VERIFIED):
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-100 ease-out active:scale-[0.96] focus:outline-none focus:ring-2"
end

# Replace duration-100 → duration-[--motion-fast]:
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-[--motion-fast] ease-out active:scale-[0.96] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
end
```

Note: `focus:ring-offset-2` and `po-focus` are added to `control_base()` so all button variants automatically get the correct focus ring. Remove `po-focus` from individual variant strings if moved here.

### Pattern 3: Demo Mirror Sync (Critical — D-04 / D-16)

**What:** `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` is a hand-maintained mirror of the template. Every CSS class change and every Elixir function body change must be applied identically.

**Verification:**
```bash
# After each change, diff the CSS blocks:
diff <(grep -o '\.po-[a-z-]*' priv/templates/parapet.gen.ui/operator_components.ex.eex | sort -u) \
     <(grep -o '\.po-[a-z-]*' examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex | sort -u)
# Should output nothing if byte-identical on class names.
```

### Pattern 4: Secondary Template Stub Remediation

**What:** `operator_live.ex.eex` and `operator_detail_live.ex.eex` carry 3 deferred stubs from Phase 44 (VERIFIED: 44-02-SUMMARY.md "Known Stubs"):

| File | Line | Current | Fix |
|------|------|---------|-----|
| `operator_live.ex.eex` | ~211 | `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300` (queue-refresh button) | Replace with `control_class(:primary)` (or inline tokenized classes) + `po-focus` |
| `operator_live.ex.eex` | ~469 | `hover:ring-teal-700 hover:text-teal-700` (pagination link hover) | Replace hover with `hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]` |
| `operator_detail_live.ex.eex` | ~211 | `text-teal-800 hover:text-teal-950` (back-link) | Replace with `po-link` (already sets `var(--po-link)` and hover `var(--po-link-hover)`) |

Each of these must also be mirrored to the demo counterpart.

### Pattern 5: Timeline Badge Class Replacement

**What:** `timeline_entry_badge_class/1` returns raw background color utilities. Replace with new semantic classes defined in the theme bootstrap.

```elixir
# Source: operator_components.ex.eex lines 1474-1478 (VERIFIED: file read)
# Current:
defp timeline_entry_badge_class(%{actor_class: :operator}), do: "bg-indigo-700"
defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "bg-violet-700"
defp timeline_entry_badge_class(%{actor_class: :external}), do: "bg-slate-700"

# Replace with:
defp timeline_entry_badge_class(%{actor_class: :operator}), do: "po-timeline-badge-operator"
defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "po-timeline-badge-copilot"
defp timeline_entry_badge_class(%{actor_class: :external}), do: "po-timeline-badge-external"
```

**New CSS rules to add to theme bootstrap:**
```css
.parapet-ui .po-timeline-badge-operator {
  background: var(--parapet-accent);  /* watch-blue light / #7FB4C6 dark */
  color: #FFFFFF;
}
.parapet-ui .po-timeline-badge-copilot {
  background: var(--parapet-info-bg); /* #ECEBFF light / rgba dark */
  color: var(--parapet-info-text);    /* #4F46A5 light / #B9B5F6 dark */
}
.parapet-ui .po-timeline-badge-external {
  background: var(--parapet-text-muted);  /* #2E3A42 light / #D8D0C3 dark */
  color: var(--parapet-panel);            /* white light / wall-slate dark */
}
```

Note: For the `copilot` badge, using `var(--parapet-info-bg)` as bg with `var(--parapet-info-text)` as fg gives the AI/trace-violet semantic that `.po-chip-info` uses. The badge text ("AI") is white in the current template — but `po-chip-info` uses colored text on colored bg. The planner must choose: (a) dark solid bg like operator badge (`var(--parapet-info-text)` as bg, white text) or (b) light chip style. The UI-SPEC says "Replace with `var(--parapet-info-bg)` pattern" — lean toward option (b).

### Anti-Patterns to Avoid

- **Adding new CSS variable values to the dark blocks:** Phase 45 only adds new class RULES and new variable DECLARATIONS in the light block. Variable values were locked in Phase 44. Exception: new `--po-button-destructive-*` and `--po-button-success-*` vars do need dark overrides.
- **Using `transition-all`:** Prohibited by MOTION-02. Always use `transition-transform` for press effects and `transition-colors` for color effects, never both in one `transition-all`.
- **Modifying `.po-chip` CSS rules:** The six `.po-chip-*` rules are already correct and GUARD-02 verified. Do not touch them.
- **Changing CSS variable values in any of the three theme blocks:** Values are locked. Phase 45 adds class rules only.
- **Adding the gallery route to `router_snippet.ex.eex`:** Gallery is demo-only — D-13 hard boundary.
- **Using `aria-disabled` on `<button>` elements:** Buttons use native `disabled` attribute. `aria-disabled` is for `<a>` link-styled elements only.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark-mode color switching | Per-component JS or data attribute toggling | Existing CSS custom property system (`data-parapet-theme` + CSS vars in `operator_theme_bootstrap/1`) | Already shipped Phase 44; all three dark blocks update automatically |
| Contrast verification | Manual math or external tool | `operator_ui_contrast_test.exs` with `contrast_ratio/2` + `relative_luminance/1` helpers | These helpers are already implemented and tested |
| Off-palette detection | Manual grep per dev | Phase-50 GUARD-04 gate (future); for now, `mix test` + manual grep `grep -r '#[0-9a-fA-F]\{3,6\}' priv/templates/` | Gate built in Phase 50; run grep during Phase 45 verification |
| Focus ring CSS | Inline `focus:ring-{color}-{n}` utilities | `.po-focus` class + `focus:ring-2 focus:ring-offset-2` Tailwind utilities | `.po-focus` sets `--tw-ring-color` from `--po-focus` token, handles both themes |
| Status color logic | Custom if/else color logic | `chip_class/2`, `state_color/1`, `severity_color/1`, `journey_color/1` functions — already implemented | These already return `.po-chip po-chip-*` semantic classes |

**Key insight:** The existing CSS interception layer (`.parapet-ui .bg-stone-50 { background-color: var(...) }`) handles Tailwind utilities that can't be updated (because they're too generic). For utilities that CAN be replaced (color-specific ones like `bg-indigo-600`), Phase 45 replaces them with either inline `var()` expressions or new semantic `.po-*` classes.

---

## Common Pitfalls

### Pitfall 1: Missing Dark-Block Sync on New CSS Variables

**What goes wrong:** A new `--po-button-destructive-bg` variable added to the light block is not added to both dark blocks, so dark mode falls back to an undefined value or the light value.
**Why it happens:** The template has THREE blocks to update (light, explicit dark, media-query dark). D-04 is the highest-risk drift point.
**How to avoid:** After adding variables to the light block, immediately copy them to BOTH dark blocks in the same edit. Write a grep check: `grep -c "po-button-destructive-bg" operator_components.ex.eex` should return ≥ 3 (one per block).
**Warning signs:** Dark mode shows wrong colors; `mix test operator_ui_contrast_test.exs` catches explicit hex assertions but not CSS variable values.

### Pitfall 2: Demo Mirror Divergence

**What goes wrong:** Template updated, demo mirror not updated (or vice versa). Gallery shows different rendering than the generated code.
**Why it happens:** The EEx template and the `.ex` demo mirror are manually synced — no automatic diff gate until Phase 50 (GUARD-03).
**How to avoid:** Always edit template and demo mirror in the same commit. The contrast test reads `@component_paths` which includes both — string assertions catching class names serve as a partial parity check.
**Warning signs:** `mix test operator_ui_contrast_test.exs` passes but gallery renders differently from what the template would produce.

### Pitfall 3: `focus:ring-offset-2` Missing on Buttons

**What goes wrong:** Adding `po-focus` class and `focus:ring-2` but omitting `focus:ring-offset-2`. The ring renders without a gap between the button edge and the ring, making it harder to see.
**Why it happens:** The UI-SPEC focuses on ring color; the offset is easy to miss.
**How to avoid:** The updated `control_base()` should include `focus:ring-offset-2` to make the 2px offset universal. Verify the `.po-focus` class sets `--tw-ring-offset-color: var(--po-focus-offset)`.
**Warning signs:** Focus rings appear as a solid border rather than a ring-with-gap.

### Pitfall 4: Raw `#042f2e` Hex Surviving in CSS Rule

**What goes wrong:** Line 378 of `operator_components.ex.eex` contains `color: #042f2e;` inside a CSS rule for dark `aria-pressed="true"`. This is the only off-palette hex inside a CSS rule block (not a variable value). Phase 50 GUARD-04 will flag it.
**Why it happens:** This is inside a CSS rule block at line 377-379, not in a markup class attribute, so standard Tailwind color searches miss it.
**How to avoid:** Explicitly grep for `#042f2e` in the template. Replace with `color: var(--po-nav-active-fg);`.
**Warning signs:** GUARD-04 gate failure in Phase 50; dark mode theme switcher selected button shows teal-black text instead of limestone.

### Pitfall 5: `transition-all` Thrash (MOTION-02 Violation)

**What goes wrong:** A button uses `transition-all` which applies the transition to opacity, layout, color, AND transform simultaneously, causing janky repaints.
**Why it happens:** Developers often reach for `transition-all` as the "safe" catch-all.
**How to avoid:** `control_base()` uses `transition-transform` (not `transition-all`). For color transitions on links/nav, use `transition-colors`. Never use `transition-all` in this codebase.
**Warning signs:** Grep for `transition-all` in template files — should return 0 results.

### Pitfall 6: `duration-100` Not Replaced by `duration-[--motion-fast]`

**What goes wrong:** The `control_base()` function at line 1284 and three standalone button `class=` strings at lines 609, 954, 1132 all use `duration-100` (hardcoded 100ms). The motion token `--motion-fast` is 120ms and must be used consistently. Under `prefers-reduced-motion`, `duration-[--motion-fast]` reads `0ms` automatically; `duration-100` does not.
**Why it happens:** These standalone buttons were not extracted into `control_class/2` — they have inline class strings with `duration-100`.
**How to avoid:** Replace ALL four occurrences:
  - Line 1284: `control_base()` function
  - Line 609: "Return to response" button in `action_center/1`
  - Line 954: "Copy retrospective" button in `retrospective_card/1`
  - Line 1132: "Back to history" link in `action_rail/1`
**Warning signs:** Buttons don't respect `prefers-reduced-motion` because `duration-100` is a fixed Tailwind class.

### Pitfall 7: `po-focus` Added to `control_base()` But Also on Individual Variants

**What goes wrong:** If `po-focus` moves into `control_base()`, and individual `control_class/2` variants also include `po-focus`, it appears twice in the class string (harmless but messy and signals an error in thinking).
**How to avoid:** Decide once: put `po-focus` in `control_base()` and remove from individual variants. Or keep it out of `control_base()` and put it on each variant. The UI-SPEC pattern puts it in `control_base()`.

### Pitfall 8: Standalone "Primary-tier" Buttons Not Migrated to `control_class(:primary)`

**What goes wrong:** The three standalone navigation buttons at lines 609 (action_center "Return to response"), 954 (retrospective_card "Copy retrospective"), 1132 (action_rail "Back to history") use `bg-stone-950 text-white hover:bg-stone-800` inline. These are intercepted by the stone interception rules but they still read as explicit stone-950 (which happens to map correctly). The UI-SPEC maps them to `control_class(:primary)` using `var(--parapet-text)`.
**How to avoid:** Replace all three with `control_class(:primary)` or the equivalent inline token expression. This also eliminates `duration-100` in one edit per the above pitfall.

---

## Code Examples

### Adding New CSS Variable Group to All Three Blocks

```css
/* Source: operator_components.ex.eex — pattern from po-button-warning (lines 92-94) */
/* Add to light block (.parapet-ui { ... }): */
--po-button-destructive-bg: #B13A32;
--po-button-destructive-fg: #FFFFFF;
--po-button-destructive-hover: #8C2E27;
--po-button-success-bg: #567236;
--po-button-success-fg: #FFFFFF;
--po-button-success-hover: #3F5E28;

/* Add to BOTH dark blocks (byte-identical to each other):
   destructive stays same hex in dark.
   success inverts: */
--po-button-success-bg: #EFF6E8;
--po-button-success-fg: #101820;
--po-button-success-hover: #3F5E28;
```

### Adding New Semantic CSS Class Rules

```css
/* Source: operator_components.ex.eex — pattern from .po-button-warning (lines 356-363) */
/* Add after the .po-button-warning:hover rule: */

.parapet-ui .po-button-primary {
  background: var(--po-button-primary-bg);
  color: var(--po-button-primary-fg);
}
.parapet-ui .po-button-primary:hover {
  background: var(--po-button-primary-hover);
}

.parapet-ui .po-button-destructive {
  background: var(--po-button-destructive-bg);
  color: var(--po-button-destructive-fg);
}
.parapet-ui .po-button-destructive:hover {
  background: var(--po-button-destructive-hover);
}

.parapet-ui .po-button-success {
  background: var(--po-button-success-bg);
  color: var(--po-button-success-fg);
}
.parapet-ui .po-button-success:hover {
  background: var(--po-button-success-hover);
}

.parapet-ui .po-guidance {
  background: var(--parapet-info-bg);
  color: var(--parapet-info-text);
  border: 1px solid var(--parapet-border);
}

.parapet-ui .po-timeline-badge-operator {
  background: var(--parapet-accent);
  color: #FFFFFF;
}

.parapet-ui .po-timeline-badge-copilot {
  background: var(--parapet-info-text);
  color: #FFFFFF;
}

.parapet-ui .po-timeline-badge-external {
  background: var(--parapet-text-muted);
  color: var(--parapet-panel);
}

.parapet-ui .po-queue-row-selected {
  border-left-color: var(--parapet-accent);
  background: var(--parapet-accent-soft);
}
.parapet-ui .po-queue-row-selected:hover {
  background: var(--parapet-accent-soft);
}
```

### `queue_row_class/2` Replacement

```elixir
# Source: operator_components.ex.eex lines 1332-1338 (VERIFIED: file read)
# Current (off-palette):
defp queue_row_class(selected, incident) do
  if selected && selected.id == incident.id do
    "border-l-teal-700 bg-teal-50/80 hover:bg-teal-50"
  else
    "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
  end
end

# Replace with (tokenized):
defp queue_row_class(selected, incident) do
  if selected && selected.id == incident.id do
    "po-queue-row-selected"
  else
    "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
  end
end
```

### `retrospective_card` Copy Button Fix

```html
<!-- Source: operator_components.ex.eex line 954 (VERIFIED: file read) -->
<!-- Current: focus:ring-teal-300 + duration-100 + bg-stone-950 -->
<!-- Replace: -->
<button
  type="button"
  data-content={@retrospective}
  onclick="..."
  class={["flex-shrink-0", control_class(:primary)]}
>
  <span data-copy-label>Copy retrospective</span>
</button>
```

### `preview_panel` Color Fix

```html
<!-- Source: operator_components.ex.eex lines 1058-1063 (VERIFIED: file read) -->
<!-- Current (off-palette): bg-indigo-500 ring-indigo-500, hover:text-indigo-100, bg-indigo-50 ring-indigo-100 text-indigo-900 -->
<!-- Replace: -->
<div class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
  <div class="px-4 py-2 flex justify-between items-center" style="background: var(--parapet-accent);">
    <h3 class="text-sm font-bold text-white uppercase tracking-wider">Recovery Preview</h3>
    <button type="button" phx-click="cancel_preview" aria-label="Close Recovery Preview"
      class="flex min-h-[40px] min-w-[40px] items-center justify-center rounded-lg text-white hover:opacity-80 focus:outline-none focus:ring-2 focus:ring-white/80">
      ...
    </button>
  </div>
  ...
  <p class="mb-3 rounded-lg px-3 py-2 text-xs ring-1 po-guidance">
    Execute bounded recovery...
  </p>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw Tailwind color utilities (`bg-indigo-600`, `text-emerald-600`) in component class strings | Semantic `.po-*` CSS classes reading from `--po-*` CSS variables | Phase 44 (partial) → Phase 45 (complete) | Dark mode works automatically; no per-component JS |
| `duration-100` hardcoded in button transitions | `duration-[--motion-fast]` token-driven | Phase 45 | Respects `prefers-reduced-motion` automatically |
| Focus rings with hardcoded `focus:ring-teal-300` etc. | `.po-focus` class that reads `--po-focus` / `--po-focus-offset` CSS variables | Phase 44 added `.po-focus` class; Phase 45 applies it to all remaining buttons | Per-surface focus ring (limestone on dark, watch-blue on light) enforced by CSS |

**Deprecated/outdated:**
- `bg-teal-700`, `bg-indigo-600`, `bg-emerald-600`, `bg-violet-700`, `bg-slate-700`: Raw Tailwind color utilities. Replaced in Phase 45 with semantic CSS classes or token expressions.
- `focus:ring-teal-300`, `focus:ring-indigo-300`, `focus:ring-emerald-300`, `focus:ring-amber-300`: Hardcoded focus ring colors. Replaced with `po-focus` + `focus:ring-2 focus:ring-offset-2`.
- `duration-100`: Hardcoded 100ms. Replaced with `duration-[--motion-fast]`.

---

## Runtime State Inventory

Phase 45 is a template re-skin (code/markup edits only). No rename, migration, or data change involved.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None — no data stored for CSS class names | None |
| Live service config | None — template-only changes | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None — no compiled binaries affected | None |

**Nothing found in any category** — verified by nature of the phase (text edits to `.eex` and `.ex` files only).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | Running tests | ✓ | (project already running) | — |
| ExUnit | Contrast + demo-contract tests | ✓ | built-in | — |
| mix test | Test execution | ✓ | standard mix task | — |

No external tools, services, or CLIs needed for Phase 45 beyond the normal Elixir development toolchain.

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

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMP-01 | Button variants tokenized — all rest/hover/active/focus/disabled states in both themes | unit (string search + contrast assert) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ needs new button_bg/fg assertions in @themes |
| COMP-02 | Disabled controls visually and semantically disabled | manual (visual gallery audit) + string search | `grep -c "disabled\|aria-disabled" operator_components.ex.eex` | manual only |
| COMP-03 | Links meet AA on surface — already verified by GUARD-02 | unit (contrast already passing) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ already asserting link_on_panel, link_on_bg |
| COMP-04 | Chips/badges use brand status triplets — already verified by GUARD-02 | unit (contrast already passing) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ all six chip triplets already asserted |
| COMP-05 | Stat/metric cards — no spurious hover/pointer | unit (string search refute) | `refute content =~ "cursor-pointer"` in contrast test | ✅ add as refute assertion in second test |
| COMP-06 | Focus rings visible using po-focus | unit (string search assert) | `assert content =~ "po-focus"` already in contrast test (partially); add count check | ✅ add stronger assertion |
| COMP-07 | Icons, dividers tokenized | unit (string search — no raw bg-purple-100 etc.) | `refute content =~ "bg-purple-100"` in contrast test | ✅ add as refute assertion |
| COMP-08 | No off-palette hex remains | unit (string search refute) | `refute content =~ "bg-indigo-600"`, `refute content =~ "bg-emerald-600"`, `refute content =~ "#042f2e"` in contrast test | ✅ add as refute assertions to second test |
| FORM-01 | Theme switcher tokenized with accessible labels | unit (string search assert) | `assert content =~ ~S|aria-label="Operator color theme"|` (already in second test) | ✅ exists + add po-focus assertion on theme buttons |
| FORM-02 | Form controls — accessible names, error/disabled not color-only | unit (string search) | `assert content =~ ~S|aria-pressed|` | ✅ add as assert |
| A11Y-02 | All text meets 4.5:1 (3:1 large) | unit (extend @themes + assertions) | `mix test test/parapet/operator_ui_contrast_test.exs` | ✅ add new_button_bg/fg pairs to @themes |
| MOTION-02 | No transition-all; duration-[--motion-fast] used | unit (string search) | `refute content =~ "transition-all"` and `assert content =~ "duration-[--motion-fast]"` or `assert content =~ "--motion-fast"` in contrast test | ✅ add as refute/assert to second test |

### New Assertions to Add to `operator_ui_contrast_test.exs`

**Test 1 — `"semantic operator tokens meet contrast minimums"`:**
Add to `@themes` for Phase 45 new button variants:
```elixir
# In light map:
primary_button_bg: "#101820", primary_button_fg: "#FFFFFF",  # parapet-text / panel
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#567236", success_button_fg: "#FFFFFF",

# In dark map:
primary_button_bg: "#F8F4EC", primary_button_fg: "#2E3A42",  # limestone / wall-slate
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#EFF6E8", success_button_fg: "#101820",
```

Add to the for-loop assertions:
```elixir
assert_contrast(theme, :primary_button, tokens.primary_button_fg, tokens.primary_button_bg, 4.5)
assert_contrast(theme, :destructive_button, tokens.destructive_button_fg, tokens.destructive_button_bg, 4.5)
assert_contrast(theme, :success_button, tokens.success_button_fg, tokens.success_button_bg, 4.5)
```

**Test 2 — `"operator components use semantic tokens for known dark-mode risk surfaces"`:**
Add refute assertions to catch Phase 45 violations:
```elixir
# COMP-08: off-palette class remediation
refute content =~ "bg-indigo-600"
refute content =~ "bg-indigo-500"
refute content =~ "bg-indigo-50 ring-indigo-100"
refute content =~ "bg-emerald-600"
refute content =~ "bg-purple-100"
refute content =~ "bg-violet-100"
refute content =~ "bg-blue-50"
refute content =~ "bg-teal-700"
refute content =~ "hover:ring-teal-700"
refute content =~ "#042f2e"

# MOTION-02: no transition-all, duration-[--motion-fast] used
refute content =~ "transition-all"
assert content =~ "duration-[--motion-fast]"

# COMP-06: po-focus on buttons
assert content =~ "po-focus"

# COMP-07: no raw color badge utilities
refute content =~ "bg-purple-100 text-purple-800"
refute content =~ "bg-violet-100 text-violet-800"
```

### New Assertions to Add to `operator_ui_demo_contract_test.exs`

No new assertions needed for Phase 45 (existing GALLERY-01, FONT-03, GUARD-01 assertions remain; GUARD-04 is Phase 50).

### Sampling Rate

- **Per task commit:** `mix test test/parapet/operator_ui_contrast_test.exs test/parapet/operator_ui_demo_contract_test.exs`
- **Per wave merge:** `mix test --exclude unboxed`
- **Phase gate:** `mix test --exclude unboxed` green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] Extend `@themes` in `operator_ui_contrast_test.exs` with primary/destructive/success button pairs (Wave 0 test infrastructure)
- [ ] Add refute/assert assertions for COMP-08/MOTION-02/COMP-06/COMP-07 to second test in `operator_ui_contrast_test.exs`

*(No new test files needed — all assertions are additive to existing files)*

---

## Security Domain

Phase 45 introduces no new network endpoints, authentication paths, user input handling, or data access patterns. All changes are CSS class strings and Elixir private function return values.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | no | Template markup is static; no new user input |
| V6 Cryptography | no | — |

### Known Threat Patterns for Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| XSS via class attribute injection | Tampering | Phoenix HEEx auto-escapes all interpolations; `class={["...", variable]}` is safe |

No new threat surface. Phase 44 threat scan (T-44-01 through T-44-07) remains the applicable baseline.

---

## Off-Palette Hex Remediation: Complete Inventory

This is the authoritative list of all items requiring remediation in Phase 45. Source: 45-UI-SPEC.md + VERIFIED against actual template files.

### In `operator_components.ex.eex` (+ demo mirror `operator_components.ex`):

| # | Location | Current | Fix |
|---|----------|---------|-----|
| 1 | `control_class(:recovery)` (line ~1262) | `bg-indigo-600 text-white hover:bg-indigo-700 focus:ring-indigo-300` | `.po-button-recovery` semantic class (uses `--parapet-accent`) |
| 2 | `control_class(:success)` (line ~1280) | `bg-emerald-600 text-white hover:bg-emerald-700 focus:ring-emerald-300` | `.po-button-success` semantic class |
| 3 | `control_base()` (line ~1284) | `duration-100` (no `ring-offset-2`, no `po-focus`) | `duration-[--motion-fast] focus:ring-offset-2 po-focus` |
| 4 | Inline button (line 609 `action_center`) | `bg-stone-950 text-white ... duration-100 ... hover:bg-stone-800` | `control_class(:primary)` |
| 5 | Inline button (line 954 `retrospective_card`) | `bg-stone-950 ... duration-100 ... focus:ring-2 focus:ring-teal-300` | `control_class(:primary)` |
| 6 | Inline link-as-button (line 1132 `action_rail`) | `bg-stone-950 ... duration-100 ... hover:bg-stone-800` | `control_class(:primary)` |
| 7 | `preview_panel` header (line ~1059) | `bg-indigo-500 ring-indigo-500` | `style="background: var(--parapet-accent)"` + `ring-[color:var(--parapet-border)]` |
| 8 | `preview_panel` close button (line ~1062) | `hover:text-indigo-100` | `hover:opacity-80` |
| 9 | `preview_panel` info block (line ~1097) | `bg-indigo-50 px-3 py-2 text-xs text-indigo-900 ring-1 ring-indigo-100` | `po-guidance px-3 py-2 text-xs ring-1` |
| 10 | `suspect_changes_card` icon badge (line ~899) | `bg-purple-100 text-purple-800` (span wrapping SVG) | `po-chip po-chip-info` |
| 11 | `suspect_changes_card` scope badge (line ~915) | `bg-violet-100 text-violet-800 ring-1 ring-violet-200/50` | `po-chip po-chip-info` |
| 12 | `runbook_card` guidance block (line ~1001) | `bg-blue-50 border border-blue-100 rounded text-xs text-violet-800 italic` | `po-guidance` |
| 13 | Theme CSS rule (line 378) | `color: #042f2e;` | `color: var(--po-nav-active-fg);` |
| 14 | `timeline_entry_badge_class(:operator)` (line ~1475) | `bg-indigo-700` | `po-timeline-badge-operator` |
| 15 | `timeline_entry_badge_class(:copilot)` (line ~1476) | `bg-violet-700` | `po-timeline-badge-copilot` |
| 16 | `timeline_entry_badge_class(:external)` (line ~1477) | `bg-slate-700` | `po-timeline-badge-external` |
| 17 | `queue_row_class/2` selected (line ~1334) | `border-l-teal-700 bg-teal-50/80 hover:bg-teal-50` | `po-queue-row-selected` |

### In `operator_live.ex.eex` (+ demo mirror `operator_live.ex`):

| # | Location | Current | Fix |
|---|----------|---------|-----|
| 18 | Queue-refresh button (line ~211) | `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300 ... duration-100` | `control_class(:primary)` or inline token expression |
| 19 | Pagination link hover (line ~469) | `hover:ring-teal-700 hover:text-teal-700` | `hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]` |

### In `operator_detail_live.ex.eex` (+ demo mirror `operator_detail_live.ex`):

| # | Location | Current | Fix |
|---|----------|---------|-----|
| 20 | Back-link (line ~211) | `text-teal-800 hover:text-teal-950` | `po-link` (replaces both, handles hover via CSS rule) |

**Total: 20 remediation items across 3 templates × 2 (template + mirror) = up to 40 file edits, but most are in operator_components.ex.eex.**

---

## Open Questions

1. **`.po-button-recovery` vs inline `var()` expressions for the recovery button**
   - What we know: `control_class(:warning)` uses a semantic `.po-button-warning` class. The recovery button maps to accent color.
   - What's unclear: Whether to create `.po-button-recovery` CSS class or use inline `bg-[color:var(--parapet-accent)] hover:bg-[color:var(--parapet-accent-strong)]` Tailwind arbitrary value expressions.
   - Recommendation: Create `.po-button-recovery` CSS class matching the pattern of `.po-button-warning`. More consistent; avoids Tailwind arbitrary value syntax which is less readable.

2. **`po-timeline-badge-copilot` color on dark surfaces**
   - What we know: UI-SPEC says use `var(--parapet-info-bg)` pattern. In dark mode, `--parapet-info-bg` is `rgba(109,91,208,0.24)` (semi-transparent). The badge needs solid background for readability.
   - What's unclear: Whether to use `var(--parapet-info-text)` as solid bg (dark: `#B9B5F6`) with white text, or the light chip approach (light bg, colored text).
   - Recommendation: For icon badges (filled circle with letter), use solid bg approach: `background: var(--parapet-info-text)` + `color: var(--parapet-bg)` so it's solid on both themes. This mirrors how `po-timeline-badge-operator` uses `var(--parapet-accent)`.

3. **`operator_live.ex.eex` queue-refresh button accessibility**
   - What we know: This button is a notification-driven refresh trigger (`phx-click="refresh_queue"`). It carries `bg-teal-700 text-white` which is contrast-safe but off-brand.
   - What's unclear: Does this button need a `control_class/2` variant, or is inline replacement sufficient since it's in a different template?
   - Recommendation: Since `operator_live.ex.eex` doesn't import `control_class/2` as a module function (it uses helper functions inline), apply the token expression directly in the class string. Use: `bg-[color:var(--parapet-accent)] text-white hover:bg-[color:var(--parapet-accent-strong)] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus duration-[--motion-fast]`.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `control_class/2` function is available in the demo mirror (`operator_components.ex`) in the same form as the template | Code Examples — Pattern 2 | LOW: The demo mirror is verified byte-equivalent to template per 44-02-SUMMARY.md; functions are identical |
| A2 | `text-stone-950` on stat card numbers is intercepted by existing `.parapet-ui .text-stone-950 { color: var(--parapet-text); }` rule | COMP-05 | LOW: Interception rule is at line 243-246 of template (VERIFIED in file read); stat card numbers use `text-stone-950` which is covered |
| A3 | `bg-stone-50/40` (unselected queue row) is NOT intercepted and will stay as-is | Off-palette inventory | LOW: The interception rule covers `bg-stone-50` but NOT `bg-stone-50/40` (opacity modifier); however this is a neutral stone color that renders acceptably — it is not a signal/accent color, so not a COMP-08 violation |
| A4 | `focus:ring-white/80` on `preview_panel` close button does not need to be replaced with `po-focus` | Code Examples — preview_panel | MEDIUM: The close button is white-on-accent-bg; the current `ring-white/80` is technically a valid ring in that context. If Phase 50 GUARD-04 gate scans for ALL non-token color expressions this may flag. Safe to replace with `focus:ring-2 focus:ring-white/60` (still white) |
| A5 | The `.po-guidance` info text uses `var(--parapet-info-text)` color — sufficient contrast on `var(--parapet-info-bg)` | Anti-Patterns | MEDIUM: Light info: `#4F46A5` on `#ECEBFF` = verified AA by chip test. Dark info: `#B9B5F6` on `rgba(109,91,208,0.24)` — opacity makes bg calculation non-trivial; on `#2E3A42` (panel) blended bg the contrast may be marginal. Verify during wave-2 contrast test extension |

**If this table is empty:** N/A — all non-trivial assumptions are listed above.

---

## Sources

### Primary (HIGH confidence — VERIFIED against actual file contents)

- `priv/templates/parapet.gen.ui/operator_components.ex.eex` — Primary re-skin target; full file read; exact line numbers for all off-palette instances verified
- `examples/demo_app/lib/demo_app_web/live/parapet/gallery_live.ex` — Gallery structure, fixture data, all 19 component render patterns verified
- `test/parapet/operator_ui_contrast_test.exs` — Existing @themes map, assertion patterns, helper functions; exact current test state
- `test/parapet/operator_ui_demo_contract_test.exs` — Existing assertions; what Phase 45 must not disturb
- `.planning/phases/44-*/44-02-SUMMARY.md` — Known stubs inventory (3 items in secondary templates)
- `.planning/phases/44-*/44-04-SUMMARY.md` — Dark warning button fg correction (#101820); WCAG AA fix pattern
- `.planning/phases/45-primitive-components/45-UI-SPEC.md` — Approved design contract; 17-item off-palette inventory; all component state contracts
- `brandbook/tokens/tokens.css` — Token source of truth; all hex values verified

### Secondary (MEDIUM confidence — cited from planning docs)

- `.planning/REQUIREMENTS.md` — 12-requirement definitions; traceability map Phase 45 → COMP-01..08, FORM-01/02, A11Y-02, MOTION-02
- `.planning/ROADMAP.md` — Phase 45 success criteria; Phase 50 GUARD-04 constraint (off-palette gate ships later)
- `.planning/phases/44-*/44-PATTERNS.md` — Architectural patterns for EEx template editing and demo mirror sync

### Tertiary (LOW confidence — N/A for this research)

No external web sources required. All findings are derived from codebase inspection.

---

## Metadata

**Confidence breakdown:**
- File inventory / off-palette items: HIGH — every item verified by reading actual template file
- Token values and CSS class patterns: HIGH — verified against tokens.css and existing theme block
- Test extension patterns: HIGH — existing test helpers verified; new assertions follow exact same patterns
- New CSS variable dark-mode values for button variants: MEDIUM — light values are locked tokens; dark inversion logic for `:success` and `:primary` follows established pattern but planner should verify ratios

**Research date:** 2026-06-25
**Valid until:** 2026-07-25 (stable Elixir/Phoenix project; token values locked by brand book)
