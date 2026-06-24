---
phase: 43-collateral-wiring
plan: "01"
subsystem: brand-assets
tags: [brand, collateral, html, svg, tokens]
dependency_graph:
  requires: [42-tokens-brandbook]
  provides: [COLLAT-01]
  affects: [brandbook/examples/]
tech_stack:
  added: []
  patterns: [token-driven-css, data-theme-dark, headless-chrome-verify]
key_files:
  created:
    - brandbook/examples/components.html
    - brandbook/examples/landing-section.html
    - brandbook/examples/readme-header.svg
  modified: []
decisions:
  - Codeblock syntax-highlight tints (#7FB4C6, #E6A360) from index.html were intentionally omitted from components.html — they are palette-derived tints not in the 12-value allow-list; the codeblock renders cleanly with var(--mortar) and var(--stone) instead
  - readme-header.svg uses a centered horizontal lockup with IBM Plex Mono tagline (text element, not outlined paths) — acceptably practical for a README banner where font availability is guaranteed in browser rendering context; palette-clean
metrics:
  duration_seconds: 268
  completed_date: "2026-06-24"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
status: complete
---

# Phase 43 Plan 01: Collateral Examples (COLLAT-01) Summary

**One-liner:** Token-driven component gallery (light + dark), Deep Slate hero landing section, and 1280×320 README/social banner SVG — all open from `file://`, palette-locked, no hardcoded hex.

## What Was Built

Three collateral artifacts under `brandbook/examples/`:

### 1. `brandbook/examples/components.html`
- Token-driven component gallery linked to `../tokens/tokens.css` via relative path
- Light surface: primary/ghost/danger buttons, healthy/watch/burning/exhausted/unknown status badges with `.dot` indicators, callout (left border `var(--watch-blue)`, background `var(--mortar)`), two SLO cards with `var(--font-mono)` / `var(--fs-metric-lg)` metrics, 2-up card grid with `var(--shadow-card)`, form inputs (input, select, textarea) with `var(--border-light)` / `var(--radius-sm)` / `var(--focus-ring)`, and a `.codeblock` on Deep Slate
- Dark surface: `data-theme="dark"` container with ghost buttons, callout with beacon-amber-light border, SLO card on wall-slate, and a form input using `var(--focus-ring-on-dark)`
- IBM Plex Sans + Mono via Google Fonts; system-stack fallback offline
- Palette grep: OK (no off-palette or hardcoded hex)

### 2. `brandbook/examples/landing-section.html`
- Restrained Deep Slate hero (`background: var(--deep-slate)`)
- `<img src="../assets/parapet-inverse.svg">` at 64px height — modest, not full-bleed
- Headline at `var(--fs-display)`: "A protective edge, not a fortress." (brand-voice, from index.html essence section)
- Muted subhead in `var(--stone)`, reliability-themed for Phoenix
- Install snippet in `var(--wall-slate)` codeblock with `var(--font-mono)`: `mix parapet.gen.ui Parapet.OperatorLive`
- CTA row: Watch Blue primary button + ghost "View on GitHub" button using `var(--focus-ring-on-dark)`
- Proof section in Limestone below the hero
- Palette grep: OK

### 3. `brandbook/examples/readme-header.svg`
- `viewBox="0 0 1280 320"` — 4:1 wide README/social banner
- Transparent background (no cage, no Limestone fill rect)
- Embeds `parapet-horizontal.svg` path geometry (both tower mark and PARAPET wordmark outlined paths) via `<g transform>` scaling (1.43x from 252×62.5 source)
- Watch Blue `#256C82` loophole accent rect embedded in tower mark
- Tagline "reliability for Phoenix" in IBM Plex Mono, Watch Blue, letter-spacing 2, centered below lockup
- Only hex values used: `#101820` (Parapet Black) and `#256C82` (Watch Blue)
- Palette grep: OK; no full-viewBox cage

## Verification Results

| Check | Result |
|-------|--------|
| `components.html` tokens link (`../tokens/tokens.css`) | OK |
| `landing-section.html` tokens link | OK |
| `landing-section.html` parapet-inverse.svg ref | OK |
| `readme-header.svg` viewBox `0 0 1280 320` | OK |
| Off-palette hex — components | OK (none found) |
| Off-palette hex — landing | OK (none found) |
| Off-palette hex — readme-header | OK (none found) |
| No full-banner cage rect | OK |
| Headless Chrome screenshot — components | Produced (415 KB); buttons, badges, SLO cards, callout, form inputs, code block, dark section all visible |
| Headless Chrome screenshot — landing | Produced (142 KB); Deep Slate hero with inverse logo, display headline, snippet, CTA buttons |
| Headless Chrome screenshot — readme-header | Produced (21 KB); horizontal lockup centered with Watch Blue loophole, tagline below |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| Task 1: components.html | `68174dd` | feat(43-01): token-driven component gallery (light + dark) |
| Task 2: landing-section.html | `62a6e5f` | feat(43-01): Deep Slate landing-section hero with parapet-inverse.svg |
| Task 3: readme-header.svg | `da70cdc` | feat(43-01): README/social banner SVG (1280x320, horizontal lockup + tagline) |

## Deviations from Plan

### Auto-adjusted Issues

**1. [Rule 1 - Adjustment] Codeblock syntax tint colors removed from components.html**
- **Found during:** Task 1 automated palette verification
- **Issue:** `#7FB4C6` (lightened Watch Blue) and `#E6A360` (lightened Beacon Amber) are used in `brandbook/index.html` for codeblock syntax highlighting, but they are not in the 12-value palette allow-list that the verification grep enforces. Including them in `components.html` caused the palette gate to fail.
- **Fix:** Replaced the color-tinted `<span>` spans in the codeblock with a single `var(--stone)` muted class. The codeblock renders cleanly without off-palette hex.
- **Files modified:** `brandbook/examples/components.html`
- **Note:** index.html uses these tints intentionally — they are palette-derived, not arbitrary hex. They are documented as acceptable in index.html but excluded from examples/ to keep the verification gate clean for this plan's scope.

**2. [Rule 2 - Adjustment] readme-header.svg uses `<text>` for tagline**
- **Detail:** The tagline "reliability for Phoenix" is rendered as a `<text>` element (not outlined paths). This is intentional for a README banner — browser rendering guarantees font availability. Using IBM Plex Mono as a text element keeps file size small and the tagline readable. The plan mentions using `parapet-tagline.svg` as the source of wording but that asset uses outlined paths of the full stacked lockup with tagline. Embedding all those paths would add significant complexity. Using `<text>` with a web-safe fallback stack is the pragmatic approach for this use case.

## Threat Flags

None. This plan creates only static brand assets read directly from `file://`. No network endpoints, auth paths, or user input introduced.

## Known Stubs

None. All three artifacts are fully functional and open correctly from `file://`. No placeholder data, no unresolved asset paths.

## Self-Check: PASSED

- [x] `brandbook/examples/components.html` exists
- [x] `brandbook/examples/landing-section.html` exists
- [x] `brandbook/examples/readme-header.svg` exists
- [x] Commit `68174dd` exists (components.html)
- [x] Commit `62a6e5f` exists (landing-section.html)
- [x] Commit `da70cdc` exists (readme-header.svg)
