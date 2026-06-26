# Phase 47: Component groups / meta-components - Pattern Map

**Mapped:** 2026-06-26
**Files analyzed:** 5 (2 templates, 2 demo mirrors, 1 test file)
**Analogs found:** 5 / 5 — all changes are additive to files that already contain their own best analog

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | template/component | request-response (stateless render) | Self — `severity_color/1`, `state_color/1`, `chip_class/2`, `control_base()`, `prefers-reduced-motion` block | exact (additive to same file) |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | demo mirror | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact byte-mirror |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | live view shell | request-response | Self — existing `<main id="parapet-main">` element at ≈line 224 | exact (one-class addition) |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex` | demo mirror | request-response | `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | exact byte-mirror |
| `test/parapet/operator_ui_contrast_test.exs` | test | batch (file-content assertion loop) | Self — existing `@component_paths` and `@detail_template_paths` test loops (lines 92–210) | exact (additive assertions) |

---

## Pattern Assignments

### 1. `@keyframes po-preview-reveal` + `.po-preview-reveal` CSS (MOTION-03, D-13)

**Analog:** Existing `prefers-reduced-motion` block in `operator_theme_bootstrap/1` `<style>`,
`priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 466–478, and motion token
declarations at lines 109–111.

**Motion token declarations — lines 109–111:**
```elixir
--motion-fast: 120ms;
--motion-base: 200ms;
--motion-ease: cubic-bezier(.2, 0, 0, 1);
```

**Existing reduced-motion block (analog for placement and comment convention) — lines 466–478:**
```css
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-fast: 0ms;
    --motion-base: 0ms;
  }
  /* DATA-06: animate-pulse skeleton is zeroed here — no new motion rule needed */
  .parapet-ui * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto;
    transition-duration: 0.01ms !important;
  }
}
```

**New CSS to insert after line 478 (before `</style>`):**
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

/* MOTION-03: preview_panel reveal — compositor-only props; auto-fires on LiveView DOM insert.
   prefers-reduced-motion block above sets animation-duration: 0.01ms !important — no new rule needed. */
.parapet-ui .po-preview-reveal {
  animation: po-preview-reveal var(--motion-base) var(--motion-ease) both;
}
```

**Placement rule:** Insert in the base `.parapet-ui` block scope, after the `prefers-reduced-motion`
block — NOT inside the `html[data-parapet-theme="dark"]` block. Opacity + transform are
theme-independent; no dark override required.

---

### 2. `[aria-disabled="true"]` CSS rule (D-09)

**Analog:** `control_base()` return value at
`priv/templates/parapet.gen.ui/operator_components.ex.eex` line 1392–1394 (the `disabled:opacity-50
disabled:cursor-not-allowed disabled:pointer-events-none` Tailwind utilities), and the
`aria-disabled` attribute already present in `operator_live` pagination (confirmed by D-09 and the
existing contrast test `assert content =~ "aria-disabled"` at line 233 of the test).

**Existing `control_base()` — line 1392–1394 (the visual precedent to match):**
```elixir
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-[--motion-fast] ease-out active:scale-[0.96] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none"
end
```

**New CSS rule (add to `operator_theme_bootstrap/1` `<style>` block, near `control_base` definitions):**
```css
/* D-09: shown-but-unavailable controls — matches control_base() :disabled visual,
   keeps element in tab order so AT users can discover and hear the reason. */
.parapet-ui [aria-disabled="true"] {
  opacity: 0.5;
  cursor: not-allowed;
  pointer-events: none;
}
```

**Markup usage pattern (add `aria-disabled` attribute to shown-but-unavailable `<button>`):**
```heex
<button
  aria-disabled={if condition_not_met?, do: "true", else: nil}
  phx-click="some_action"
  class={control_class(:recovery)}
>
  Action Label
</button>
```

---

### 3. `action_item_risk/1` helper + risk/audit chips in `action_item_card/1` (D-07, D-08)

**Analog:** `severity_color/1` and `state_color/1` at
`priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1449–1459 — identical pattern of
private `defp` clauses matching on a string value and returning a CSS class string (or atom for
downstream `chip_class/2` lookup).

**Existing `severity_color/1` + `state_color/1` — lines 1449–1459 (copy the clause structure):**
```elixir
defp state_color("open"),          do: "po-chip po-chip-danger"
defp state_color("acknowledged"),  do: "po-chip po-chip-warning"
defp state_color("investigating"), do: "po-chip po-chip-info"
defp state_color("resolved"),      do: "po-chip po-chip-success"
defp state_color(_),               do: "po-chip"

defp severity_color("critical"), do: "po-chip po-chip-danger"
defp severity_color("high"),     do: "po-chip po-chip-danger"
defp severity_color("medium"),   do: "po-chip po-chip-warning"
defp severity_color("low"),      do: "po-chip po-chip-success"
defp severity_color(_),          do: "po-chip"
```

**Existing `chip_class(:execution, :executed)` — lines 1408–1410 (reuse for audit-outcome chip):**
```elixir
defp chip_class(:execution, :executed),
  do:
    "po-chip po-chip-success rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"
```

**New helpers to add after `action_item_card/1` (pattern-match the `severity_color` clause style):**
```elixir
defp action_item_risk("dead_letter"),         do: :danger
defp action_item_risk("orphaned_callback"),   do: :warning
defp action_item_risk("stalled_workflow"),    do: :warning
defp action_item_risk("suppressed_delivery"), do: :info
defp action_item_risk("exact_follow_up"),     do: :neutral
defp action_item_risk(_),                     do: :neutral

defp risk_chip_class(:danger),  do: "po-chip-danger"
defp risk_chip_class(:warning), do: "po-chip-warning"
defp risk_chip_class(:info),    do: "po-chip-info"
defp risk_chip_class(_),        do: ""

defp risk_label(:danger),  do: "High risk"
defp risk_label(:warning), do: "Medium risk"
defp risk_label(:info),    do: "Low risk"
defp risk_label(_),        do: "Routine"

defp audit_outcome_chip_class("resolved"),
  do: chip_class(:execution, :executed)

defp audit_outcome_chip_class(_state),
  do: "po-chip rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide"

defp audit_outcome_label("resolved"), do: "Resolved · audited"
defp audit_outcome_label(_state),     do: "Pending"
```

**Existing `action_item_card/1` markup — lines 1316–1336 (the block to extend with chips):**
```heex
<div class={surface_class(:action_card)}>
  <div class="flex justify-between items-start mb-2">
    <h4 class="text-sm font-medium text-stone-900"><%= @item.title || "Action Item" %></h4>
    <span class={["rounded-full px-2.5 py-1 text-xs font-semibold", state_color(@item.state)]}>
      <%= @item.state %>
    </span>
  </div>
  <p class="text-xs text-stone-500 mb-3"><%= @item.integration %>:<%= @item.external_id %></p>
  ...
```

**Updated header row — add risk chip alongside the existing state chip:**
```heex
<div class="flex justify-between items-start mb-2">
  <h4 class="text-sm font-medium text-stone-900"><%= @item.title || "Action Item" %></h4>
  <div class="flex items-center gap-1.5">
    <%# D-07: risk chip — color + icon + label, never color alone (WCAG 1.4.1) %>
    <span class={["po-chip rounded px-1.5 py-0.5 text-xs font-semibold uppercase tracking-wide flex items-center gap-1", risk_chip_class(action_item_risk(@item.kind))]}>
      <%# SVG icon at executor's discretion (aria-hidden="true") %>
      <%= risk_label(action_item_risk(@item.kind)) %>
    </span>
    <%# D-08: audit-outcome chip — derived honestly from state %>
    <span class={audit_outcome_chip_class(@item.state)}>
      <%= audit_outcome_label(@item.state) %>
    </span>
  </div>
</div>
```

---

### 4. `preview_panel/1` — `.po-preview-reveal` class + `role="region"` + `aria-label` (D-03, D-13)

**Analog:** The existing two-`<div>` outer structure of `preview_panel/1` at
`priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1169–1170.

**Current lines 1169–1170:**
```heex
<div class="fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
```

**Updated lines 1169–1170 (add `.po-preview-reveal` to outermost, `role`/`aria-label` to inner):**
```heex
<div class="po-preview-reveal fixed inset-x-0 bottom-0 z-50 p-4 md:relative md:inset-auto md:p-0 md:mb-6">
  <div role="region" aria-label="Recovery Preview"
       class="bg-white ring-1 ring-[color:var(--parapet-border)] rounded-xl shadow-xl overflow-hidden">
```

**Placement rule for `.po-preview-reveal`:** outermost `<div>` (line 1169) — the positioning
container. Not the inner content `<div>`. The animation runs on the entire positioned block, giving
a unified lift-up reveal without repositioning the content card.

**What NOT to add:** Do NOT add `role="dialog"`, `aria-modal`, or `aria-expanded`. This remains
ARIA Disclosure pattern, not Dialog. The negative-guard tests enforce this.

---

### 5. `incident_summary/1` brand-voice re-author (D-10, D-11)

**Analog:** The existing `incident_summary/1` body at
`priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 810–928. No structural change to
data access — all `@detail.*` and `@detail.derived.*` accesses remain identical.

**Current three-card structure (lines 812–925):**
- Card 1 (lines 812–821): Header block — incident title, ID, state badge
- Card 2 (lines 823–889): Amber escalation card — "Escalation Status" / "Next Step"
- Card 3 (lines 891–925): Two-column grid — "Top Facts" / "Observability"

**Current labels to rename (D-11 verbatim):**
```
"Impact Summary"    → "What users are seeing"     (line 824)
"Escalation Status" → "Escalation status"          (line 833, sentence case only)
"Next Step"         → "Safe next step"             (line 873)
"Top Facts"         → "Evidence on record"         (line 893)
"Observability"     → "Where to inspect"           (line 905)
```

**Current fallback strings to rewrite (D-11 verbatim):**
```
"No impact summary recorded."      → "No user-facing impact has been recorded yet."   (line 826)
"No external links attached."      → "No trace or external links are attached to this incident yet."  (line 921)
```

**`break-words` precedent (already present at line 815 — shows the pattern):**
```heex
<h1 class="max-w-xs whitespace-normal break-words text-2xl font-bold ...">
```

**Card-reorder decision (D-10 / open question from RESEARCH.md):** The brand formula is
`symptom → evidence → safe next action → where to inspect`. Current card order places escalation
(safe next action) before evidence/observability. The recommended reorder puts evidence (Top Facts
card) and observability before the escalation card, so the reading order top-to-bottom traces the
formula. This is within D-10 scope ("re-author only the body"). Confirm via gallery walkthrough.

---

### 6. `response_cockpit/1` — `break-words` on `<h2>` (D-06)

**Analog:** `incident_summary/1` `<h1>` at line 815 (verified, already uses `break-words`).

**Current line 561:**
```heex
<h2 class="text-3xl font-semibold text-stone-950 text-balance"><%= @detail.incident.title %></h2>
```

**Updated line 561 (add `break-words` to match line 815 pattern):**
```heex
<h2 class="text-3xl font-semibold text-stone-950 text-balance break-words"><%= @detail.incident.title %></h2>
```

---

### 7. `operator_detail_live.ex.eex` — `scroll-pb-72 md:scroll-pb-0` on `<main>` (D-02)

**Analog:** Existing `<main id="parapet-main" tabindex="-1">` at
`priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` ≈line 224.

**Current ≈line 224:**
```heex
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8">
```

**Updated ≈line 224 (D-02, WCAG 2.4.11 technique C43):**
```heex
<main id="parapet-main" tabindex="-1" class="flex-1 bg-stone-50 px-4 py-6 md:px-8 scroll-pb-72 md:scroll-pb-0">
```

`scroll-pb-72` = 288px — conservative over-estimate for the tallest mobile sheet height. Tune from
gallery walkthrough if needed (see RESEARCH.md Open Question 1). `md:scroll-pb-0` clears the
padding at md+ where the panel is `md:relative md:inset-auto` (inline, not fixed).

---

### 8. `operator_ui_contrast_test.exs` — additive assertions (D-15..D-17)

**Analog:** Existing `@component_paths` test loop, lines 92–191; existing `@detail_template_paths`
test loop, lines 198–210. New assertions follow the exact `assert content =~ "..."` and
`refute content =~ "..."` pattern throughout.

**Existing loop structure to extend (lines 92–95):**
```elixir
test "operator components use semantic tokens for known dark-mode risk surfaces" do
  for path <- @component_paths do
    content = File.read!(path)
    assert content =~ "--po-chip-warning-bg"
    ...
```

**New assertions to add inside the `@component_paths` loop (Wave 47-01, all RED until 47-02):**
```elixir
# GROUP-01: cockpit <h2> overflow hardening (D-06)
assert content =~ "break-words"

# GROUP-02: brand-voice formula labels (D-11)
assert content =~ "What users are seeing"
assert content =~ "Evidence on record"
assert content =~ "Where to inspect"
assert content =~ "Safe next step"
assert content =~ "No user-facing impact has been recorded yet."
assert content =~ "No trace or external links are attached to this incident yet."
# Old labels absent — use positive-assert approach only for "Observability"
# (word may appear in comments/helpers — RESEARCH.md Pitfall 3)
refute content =~ "Impact Summary"
refute content =~ "Top Facts"

# GROUP-03/05/06 + A11Y-05: N/A negative-guards (D-16)
refute content =~ ~S|role="dialog"|
refute content =~ "aria-modal"
# Guard for full-screen scrim only — preview_panel uses "fixed inset-x-0 bottom-0" (different string)
refute content =~ ~S|class="fixed inset-0|
assert content =~ "md:relative md:inset-auto"
# Close button already passing — no new assertion needed:
# assert content =~ ~S|aria-label="Close Recovery Preview"|

# A11Y-05: Disclosure shape confirmed (D-03)
assert content =~ ~S|role="region"|
assert content =~ ~S|aria-label="Recovery Preview"|

# GROUP-04: risk helper + audit-outcome + aria-disabled rule (D-07/D-08/D-09)
assert content =~ "action_item_risk"
assert content =~ "Resolved · audited"
assert content =~ ~S|[aria-disabled="true"]|

# MOTION-03: keyframe reveal (D-13)
assert content =~ "@keyframes po-preview-reveal"
assert content =~ "animation: po-preview-reveal var(--motion-base) var(--motion-ease)"
# transition-all refute already passing (line 143); reduced-motion assert already passing (line 123)
```

**New assertion to add inside the `@detail_template_paths` loop (lines 203–210):**
```elixir
# D-02: WCAG 2.4.11 scroll-padding-bottom fix (added to existing "operator detail templates have correct landmarks" test)
assert content =~ "scroll-pb-72"
```

---

## Shared Patterns

### Demo-mirror parity
**Source:** Every template edit (both `operator_components.ex.eex` and `operator_detail_live.ex.eex`)
**Apply to:** Their respective demo mirrors in `examples/demo_app/lib/demo_app_web/live/parapet/`
**Enforcement:** The `@component_paths` and `@detail_template_paths` loops in the contrast test read
BOTH the template and the mirror — any mismatch fails the test. Apply every edit to the mirror in
the same commit.

### CSS block placement (theme bootstrap `<style>`)
**Source:** `operator_theme_bootstrap/1` `<style>` block, currently ending at ≈line 479 with `</style>`.
All new CSS rules (`@keyframes po-preview-reveal`, `.po-preview-reveal`, `[aria-disabled="true"]`)
go in the base block BEFORE the closing `</style>`, after the `prefers-reduced-motion` media query.
No new `html[data-parapet-theme="dark"]` override needed for either rule.

### `defp` helper clause convention
**Source:** `severity_color/1` / `state_color/1` / `chip_class/2` — all multi-clause `defp`
functions with string-match heads, one clause per value, catch-all `_` last.
**Apply to:** `action_item_risk/1`, `risk_chip_class/1`, `risk_label/1`, `audit_outcome_chip_class/1`,
`audit_outcome_label/1`.

### Wave structure (test-first)
Wave 47-01 adds all new assertions to `operator_ui_contrast_test.exs` BEFORE touching templates —
every new assertion should be RED on first run. Wave 47-02 flips them GREEN by making the template
+ mirror edits. This is the established Phase 45/46 cadence; follow it exactly.

---

## No Analog Found

No files lack a close codebase analog. All changes are additive to existing, well-patterned files.

---

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.ui/`, `examples/demo_app/lib/demo_app_web/live/parapet/`, `test/parapet/`
**Files scanned:** 6 (operator_components.ex.eex, operator_detail_live.ex.eex, operator_live.ex.eex, their demo mirrors, operator_ui_contrast_test.exs)
**Pattern extraction date:** 2026-06-26
