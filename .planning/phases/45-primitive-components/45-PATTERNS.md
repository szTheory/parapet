# Phase 45: Primitive Components - Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 7
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` (CSS block) | template/config | request-response | self — existing `.po-chip-*` / `.po-button-warning` CSS rules (lines 326–363) | exact — additive extension of same selector pattern |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` (Elixir functions) | template/config | request-response | self — existing `control_class/2`, `chip_class/2`, `state_color/1`, `timeline_entry_badge_class/1`, `queue_row_class/2` (lines 1256–1338, 1474–1478) | exact — in-place replacement of return values |
| `examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` | component (mirror) | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact — byte-mirror; every edit is applied identically |
| `priv/templates/parapet.gen.ui/operator_live.ex.eex` | template | request-response | self — deferred stubs from Phase 44 (lines ~211, ~469) | exact — inline class string replacement |
| `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` | template | request-response | self — deferred stub from Phase 44 (line ~211) | exact — inline class string replacement |
| `test/parapet/operator_ui_contrast_test.exs` | test | batch | self — existing `@themes` map (lines 9–58) and `"semantic operator tokens"` test (lines 60–81) | exact — additive entries and assertions |
| Demo mirrors of secondary templates (`operator_live.ex`, `operator_detail_live.ex`) | live_view (mirror) | request-response | their respective template source | exact — byte-mirror |

---

## Pattern Assignments

---

### New CSS class rules in `operator_theme_bootstrap/1` CSS block

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 326–363

The existing `.po-chip-*` and `.po-button-warning` rules define the canonical pattern.
Every new `.po-*` class rule follows this same shape: one selector sets rest state, a
second selector (`:hover`, `:active`, or attribute) handles the interaction state.
All rules are scoped under `.parapet-ui` to stay inside the theme container.

**Existing `.po-chip-*` selector pattern** (lines 326–354) — copy this shape for new badge classes:
```css
.parapet-ui .po-chip {
  border: 1px solid var(--po-chip-neutral-border);
  background: var(--po-chip-neutral-bg);
  color: var(--po-chip-neutral-fg);
}

.parapet-ui .po-chip-success {
  border-color: var(--po-chip-success-border);
  background: var(--po-chip-success-bg);
  color: var(--po-chip-success-fg);
}

.parapet-ui .po-chip-info {
  border-color: var(--po-chip-info-border);
  background: var(--po-chip-info-bg);
  color: var(--po-chip-info-fg);
}
```

**Existing `.po-button-warning` selector pattern** (lines 356–363) — copy this shape for
all new button-variant classes (primary, recovery, destructive, success):
```css
.parapet-ui .po-button-warning {
  background: var(--po-button-warning-bg);
  color: var(--po-button-warning-fg);
}

.parapet-ui .po-button-warning:hover {
  background: var(--po-button-warning-hover);
}
```

**New CSS variable declarations** — append inside the light `.parapet-ui { }` block
(after the existing `--po-button-warning-hover` at line 94, before the closing `}`):
```css
--po-button-primary-bg: var(--parapet-text);
--po-button-primary-fg: var(--parapet-panel);
--po-button-primary-hover: var(--parapet-text-muted);
--po-button-recovery-bg: var(--parapet-accent);
--po-button-recovery-fg: #FFFFFF;
--po-button-recovery-hover: var(--parapet-accent-strong);
--po-button-destructive-bg: #B13A32;
--po-button-destructive-fg: #FFFFFF;
--po-button-destructive-hover: #8C2E27;
--po-button-success-bg: #567236;
--po-button-success-fg: #FFFFFF;
--po-button-success-hover: #3F5E28;
```

**Same variable declarations for BOTH dark blocks** (lines ~130–172 and ~196–233 —
both blocks must be byte-identical to each other):
```css
/* primary and recovery derive from existing dark vars — no separate value needed
   in dark; they already reference var(--parapet-text) etc. which are overridden.
   Add only where the hex value itself changes in dark: */
--po-button-success-bg: #3F5E28;
--po-button-success-fg: #EFF6E8;
--po-button-success-hover: #567236;
/* destructive stays same hex in both themes — no dark override needed */
```

**Verification check:** After editing, `grep -c "po-button-destructive-bg" priv/templates/parapet.gen.ui/operator_components.ex.eex` must return ≥ 1 (it only needs the light declaration; the value is theme-invariant).

**New CSS class rules to add** — insert after the existing `.po-button-warning:hover` rule (after line 363, before the `.parapet-theme-option` block at line 365):
```css
.parapet-ui .po-button-primary {
  background: var(--po-button-primary-bg);
  color: var(--po-button-primary-fg);
}
.parapet-ui .po-button-primary:hover {
  background: var(--po-button-primary-hover);
}

.parapet-ui .po-button-recovery {
  background: var(--po-button-recovery-bg);
  color: var(--po-button-recovery-fg);
}
.parapet-ui .po-button-recovery:hover {
  background: var(--po-button-recovery-hover);
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
  color: var(--parapet-bg);
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

**Inline hex fix** — line 378, inside existing `html[data-parapet-theme="dark"] .parapet-theme-option[aria-pressed="true"]` rule:
```css
/* Current (line 378): */
color: #042f2e;

/* Replace with: */
color: var(--po-nav-active-fg);
```

---

### `control_base()` function replacement

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1283–1285

**Current** (line 1284):
```elixir
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-100 ease-out active:scale-[0.96] focus:outline-none focus:ring-2"
end
```

**Replacement:**
```elixir
defp control_base do
  "flex min-h-[40px] items-center justify-center rounded-lg px-4 py-2 text-sm font-medium transition-transform duration-[--motion-fast] ease-out active:scale-[0.96] focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus"
end
```

Changes: `duration-100` → `duration-[--motion-fast]`; add `focus:ring-offset-2`; add `po-focus`.
After this, remove any standalone `po-focus` or `focus:ring-{color}-{n}` from individual
`control_class/2` variant strings (see below).

---

### `control_class/2` function replacements

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1258–1282

The existing `:warning` variant (line 1264–1268) shows the pattern for tokenized variants —
use a semantic `.po-button-*` class, remove raw color utilities:
```elixir
# Existing :warning (lines 1264–1268) — MODEL for new variants:
defp control_class(:warning, width),
  do:
    control_width(width) <>
      " " <>
      control_base() <> " po-button-warning focus:ring-amber-300"
```

**Replace `:recovery`** (lines 1258–1262) — current uses raw `bg-indigo-600`:
```elixir
# Current:
defp control_class(:recovery, width),
  do:
    control_width(width) <>
      " " <>
      control_base() <> " bg-indigo-600 text-white hover:bg-indigo-700 focus:ring-indigo-300"

# Replacement:
defp control_class(:recovery, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-recovery"
```

**Replace `:success`** (lines 1277–1281) — current uses raw `bg-emerald-600`:
```elixir
# Current:
defp control_class(:success, width),
  do:
    control_width(width) <>
      " " <>
      control_base() <> " bg-emerald-600 text-white hover:bg-emerald-700 focus:ring-emerald-300"

# Replacement:
defp control_class(:success, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-success"
```

**Add new `:primary` variant** (insert before `:recovery`, after line 1256):
```elixir
defp control_class(:primary, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-primary"
```

**Add new `:destructive` variant** (insert after `:primary`):
```elixir
defp control_class(:destructive, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-destructive"
```

**Clean up `:warning`** (line 1268) — remove `focus:ring-amber-300` since `control_base()` now includes `po-focus`:
```elixir
defp control_class(:warning, width),
  do: control_width(width) <> " " <> control_base() <> " po-button-warning"
```

---

### `timeline_entry_badge_class/1` function replacement

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1474–1478

The `:system` clause (line 1474) already uses a semantic class `"po-button-warning"` —
that is the model for replacing the remaining three raw-utility clauses:

```elixir
# Current (lines 1474–1478):
defp timeline_entry_badge_class(%{actor_class: :system}), do: "po-button-warning"
defp timeline_entry_badge_class(%{actor_class: :operator}), do: "bg-indigo-700"
defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "bg-violet-700"
defp timeline_entry_badge_class(%{actor_class: :external}), do: "bg-slate-700"
defp timeline_entry_badge_class(_), do: "bg-stone-600"

# Replacement (lines 1475–1477 only — :system and catch-all unchanged):
defp timeline_entry_badge_class(%{actor_class: :operator}), do: "po-timeline-badge-operator"
defp timeline_entry_badge_class(%{actor_class: :copilot}), do: "po-timeline-badge-copilot"
defp timeline_entry_badge_class(%{actor_class: :external}), do: "po-timeline-badge-external"
```

---

### `queue_row_class/2` function replacement

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 1332–1338

```elixir
# Current (lines 1332–1338):
defp queue_row_class(selected, incident) do
  if selected && selected.id == incident.id do
    "border-l-teal-700 bg-teal-50/80 hover:bg-teal-50"
  else
    "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
  end
end

# Replacement — selected branch only; unselected branch is intercepted and acceptable:
defp queue_row_class(selected, incident) do
  if selected && selected.id == incident.id do
    "po-queue-row-selected"
  else
    "border-l-transparent bg-stone-50/40 hover:bg-stone-100"
  end
end
```

---

### Inline markup fixes in `operator_components.ex.eex`

**Analog:** existing markup in the same file; the `.po-chip po-chip-info` pattern already
appears in `chip_class/2` at line 1301 and `state_color/1` at line 1342.

**`suspect_changes_card` icon badge** (line ~899) — current `bg-purple-100 text-purple-800`:
```html
<!-- Replace class string with: -->
class="po-chip po-chip-info ..."
```

**`suspect_changes_card` scope badge** (line ~915) — current `bg-violet-100 text-violet-800 ring-1 ring-violet-200/50`:
```html
<!-- Replace with: -->
class="po-chip po-chip-info"
```

**`runbook_card` guidance block** (line ~1001) — current `bg-blue-50 border border-blue-100 rounded text-xs text-violet-800 italic`:
```html
<!-- Replace with (keep layout utilities, replace color utilities): -->
class="po-guidance rounded text-xs italic"
```

**`preview_panel` header** (line ~1059) — current `bg-indigo-500 ring-indigo-500`:
```html
<!-- Replace bg-indigo-500 with style= and ring with token expression: -->
<div class="... ring-1 ring-[color:var(--parapet-border)] ..."
     style="background: var(--parapet-accent);">
```

**`preview_panel` close button hover** (line ~1062) — current `hover:text-indigo-100`:
```html
<!-- Replace with: -->
hover:opacity-80
```

**`preview_panel` info/guidance block** (line ~1097) — current `bg-indigo-50 px-3 py-2 text-xs text-indigo-900 ring-1 ring-indigo-100`:
```html
<!-- Replace with: -->
class="po-guidance px-3 py-2 text-xs ring-1"
```

**Three standalone navigation buttons** using `bg-stone-950 ... duration-100 ...`:
- Line ~609 `action_center` "Return to response" button
- Line ~954 `retrospective_card` "Copy retrospective" button
- Line ~1132 `action_rail` "Back to history" link

All three replace their inline class string with `control_class(:primary)`:
```elixir
# Pattern:
class={["..layout-only utilities..", control_class(:primary)]}
```

---

### Secondary template stubs: `operator_live.ex.eex`

**Analog:** self — `priv/templates/parapet.gen.ui/operator_live.ex.eex` (Phase 44 deferred stubs)

**Queue-refresh button** (line ~211) — current `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300 ... duration-100`:
```html
<!-- Replace color + duration class string with token expression
     (operator_live.ex.eex does not call control_class/2, so use inline): -->
class="... bg-[color:var(--parapet-accent)] text-white hover:bg-[color:var(--parapet-accent-strong)]
       focus:outline-none focus:ring-2 focus:ring-offset-2 po-focus
       duration-[--motion-fast] transition-colors ease-out ..."
```

**Pagination link hover** (line ~469) — current `hover:ring-teal-700 hover:text-teal-700`:
```html
<!-- Replace with: -->
hover:text-[color:var(--parapet-accent)] hover:ring-[color:var(--parapet-border)]
```

---

### Secondary template stub: `operator_detail_live.ex.eex`

**Analog:** self — `priv/templates/parapet.gen.ui/operator_detail_live.ex.eex` (Phase 44 deferred stub)

**Back-link** (line ~211) — current `text-teal-800 hover:text-teal-950`:
```html
<!-- Replace both classes with: -->
class="po-link ..."
```
`.po-link` already handles `color: var(--po-link)` and `:hover { color: var(--po-link-hover); }`.

---

### `test/parapet/operator_ui_contrast_test.exs` — `@themes` extension

**Analog:** `test/parapet/operator_ui_contrast_test.exs` lines 9–58 (existing `@themes` map structure)

Add to the **light** map (after `warning_button_fg: "#FFFFFF"` on line 32):
```elixir
primary_button_bg: "#101820", primary_button_fg: "#FFFFFF",
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#567236", success_button_fg: "#FFFFFF"
```

Add to the **dark** map (after `warning_button_fg: "#101820"` on line 56):
```elixir
primary_button_bg: "#F8F4EC", primary_button_fg: "#2E3A42",
destructive_button_bg: "#B13A32", destructive_button_fg: "#FFFFFF",
success_button_bg: "#3F5E28", success_button_fg: "#EFF6E8"
```

---

### `test/parapet/operator_ui_contrast_test.exs` — new `assert_contrast` calls

**Analog:** `test/parapet/operator_ui_contrast_test.exs` lines 60–81 (existing assertion pattern)

Add inside the `for {theme, tokens} <- @themes do` loop (after line 76, before the focus ring assertion):
```elixir
assert_contrast(theme, :primary_button, tokens.primary_button_fg, tokens.primary_button_bg, 4.5)
assert_contrast(theme, :destructive_button, tokens.destructive_button_fg, tokens.destructive_button_bg, 4.5)
assert_contrast(theme, :success_button, tokens.success_button_fg, tokens.success_button_bg, 4.5)
```

---

### `test/parapet/operator_ui_contrast_test.exs` — new refute/assert for COMP-06/07/08 + MOTION-02

**Analog:** `test/parapet/operator_ui_contrast_test.exs` lines 83–121 (existing `"operator components use semantic tokens..."` test — `File.read!/assert content =~` pattern)

Add inside the `for path <- @component_paths do` block (after the `"font-display: swap"` assertion on line 119, before the closing `end`):
```elixir
# COMP-08: off-palette class remediation complete
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

# MOTION-02: duration token used; no transition-all
refute content =~ "transition-all"
assert content =~ "duration-[--motion-fast]"

# COMP-06: po-focus on all controls
assert content =~ "po-focus"

# COMP-07: no raw badge color utilities
refute content =~ "bg-purple-100 text-purple-800"
refute content =~ "bg-violet-100 text-violet-800"
refute content =~ "bg-indigo-700"
refute content =~ "bg-violet-700"
refute content =~ "bg-slate-700"

# COMP-05: no spurious pointer cursor on stat cards
refute content =~ "cursor-pointer"
```

---

## Shared Patterns

### Byte-mirror constraint (CRITICAL — applies to every file edit)

**Source:** Phase 44 PATTERNS.md and RESEARCH.md Pattern 3
**Apply to:** All edits to `operator_components.ex.eex`, `operator_live.ex.eex`, `operator_detail_live.ex.eex`

Every change to a template file must be applied identically to its demo mirror in the
same commit. Verify with:
```bash
diff <(grep -o '\.po-[a-z-]*' priv/templates/parapet.gen.ui/operator_components.ex.eex | sort -u) \
     <(grep -o '\.po-[a-z-]*' examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex | sort -u)
```
Output should be empty.

### `po-focus` placement rule

**Source:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 284–287 (`.po-focus` CSS definition) and `control_base()` at line 1283
**Apply to:** All interactive elements (`<button>`, `<a>`, theme-option buttons)

`po-focus` lives in `control_base()` after Phase 45. Do NOT duplicate it on individual
`control_class/2` variant strings. For markup buttons outside `control_class/2`, add
`po-focus focus:outline-none focus:ring-2 focus:ring-offset-2` as a group.

### `.parapet-ui .po-*` selector scoping

**Source:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` lines 326–363 (every existing `.po-*` rule)
**Apply to:** All new CSS class rules

All semantic class rules MUST be prefixed with `.parapet-ui` to stay inside the theme
container and avoid leaking into host application styles.

### Three-block CSS variable sync

**Source:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` blocks at lines 8–60 (light), 62–115 (explicit dark), ~196–234 (media-query dark)
**Apply to:** Any new `--po-button-*` variable that has a different value in dark mode

After editing the light block, add the dark override to BOTH dark blocks.
Check with: `grep -c "po-button-success-bg" operator_components.ex.eex` → must return ≥ 3.

### ExUnit `File.read!` + string assertion pattern

**Source:** `test/parapet/operator_ui_contrast_test.exs` lines 83–121
**Apply to:** All new refute/assert additions to the second test

```elixir
for path <- @component_paths do
  content = File.read!(path)
  assert content =~ "marker"
  refute content =~ "forbidden"
end
```

---

## No Analog Found

No new files are introduced in Phase 45. All changes are edits to existing files.
The pattern map is entirely composed of "file's own existing idiom" analogs.

---

## Metadata

**Analog search scope:** `priv/templates/parapet.gen.ui/`, `examples/demo_app/lib/demo_app_web/live/parapet/`, `test/parapet/`
**Files read:** 6 source files + Phase 44 PATTERNS.md
**Pattern extraction date:** 2026-06-25
