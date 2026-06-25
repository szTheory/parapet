---
phase: 44-foundations-token-re-skin-fonts-audit-apparatus
plan: "02"
subsystem: operator-theme
tags: [tokens, css-vars, fonts, motion, a11y, re-skin]
dependency_graph:
  requires: [44-01]
  provides: [brand-token-css-vars, font-face-declarations, motion-tokens]
  affects: [operator_components, demo_mirror, secondary_templates]
tech_stack:
  added: []
  patterns: [values-only-css-reskin, three-block-dark-mode-update, font-face-injection, motion-tokens]
key_files:
  created: []
  modified:
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex
    - priv/templates/parapet.gen.ui/operator_live.ex.eex
    - priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_live.ex
    - examples/demo_app/lib/demo_app_web/live/parapet/operator_detail_live.ex
decisions:
  - "D-04 honored: both explicit [data-parapet-theme=dark] and @media (prefers-color-scheme: dark) blocks updated byte-identically"
  - "D-07 honored: dark --po-link uses #7FB4C6 (operator exception), NOT brandbook #6FA8BC"
  - "D-06 honored: light focus ring #256C82, dark focus ring #F8F4EC (limestone)"
  - "D-03 honored: theme attribute remains data-parapet-theme, not renamed to data-theme"
  - "D-11 honored: @font-face rules in operator_theme_bootstrap/1, font-display: swap, system-stack fallback"
  - "bg-teal-700/hover:bg-teal-800/focus:ring-teal-300 and hover:ring-teal-700/hover:text-teal-700 have no intercepted equivalents; documented as deferred"
metrics:
  duration: "7 minutes"
  completed: "2026-06-24"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 6
status: complete
requirements: [TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, FONT-02, A11Y-01, MOTION-01]
---

# Phase 44 Plan 02: Token Re-skin — CSS Blocks + Font-face + Motion Summary

Re-pointed all 16 `--parapet-*` and 34 `--po-*` CSS variable VALUES to brand token hexes across all three theme blocks (light, explicit dark, `@media (prefers-color-scheme: dark)`) in the operator template and its demo mirror; injected IBM Plex `@font-face` rules with `font-display: swap`; added motion tokens zeroed under `prefers-reduced-motion`; replaced two un-intercepted decoration/ring teal classes in secondary templates.

## What Was Built

### Task 1: Re-skin all three CSS blocks + @font-face + motion

**operator_theme_bootstrap/1 light block** — 16 `--parapet-*` + 34 `--po-*` var values re-pointed to brand tokens, plus new vars:
- `--parapet-bg: #F8F4EC` (limestone), `--parapet-accent: #256C82` (watch-blue)
- `--po-link: #256C82`, `--po-focus: #256C82` (watch-blue, D-06)
- All six status chip triplets from `brandbook/tokens/tokens.css` lines 25-30
- `--font-sans: "IBM Plex Sans", ui-sans-serif, system-ui, sans-serif`
- `--font-mono: "IBM Plex Mono", ui-monospace, monospace`
- `--motion-fast: 120ms`, `--motion-base: 200ms`, `--motion-ease: cubic-bezier(.2, 0, 0, 1)`

**Both dark blocks (D-04 — highest-risk drift point):**
- `--parapet-bg: #18232B` (deep-slate), `--parapet-accent: #7FB4C6`
- `--po-link: #7FB4C6` (D-07 operator exception, NOT brandbook #6FA8BC)
- `--po-focus: #F8F4EC` (limestone, D-06)
- Explicit `[data-parapet-theme="dark"]` block and `@media (prefers-color-scheme: dark)` block are byte-identical in var values

**@font-face block** (inserted before `.parapet-ui { }` rule):
- IBM Plex Sans 400/500/600 + IBM Plex Mono 400/500
- `font-display: swap` on all five rules
- Filenames match Plan 01 output exactly

**prefers-reduced-motion block:**
- Added `:root { --motion-fast: 0ms; --motion-base: 0ms; }` block
- Existing `.parapet-ui * { animation-duration: 0.01ms !important; ... }` kept

**Demo mirror** (examples/demo_app/.../operator_components.ex): Identical changes applied. Both files carry all required hexes in all three blocks.

### Task 2: Secondary template color-class audit

Scanned `operator_live.ex.eex`, `operator_detail_live.ex.eex`, and their demo mirrors for un-intercepted Tailwind color utility classes.

**Changes made (class-token replacements):**
- `ring-teal-200` → `ring-stone-300` in queue-refresh notification div (operator_live, both template + mirror)
- `decoration-teal-200` → `decoration-stone-300` on back-link in operator_detail_live (both template + mirror)

**Classes left as-is (intercepted — branch by CSS var system):**
- `bg-teal-50` → intercepted by `.parapet-ui .bg-teal-50 { background-color: var(--parapet-accent-soft); }`
- `text-teal-950`, `text-teal-800` → intercepted by `.parapet-ui .text-teal-950 / .text-teal-800 { color: var(--parapet-accent-text); }`
- All `bg-stone-*`, `text-stone-*` classes → intercepted by stone interception rules
- `ring-stone-300`, `ring-stone-200` → intercepted

## Decisions Made

1. **D-04 gate passed**: Both dark blocks updated identically. `awk` extraction + hex grep verified `#18232B`, `#7FB4C6`, `#F8F4EC` all appear inside the `@media (prefers-color-scheme: dark)` block in both files.

2. **D-07 operator exception applied**: `--po-link` and `--po-header-muted` dark values set to `#7FB4C6` (5.14:1 on wall-slate panel surface), NOT `#6FA8BC` from brandbook. Phase-50 GUARD-04 admitting this as an explicit operator-scoped exception.

3. **Demo mirror byte-equivalence (D-16)**: Template and demo mirror carry identical CSS variable values across all three blocks. Verified by grep on both paths.

## Deviations from Plan

### Known Stubs / Partially Intercepted Classes

**1. [Rule 2 - Not Applied] Queue-refresh button (bg-teal-700/hover:bg-teal-800/focus:ring-teal-300)**

- **Found during:** Task 2 secondary template scan
- **Issue:** The queue-refresh CTA button in `operator_live.ex.eex` uses `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300`. There is no intercepted Tailwind class equivalent for a solid dark-teal background (the interception layer only covers `bg-teal-50`/`bg-teal-50/80`). Adding a new interception rule would violate D-01 (utility-interception layer must stay byte-identical). Adding an inline `style` attribute would be a markup-structure change (also D-01).
- **Resolution:** `ring-teal-200` on the notification wrapper was replaced with `ring-stone-300` (intercepted). The button's `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300` remains. Post-re-skin the button renders raw Tailwind teal-700 (#0f766e) on light, which is contrast-safe but off-brand. Phase 45 per-component fixes will address this CTA button.
- **Files:** priv/templates/parapet.gen.ui/operator_live.ex.eex, examples/demo_app/.../operator_live.ex

**2. [Rule 2 - Not Applied] Pagination link hover states (hover:ring-teal-700/hover:text-teal-700)**

- **Found during:** Task 2 scan of `pagination_link_class/1` function
- **Issue:** `pagination_link_class(true)` returns `"... hover:ring-teal-700 hover:text-teal-700"`. Hover-state Tailwind variants generate a CSS selector `.hover\:text-teal-700:hover { }` which is NOT matched by the interception rule `.parapet-ui .text-teal-700 { color: var(--parapet-accent-text); }` (class name mismatch on the colon).
- **Resolution:** These hover states remain. Hover on an active pagination link will show raw teal-700. Phase 45 per-component color fixes will address pagination link hover states.
- **Files:** priv/templates/parapet.gen.ui/operator_live.ex.eex, examples/demo_app/.../operator_live.ex

**3. [Rule 2 - Not Applied] operator_detail_live hover:text-teal-950**

- **Found during:** Task 2 scan
- **Issue:** Back-link uses `hover:text-teal-950`. `text-teal-950` IS intercepted but its hover variant is not.
- **Resolution:** `decoration-teal-200` replaced with `decoration-stone-300`. `hover:text-teal-950` remains (hover renders raw teal-950 on the back-link). Phase 45 will handle.
- **Files:** priv/templates/parapet.gen.ui/operator_detail_live.ex.eex, demo mirror

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` | PASS |
| `mix test operator_ui_contrast_test.exs` (informational) | PASS (2/2) |
| `#256C82` count ≥ 3 in template | PASS (5) |
| `#7FB4C6` in template | PASS |
| `@font-face` in template | PASS |
| `--motion-fast` in template | PASS |
| `--motion-fast: 0ms` in prefers-reduced-motion block | PASS |
| `#18232B`, `#7FB4C6`, `#F8F4EC` in `@media (prefers-color-scheme: dark)` block of template | PASS |
| `#18232B`, `#7FB4C6`, `#F8F4EC` in `@media (prefers-color-scheme: dark)` block of mirror | PASS |
| Demo mirror carries identical hexes | PASS |
| `data-parapet-theme` not renamed to `data-theme` | PASS |

## Known Stubs

| File | Class/Element | Issue | Future Plan |
|------|---------------|-------|-------------|
| priv/templates/parapet.gen.ui/operator_live.ex.eex | `bg-teal-700 hover:bg-teal-800 focus:ring-teal-300` on queue-refresh button | No intercepted solid-accent-bg equivalent | Phase 45 |
| priv/templates/parapet.gen.ui/operator_live.ex.eex | `hover:ring-teal-700 hover:text-teal-700` in pagination_link_class | Hover-variant not interceptable by CSS var layer | Phase 45 |
| priv/templates/parapet.gen.ui/operator_detail_live.ex.eex | `hover:text-teal-950` on back-link | Hover-variant not interceptable | Phase 45 |

## Self-Check: PASSED

Files exist:
- priv/templates/parapet.gen.ui/operator_components.ex.eex — FOUND
- examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex — FOUND
- priv/templates/parapet.gen.ui/operator_live.ex.eex — FOUND
- priv/templates/parapet.gen.ui/operator_detail_live.ex.eex — FOUND

Commits exist:
- b3d710d — feat(44-02): re-skin all three CSS blocks + @font-face + motion
- 2c57f01 — chore(44-02): replace un-intercepted color classes in secondary templates

## Gap-Closure Follow-up: Brand type/spacing/radius/shadow token declarations

The phase goal requires the operator theme foundation to carry the full brand token
set (color/type/spacing/radius/shadow/motion/focus). The initial pass declared color,
`--motion-*`, and `--font-*` only. This follow-up adds the remaining theme-independent
foundation tokens to the LIGHT/`:root` block of `operator_theme_bootstrap/1` (light block
only, like `--motion-*`/`--font-*`), copied VERBATIM from `brandbook/tokens/tokens.css`
(doc §8.3 type scale, §9.2 spacing, §9.3 radius, §9.4 borders & shadows):

- Type scale: `--fs-*`/`--lh-*`/`--fw-*` (display, h1-h3, body, body-sm, caption, code, metric-lg, metric-sm)
- Spacing 8px grid: `--space-1` through `--space-8`
- Radius: `--radius-xs/sm/md/lg/xl/pill`
- Borders & shadows: `--border-light`, `--border-dark`, `--shadow-card`, `--shadow-popover`

Values-only DECLARATIONS — no markup/class/selector/`.po-*` changes. Per-component
APPLICATION remains Phase 45. Added byte-identically to both
`priv/templates/parapet.gen.ui/operator_components.ex.eex` and the demo mirror
`examples/demo_app/lib/demo_app_web/live/parapet/operator_components.ex` (16 lines each, verified identical).

Gates: `mix compile --warnings-as-errors` PASS; `mix test operator_ui_contrast_test.exs
operator_ui_demo_contract_test.exs` PASS (7 tests, 0 failures — additive declarations,
no existing var values changed).
