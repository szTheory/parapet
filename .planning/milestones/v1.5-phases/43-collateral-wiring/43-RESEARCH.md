# Phase 43: Collateral, Wiring & QA/Audit Gate — Research

**Researched:** 2026-06-24
**Domain:** SVG/HTML collateral authoring, ExDoc logo wiring, repo-hygiene audit
**Confidence:** HIGH (all findings from direct codebase inspection)

## Summary

Phase 43 is the final phase of v1.5. Everything it needs exists on disk and is confirmed. The token system (tokens.css/tokens.json), 9 final logo SVGs, and the HTML brand book (index.html) are all committed. This phase is purely additive: create `brandbook/examples/` (3 artifacts), copy two SVGs into `docs/assets/`, trim 5 exploration HTMLs, run QA checks, and write milestone docs.

There are no new libraries to install, no new dependencies to resolve, and no architectural decisions to make. The logo is locked (D-003). `mix.exs` requires zero edits — the swap is path-stable. The palette-audit and binary-scan QA commands are provided verbatim in 43-CONTEXT.md and confirmed here.

**Primary recommendation:** Follow the 43-CONTEXT.md TODO list in order (COLLAT-01 → COLLAT-02 → cleanup → COLLAT-03), verifying each QA gate before moving forward.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Identity is final (6 rounds, user-approved). See `brandbook/notes/decision-log.md` D-003. Do NOT re-open the logo.
- Stacked emblem: corbelled parapet tower above PARAPET in Space Grotesk tight caps; single Watch Blue `#256C82` loophole accent. Wordmark outlined to paths (font-independent).
- Final assets (9 SVGs, all transparent/palette-locked/outlined) live in `brandbook/assets/`.
- HexDocs swap is zero-config path-stable: `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` paths unchanged so `mix.exs` doc block requires no edits.
- Transparent logos, no background cage · palette-locked (brand tokens only) · no font binaries committed · repo-lean · no subtitle on the primary lockup.
- Values copied from the research doc, not re-derived.
- Commit via `gsd-tools query commit` per the session pattern.

### Claude's Discretion
- Which of `parapet-logo.svg` (stacked, 183.9×106.0) vs `parapet-horizontal.svg` (252.0×62.5) vs `parapet-mark.svg` (32×52, mark only) reads best in the ExDoc sidebar — eyeball `mix docs` after the swap to confirm. The stacked is tall; horizontal is wider; mark is the most compact.
- Whether to move all exploration rounds to an `explorations/` note subdirectory or simply delete rounds 1–5 and keep round 6 in place.
- Exact copy/headline for landing-section.html hero text (must be brand-voice-consistent; see voice section of index.html).

### Deferred Ideas (OUT OF SCOPE)
- Self-hosted webfont bundle (`@font-face` IBM Plex woff2)
- Raster exports: PNG/ICO favicons and OpenGraph social-card images
- Token → Tailwind/daisyUI theme generator and HEEx component snippets
- Retheme the generated Operator LiveView UI to the new tokens
- Animated/motion logo, Figma source-of-truth, multi-page PDF brand book
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COLLAT-01 | Implementation-ready collateral built on tokens: `brandbook/examples/components.html`, `brandbook/examples/landing-section.html`, `brandbook/examples/readme-header.svg` — each openable from `file://` | Token catalog below; liftable component markup identified in index.html §components |
| COLLAT-02 | Replace `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` with on-brand winners; `mix.exs` paths unchanged; `mix docs` renders without error | Paths confirmed at lines 59-60; current off-brand assets confirmed; ExDoc `<img>` rendering confirmed; outlined SVGs are font-independent |
| COLLAT-03 | Repo-hygiene audit passes: size ≤ ~250 KB, zero raster/font binaries, no full-viewBox rect background in any logo asset, no off-palette hex in any SVG/CSS; milestone docs written | Current baseline: 224 KB, 0 binaries, assets palette-clean (confirmed by dry-run); audit commands documented |
</phase_requirements>

## Architectural Responsibility Map

This phase is brand-assets only — no application tiers are involved.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Collateral HTML examples | Static file (file://) | — | Self-contained; served from disk, no server needed |
| ExDoc logo/favicon swap | CDN / Static | — | Copies SVG into `docs/assets/`; ExDoc embeds as `<img>` tag |
| Repo-hygiene audit | Build tooling | — | `du`, `find`, `grep`, `mix docs` — local CLI only |
| Milestone audit doc | Planning artifacts | — | Markdown written to `.planning/milestones/` |

---

## 1. Token System & Brand Book Internals

### CSS Custom Properties Catalog

All tokens live in `brandbook/tokens/tokens.css` (`:root` block) with a `[data-theme="dark"]` override. [VERIFIED: direct codebase read]

**Brand neutrals:**
| Token | Value | Role |
|-------|-------|------|
| `--parapet-black` | `#101820` | Primary dark — headers, dark surfaces, primary text on light |
| `--deep-slate` | `#18232B` | Secondary dark — admin shell, nav, dark cards |
| `--wall-slate` | `#2E3A42` | Structural neutral — borders on dark, secondary panels |
| `--stone` | `#D8D0C3` | Warm neutral — dividers, diagrams, disabled fills |
| `--mortar` | `#EAE2D4` | Soft surface — cards, doc callouts |
| `--limestone` | `#F8F4EC` | Main light background — docs, marketing, empty states |

**Signal colors:**
| Token | Value | Role |
|-------|-------|------|
| `--watch-blue` | `#256C82` | Calm signal — links, selected, info, logo accent |
| `--beacon-amber` | `#B45309` | Warning on light |
| `--beacon-amber-light` | `#D97706` | Warning on dark |
| `--budget-moss` | `#567236` | Healthy budget, success |
| `--incident-red` | `#B13A32` | Critical SLO burn, destructive |
| `--trace-violet` | `#6D5BD0` | AI / correlation / assistive layer only |

**Status sets** (all three of text/bg/border defined per state):
`--healthy-text/bg/border`, `--watch-text/bg/border`, `--burning-text/bg/border`, `--exhausted-text/bg/border`, `--unknown-text/bg/border`, `--ai-text/bg/border`

**Semantic roles (auto-switch with data-theme):**
`--bg`, `--surface`, `--surface-soft`, `--text`, `--text-muted`, `--link`, `--border`

**Typography:**
- `--font-sans`: `"IBM Plex Sans", Inter, ui-sans-serif, system-ui, sans-serif`
- `--font-mono`: `"IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace`
- `--font-serif`: `"IBM Plex Serif", Georgia, serif`
- Logo wordmark is Space Grotesk — NOT a UI typeface; shipped as outlined paths only

**Type scale tokens** (size/line-height/weight triplets):
`--fs-display/--lh-display/--fw-display` (56px/1.00/500), `--fs-h1/--lh-h1/--fw-h1` (40px/1.08/500), `--fs-h2` (30px), `--fs-h3` (22px), `--fs-body` (16px/1.60/400), `--fs-body-sm` (14px), `--fs-caption` (12px/1.40/500), `--fs-code` (13px), `--fs-metric-lg` (36px), `--fs-metric-sm` (20px)

**Spacing (8px grid):** `--space-1` (4px) through `--space-8` (64px)

**Radius:** `--radius-xs` (4px), `--radius-sm` (6px), `--radius-md` (10px), `--radius-lg` (14px), `--radius-xl` (20px), `--radius-pill` (999px)

**Borders:** `--border-light` (`1px solid rgba(16,24,32,0.12)`), `--border-dark` (`1px solid rgba(248,244,236,0.16)`)

**Shadows:** `--shadow-card` (`0 1px 2px rgba(16,24,32,0.06)`), `--shadow-popover` (`0 12px 32px rgba(16,24,32,0.16)`)

**Focus:** `--focus-ring` (`2px solid #256C82`), `--focus-ring-on-dark` (`2px solid #F8F4EC`), `--focus-offset` (2px)
Note: `#256C82` passes 3:1 only on LIGHT surfaces. Dark surfaces must use `--focus-ring-on-dark`.

**Motion:** `--motion-fast` (120ms), `--motion-base` (200ms), `--motion-ease` (`cubic-bezier(0.2,0,0,1)`)

### Dark Theme Mechanism

Apply `data-theme="dark"` on any container element (not a class swap). The `:root` semantic tokens are remapped:
- `--bg` → `var(--deep-slate)` (`#18232B`)
- `--surface` → `var(--wall-slate)` (`#2E3A42`)
- `--text` → `var(--limestone)` (`#F8F4EC`)
- `--text-muted` → `var(--stone)` (`#D8D0C3`)
- `--link` → `#6FA8BC` (lightened Watch Blue for AA on dark)
- `--border` → `rgba(248,244,236,0.16)`

### Liftable Component Markup from index.html

The `#components` section (lines 219–248) is the direct source for `examples/components.html`. Markup classes defined in index.html `<style>`:

**Buttons** (lines 80–87):
```css
.btn { font-family: var(--font-sans); font-weight: 600; font-size: var(--fs-body-sm);
       border-radius: 8px; padding: 9px 16px; border: 1px solid transparent; cursor: pointer }
.btn-primary { background: var(--watch-blue); color: var(--limestone) }
.btn-ghost   { background: transparent; color: var(--text); border-color: var(--border) }
.btn-danger  { background: var(--incident-red); color: var(--limestone) }
.btn:focus-visible { outline: var(--focus-ring); outline-offset: var(--focus-offset) }
.dark .btn-ghost { color: var(--limestone); border-color: var(--border-dark) }
.dark .btn:focus-visible { outline: var(--focus-ring-on-dark) }
```

**Badges:**
```css
.badge { display: inline-flex; align-items: center; gap: 6px; font-size: var(--fs-caption);
         font-weight: 600; padding: 3px 10px; border-radius: var(--radius-pill); border: 1px solid }
```
Status badge pattern: apply status `color`/`background`/`border-color` inline from status tokens + `.dot` span with `background` color.

**Callout:**
```css
.callout { border-left: 3px solid var(--watch-blue); background: var(--mortar);
           padding: var(--space-3) var(--space-4); border-radius: var(--radius-sm) }
```

**Card (`.panel`):**
```css
.panel { border: var(--border-light); border-radius: var(--radius-md);
         padding: var(--space-5); background: var(--surface) }
.panel.dark { background: var(--deep-slate); border-color: var(--border-dark) }
```

**SLO card (`.slo`):**
```css
.slo { border: var(--border-light); border-radius: var(--radius-md);
       padding: var(--space-4); background: var(--surface) }
```
Contains: title (`font-weight: 600`), metric (`--fs-metric-lg` / `--font-mono` / weight 500), muted caption row.

**Code block (`.codeblock`):**
```css
.codeblock { background: var(--deep-slate); color: var(--mortar); font-family: var(--font-mono);
             font-size: var(--fs-code); line-height: var(--lh-code);
             padding: var(--space-4); border-radius: var(--radius-md); overflow: auto }
```

---

## 2. Logo Asset Inventory

All 9 SVGs live in `brandbook/assets/`. All are transparent, palette-locked, outlined (font-independent). [VERIFIED: direct file read]

| File | ViewBox | Rendered W×H | Description |
|------|---------|--------------|-------------|
| `parapet-logo.svg` | `0 0 183.9 106.0` | 183.9×106 px | Primary stacked: tower above PARAPET wordmark. Tall aspect. |
| `parapet-inverse.svg` | `0 0 183.9 106.0` | 183.9×106 px | Stacked on dark: Limestone ink, same geometry |
| `parapet-mono.svg` | (similar to logo) | ~183.9×106 | Single-ink monochrome version |
| `parapet-horizontal.svg` | `0 0 252.0 62.5` | 252×62.5 px | Horizontal: tower left of wordmark. Wide/short. |
| `parapet-horizontal-inverse.svg` | `0 0 252.0 62.5` | 252×62.5 px | Horizontal on dark |
| `parapet-mark.svg` | `4 6 32 52` | 32×52 px | Tower mark only. Compact/square-ish. Best for tight spaces. |
| `parapet-mark-inverse.svg` | `4 6 32 52` | 32×52 px | Mark only on dark |
| `favicon.svg` | `4 6 32 52` | 32×52 px | Same geometry as mark; used as favicon |
| `parapet-tagline.svg` | `0 0 213.5 139.0` | 213.5×139 px | Stacked + tagline lockup ("reliability for Phoenix") |

**Asset selection guidance for each collateral artifact:**
- `examples/landing-section.html` (Deep Slate hero): use `parapet-inverse.svg` — the brand book hero already demonstrates this pattern (`<img src="assets/parapet-inverse.svg">` in index.html header)
- `examples/readme-header.svg` (1280×320 banner): use the horizontal lockup geometry (tower + wordmark side-by-side) and optionally include the tagline text; `parapet-horizontal.svg` is the source composition
- `docs/assets/parapet-logo.svg` (ExDoc sidebar): use `parapet-mark.svg` — the mark-only asset (32×52 viewBox) reads best at the small/compact size ExDoc renders. The stacked (106px tall) may be clipped; the horizontal (252px wide) overflows. Eyeball `mix docs` to confirm. [ASSUMED — ExDoc sidebar size not formally documented]
- `docs/assets/favicon.svg`: copy `brandbook/assets/favicon.svg` directly (identical geometry to mark; already branded and verified at 16px)

**Explorations subdirectory** (`brandbook/assets/explorations/`): 8 SVGs from round 1 (option-a/b/c/d mark + full). Keep as provenance — they are small SVGs, no cleanup needed.

---

## 3. ExDoc / HexDocs Logo Wiring

### Confirmed Configuration

`mix.exs` lines 59–60 [VERIFIED: direct file read]:
```elixir
logo: "docs/assets/parapet-logo.svg",
favicon: "docs/assets/favicon.svg",
```

These paths are unchanged by the phase. The swap is a file copy only:
```bash
cp brandbook/assets/parapet-mark.svg docs/assets/parapet-logo.svg   # (or parapet-logo.svg if stacked reads fine)
cp brandbook/assets/favicon.svg      docs/assets/favicon.svg
```

### Current Off-Brand Assets (to be replaced)

`docs/assets/parapet-logo.svg` (753 bytes) — contains a full-viewBox `<rect>` with `fill="#0f172a"` (Tailwind slate-900), `<text>` in `Arial, Helvetica, sans-serif`, and off-palette stroke colors `#38bdf8`/`#94a3b8`/`#f8fafc`. This is the defect documented in D-001.

`docs/assets/favicon.svg` (622 bytes) — same defects.

### ExDoc Rendering Behavior

ExDoc renders the logo asset as an `<img>` tag in the sidebar, not inline SVG. This means:
- The SVG is font-independent (required — outlined paths satisfy this)
- No JavaScript or CSS from the host page applies to logo internals
- The logo should work at the size ExDoc constrains it to (typically 48–64px height in the sidebar)

**Verify command:** `mix docs && open doc/index.html`
Output directory: `doc/` (not `docs/`)

---

## 4. QA / Audit Mechanics

All QA commands are from 43-CONTEXT.md and confirmed runnable. [VERIFIED: dry-run executed]

### Command 1 — Off-palette hex audit

```bash
cd /Users/jon/projects/parapet
grep -rohiE '#[0-9a-f]{6}' brandbook/assets/*.svg | sort -u | \
  grep -viE '101820|18232B|2E3A42|D8D0C3|EAE2D4|F8F4EC|256C82|B45309|D97706|567236|B13A32|6D5BD0' \
  && echo "OFF-PALETTE FOUND" || echo "OK"
```

**Palette allow-list (12 hex values):**
`#101820` (Parapet Black), `#18232B` (Deep Slate), `#2E3A42` (Wall Slate), `#D8D0C3` (Stone), `#EAE2D4` (Mortar), `#F8F4EC` (Limestone), `#256C82` (Watch Blue), `#B45309` (Beacon Amber), `#D97706` (Beacon Amber Light), `#567236` (Budget Moss), `#B13A32` (Incident Red), `#6D5BD0` (Trace Violet)

**Current baseline:** Ran against `brandbook/assets/*.svg` — result: `OK`. No off-palette colors found. [VERIFIED: executed in this session]

Note: this grep only catches 6-digit hex. The status set colors in tokens.css (`#3F5E28`, `#EFF6E8`, etc.) appear only in HTML/CSS, not in SVGs — the audit scope is `assets/*.svg` only.

Run this again after COLLAT-01 against `brandbook/examples/*.html` and `brandbook/examples/*.svg` to catch any authoring drift.

### Command 2 — Raster/font binary scan

```bash
find brandbook \( -name '*.png' -o -name '*.jpg' -o -name '*.woff*' -o -name '*.ttf' -o -name '*.otf' \) -print
```

**Current baseline:** Zero hits. [VERIFIED: executed in this session]

### Command 3 — Size budget

```bash
du -sh brandbook
```

**Current baseline:** 224 KB. Budget: ≤ ~250 KB.

Trimming `logo-options.html` + `logo-round-2..5.html` (5 files, ~49 KB combined) would bring it to ~175 KB, well within budget.
Adding `examples/` (3 new files) will add ~10–20 KB estimated, landing around ~185–195 KB after cleanup.

### Command 4 — Visual render (headless Chrome)

```bash
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=2 \
  --window-size=1200,2000 --virtual-time-budget=4500 --screenshot=/tmp/out.png \
  "file://$PWD/brandbook/examples/components.html"
```

Adjust `--window-size` per artifact:
- `components.html`: 1200×2000 (tall, many components)
- `landing-section.html`: 1200×800 (hero section)
- `readme-header.svg`: load as `file://…/readme-header.svg` or embed in an HTML wrapper for screenshot

macOS Chrome binary path: `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` [VERIFIED: confirmed in 43-CONTEXT.md]

### Command 5 — Mix docs build

```bash
mix docs && open doc/index.html
```

Output goes to `doc/` (not `docs/`). Visually confirm the new logo appears in the sidebar at an appropriate size.

### Command 6 — Scoped diff check

```bash
git diff --name-only HEAD
# Expected: only brandbook/** and docs/assets/*.svg
```

---

## 5. Cleanup Scope

### Files to Delete

| File | Size | Disposition |
|------|------|-------------|
| `brandbook/notes/logo-options.html` | ~15 KB | DELETE — round 1 exploration, superseded |
| `brandbook/notes/logo-round-2.html` | ~11 KB | DELETE — intermediate, superseded |
| `brandbook/notes/logo-round-3.html` | ~8 KB | DELETE — intermediate, superseded |
| `brandbook/notes/logo-round-4.html` | ~7 KB | DELETE — intermediate, superseded |
| `brandbook/notes/logo-round-5.html` | ~8 KB | DELETE — intermediate, superseded |

Total savings: ~49 KB.

### Files to Keep

| File | Rationale |
|------|-----------|
| `brandbook/notes/logo-round-6.html` | Final-round record — documents the stacked emblem tournament that produced the locked identity |
| `brandbook/assets/explorations/*.svg` | Round-1 option SVGs (8 files, small); provenance of the direction process |

### After Cleanup: Projected Size

~224 KB − 49 KB + ~15 KB (examples) ≈ **190 KB** — well within 250 KB budget.

---

## 6. COLLAT-01 Authoring Plan (Implementation Details)

### File: `brandbook/examples/components.html`

**Header pattern** (adapted from index.html):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Parapet — Components</title>
  <link rel="stylesheet" href="../tokens/tokens.css">
  <!-- IBM Plex via Google Fonts (degrades to system stack offline) -->
  <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@400;500;600&display=swap" rel="stylesheet">
  <style>
    /* copy relevant styles from index.html + extend for form inputs */
  </style>
</head>
```

The path to tokens.css is `../tokens/tokens.css` (examples/ is one level below brandbook/).

**Lift directly from index.html §components:**
- Light panel with buttons (primary, ghost, danger)
- Badge row (healthy, watch, burning) with `.dot` and status tokens
- SLO card (`.slo`) with metric in `--font-mono` / `--fs-metric-lg`
- Dark panel with `data-theme="dark"` showing ghost buttons + callout

**Extend for components.html (not in index.html):**
- Form inputs: input, select, textarea — use `--border-light`, `--radius-sm`, `--focus-ring`
- Cards: explicit `.card` grid (2-up) showing `--shadow-card`
- Code block example

### File: `brandbook/examples/landing-section.html`

**Pattern:** Deep Slate (`--deep-slate`) full-width hero section. Use `parapet-inverse.svg` for the mark. Brand voice example from index.html §essence: "A protective edge, not a fortress."

Key structure:
```html
<section style="background: var(--deep-slate); color: var(--limestone); padding: var(--space-8) 0;">
  <img src="../assets/parapet-inverse.svg" alt="Parapet" style="height: 64px;">
  <h1 style="font-size: var(--fs-display);">…headline…</h1>
  <p style="color: var(--stone);">…subhead…</p>
  <!-- install snippet in .codeblock -->
  <code style="background: var(--wall-slate);">mix parapet.gen.ui Parapet.OperatorLive</code>
</section>
```

Restrained stepped mark note: 43-CONTEXT.md says "restrained stepped mark" in the hero — use `parapet-inverse.svg` at modest size (not full-bleed). The brand book hero uses `height: 84px` — 64px is appropriate for a landing section.

### File: `brandbook/examples/readme-header.svg`

**Dimensions:** `viewBox="0 0 1280 320"` — a 4:1 wide banner.

**Composition:**
- Background: `#F8F4EC` (Limestone) or transparent (the non-negotiable says transparent is default; backgrounds appear only as swatches)
- Tower mark group from `parapet-horizontal.svg` geometry — tower left + PARAPET wordmark right
- Tagline text below or beside: "reliability for Phoenix" (from `parapet-tagline.svg`)
- Can embed the path data from `parapet-horizontal.svg` directly (it is already outlined path data)

Since this is a standalone SVG (no CSS link), colors must be hardcoded hex values from the palette — the 6 allowed hex values apply. Use `#101820` for Parapet Black ink and `#256C82` for the loophole.

---

## 7. Milestone Audit Format

### v1.4 MILESTONE-AUDIT.md Structure (template to mirror)

From `.planning/milestones/v1.4-MILESTONE-AUDIT.md` [VERIFIED: direct file read]:

```yaml
---
milestone: v1.5
milestone_name: Brand Book & Logo System
audited: <ISO datetime>
status: passed
scores:
  requirements: 3/3
  phases: 4/4
  integration: X/X
  flows: X/X
gaps:
  requirements: []
  integration: []
  flows: []
tech_debt: []
nyquist:
  compliant_phases: [40, 41, 42, 43]
  partial_phases: []
  missing_phases: []
  overall: compliant
---
```

**Sections in the document body:**
1. Summary paragraph
2. Requirements Coverage table (`| Requirement | Phase | Summary Evidence | Final Status |`)
3. Phase Verification table (`| Phase | Name | Plans | Verification | Result |`)
4. Cross-Phase Integration table (brand artifacts connecting: token system → brand book → collateral → HexDocs)
5. End-to-End Flows (e.g., "Maintainer opens brand book from file:// and sees correct logo")
6. Nyquist Coverage (note: v1.5 phases are brand/design — no ExUnit tests; note this explicitly)
7. Verification Commands (the QA bash commands + `mix docs`)
8. Result line

**MILESTONES.md format** (from reading the file):
Each entry is an H2 heading `## vX.Y Name (Shipped: YYYY-MM-DD)` followed by:
- `**Phases completed:**` count line
- `**Key accomplishments:**` bullet list
- `**Audit:**` one-liner linking to the audit file

The v1.5 entry goes at the top of the file (newest first). [VERIFIED: direct file read]

---

## Architecture Patterns

### Recommended Project Structure After Phase 43

```
brandbook/
  index.html                 # brand book (done)
  tokens/tokens.css          # CSS custom properties (done)
  tokens/tokens.json         # machine-readable mirror (done)
  assets/parapet-logo.svg    # primary stacked (done)
  assets/parapet-inverse.svg # (done)
  assets/parapet-horizontal.svg  # (done)
  assets/parapet-horizontal-inverse.svg  # (done)
  assets/parapet-mark.svg    # (done)
  assets/parapet-mark-inverse.svg  # (done)
  assets/parapet-mono.svg    # (done)
  assets/favicon.svg         # (done)
  assets/parapet-tagline.svg # (done)
  assets/explorations/       # round-1 SVGs (keep, small)
  examples/components.html   # NEW — COLLAT-01
  examples/landing-section.html  # NEW — COLLAT-01
  examples/readme-header.svg     # NEW — COLLAT-01
  notes/research.md          # (done)
  notes/accessibility.md     # (done)
  notes/decision-log.md      # (done)
  notes/contrast.py          # (done)
  notes/logo-build.py        # (done)
  notes/logo-round-6.html    # keep (final round record)
  # DELETED: logo-options.html, logo-round-2..5.html
docs/assets/parapet-logo.svg  # REPLACED (COLLAT-02)
docs/assets/favicon.svg       # REPLACED (COLLAT-02)
```

### tokens.css Relative Path in examples/

The `examples/` directory is one level below `brandbook/`. Use:
```html
<link rel="stylesheet" href="../tokens/tokens.css">
```

For logo assets:
```html
<img src="../assets/parapet-inverse.svg" alt="Parapet">
```

These relative paths work for `file://` access.

### SVG readme-header: Inline vs. External

The `readme-header.svg` file has no access to `tokens.css` (SVGs do not load linked stylesheets reliably for `file://` usage in all contexts). Hardcode palette hex values inline on path/rect elements. Use only the 12 palette-approved hex values.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark mode | Custom JavaScript theme switcher | `data-theme="dark"` CSS attribute selector already in tokens.css | It works; keeps components consistent with brand book |
| Font loading | Custom `@font-face` declarations | Google Fonts CDN link (degrades gracefully offline) | Repo-lean constraint; self-hosted woff2 is deferred to v1.6 |
| Color variables in SVG | CSS var() in SVG attributes | Hardcoded hex (palette values only) | SVG `fill` attributes do not resolve CSS custom properties in `<img>` context |
| Logo paths | Re-generate from scratch | Copy from `brandbook/assets/` directly | Paths are already outlined, palette-locked, and audited |

---

## Common Pitfalls

### Pitfall 1: CSS vars in SVG `<img>` context

**What goes wrong:** Using `fill: var(--parapet-black)` in an SVG that ExDoc (or a browser) loads as an `<img>`. CSS custom properties are not resolved in the external SVG document context.
**Why it happens:** SVG loaded via `<img>` is isolated from the host page's CSS.
**How to avoid:** All logo assets already use hardcoded hex (`#101820`, `#256C82`) — do not introduce var() references into any SVG in `brandbook/assets/` or the readme-header.svg.

### Pitfall 2: Wrong relative path for examples/

**What goes wrong:** Using `href="tokens/tokens.css"` from `examples/components.html` — this resolves to `brandbook/examples/tokens/tokens.css`, which does not exist.
**How to avoid:** Always use `../tokens/tokens.css` and `../assets/parapet-logo.svg` from the `examples/` subdirectory.

### Pitfall 3: Stacked logo in ExDoc sidebar clipping

**What goes wrong:** `parapet-logo.svg` has a 183.9×106 viewBox — tall and narrow. ExDoc renders it in a sidebar at constrained width. If ExDoc constrains width, the tall stacked logo could appear very small or clipped.
**How to avoid:** Use `parapet-mark.svg` (32×52, tower-only) for `docs/assets/parapet-logo.svg` as the ExDoc logo, OR use the horizontal (252×62.5). Confirm with `mix docs` before committing.

### Pitfall 4: Off-palette status set hex in SVG

**What goes wrong:** Status colors (`#3F5E28`, `#EFF6E8`, `#B6C99A`, etc.) are not in the 12-value palette allow-list for the SVG audit. Using them in any `.svg` file (including readme-header.svg) will flag as off-palette.
**How to avoid:** The readme-header.svg should use only the 12 core palette colors. Status set colors are for UI components in HTML/CSS only.

### Pitfall 5: Touching mix.exs

**What goes wrong:** Unnecessary edits to `mix.exs` outside the doc block (or any edit at all, since the swap is path-stable).
**How to avoid:** The paths `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` are already correct in mix.exs (lines 59–60). Do not touch mix.exs.

### Pitfall 6: rgba() values in off-palette audit

**What goes wrong:** The off-palette grep only catches `#rrggbb` format. `rgba(16,24,32,0.12)` used for border and shadow tokens would not be caught by the grep pattern even if incorrect.
**How to avoid:** The rgba values in tokens.css are derived from palette hex (Parapet Black = `rgb(16,24,32)`, Limestone = `rgb(248,244,236)`). They are palette-correct. No action needed, but be aware the grep does not validate them.

---

## Validation Architecture

`nyquist_validation` key is absent from `.planning/config.json` → treat as enabled. However, v1.5 is brand/design assets only — there are no ExUnit test files to run. The validation surface for this phase is the QA gate defined in COLLAT-03.

### Phase Validation Surface

| Req ID | Behavior | Test Type | Command | Notes |
|--------|----------|-----------|---------|-------|
| COLLAT-01 | Examples open from file:// | Visual / headless screenshot | `"$CHROME" --headless=new … --screenshot=/tmp/out.png "file://$PWD/brandbook/examples/components.html"` | Manual visual confirm |
| COLLAT-01 | readme-header.svg renders | Visual | Open in browser or screenshot | — |
| COLLAT-02 | mix docs builds clean | Build check | `mix docs` | Zero errors/warnings |
| COLLAT-02 | New logo renders in ExDoc | Visual | `open doc/index.html` | Manual inspect sidebar |
| COLLAT-03 | Zero off-palette hex in assets | Automated grep | See QA Command 1 | Must output `OK` |
| COLLAT-03 | Zero raster/font binaries | Automated find | See QA Command 2 | Must produce no output |
| COLLAT-03 | brandbook/ within size budget | du check | `du -sh brandbook` | Must show ≤ ~250 KB |
| COLLAT-03 | Git diff scoped | Scope check | `git diff --name-only HEAD` | Only brandbook/ and docs/assets/*.svg |

### Wave 0 Gaps

None — no new test framework needed. The validation surface is entirely bash commands and visual inspection.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| mix / Elixir | COLLAT-02 verify | ✓ | OTP 28 / Erlang 16.3 | — |
| Google Chrome (headless) | COLLAT-01 visual verify | ✓ (macOS path confirmed in 43-CONTEXT.md) | — | `open file://…` in browser manually |
| git | COLLAT-03 diff scope check | ✓ | — | — |

---

## Security Domain

Not applicable. This phase touches only brand assets (SVG/HTML/CSS). No authentication, session management, data input, or cryptography involved. No ASVS categories apply.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)

- `brandbook/tokens/tokens.css` — complete token catalog with all CSS custom property names and values
- `brandbook/tokens/tokens.json` — machine-readable mirror confirming values
- `brandbook/index.html` — component markup classes, header/dark-theme patterns, Google Fonts link
- `brandbook/assets/*.svg` — all 9 final SVGs: viewBox dimensions, color usage confirmed
- `brandbook/notes/decision-log.md` — D-001 (anti-criteria), D-002 (acceptance checklist), D-003 (locked identity)
- `.planning/phases/43-collateral-wiring/43-CONTEXT.md` — QA commands, TODO list, non-negotiables
- `.planning/REQUIREMENTS.md` — COLLAT-01, COLLAT-02, COLLAT-03 definitions
- `.planning/milestones/v1.4-MILESTONE-AUDIT.md` — audit format template
- `.planning/MILESTONES.md` — entry format for v1.5
- `mix.exs` lines 59–60 — logo/favicon paths confirmed unchanged
- `docs/assets/parapet-logo.svg` — off-brand content confirmed (rect cage, Arial, off-palette)

### Verified QA runs (this session)

- Off-palette audit on `brandbook/assets/*.svg`: result `OK`
- Binary scan on `brandbook/`: zero hits
- `du -sh brandbook/`: 224 KB (baseline before examples added)

### Tertiary (LOW confidence)

- ExDoc sidebar logo rendering size [ASSUMED] — ExDoc renders as `<img>`; exact pixel constraints not read from ExDoc source. Confirms: eyeball `mix docs` before committing the logo choice.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | ExDoc sidebar constrains logo to ~48–64px height, making the stacked (106px tall) awkward | ExDoc Wiring | Planner picks mark for ExDoc logo; if stacked actually renders fine, horizontal or stacked would also work — no harm, just a visual preference |

---

## Open Questions

1. **Which asset for `docs/assets/parapet-logo.svg`?**
   - What we know: ExDoc renders as `<img>`; stacked is 106px tall, horizontal is 252px wide, mark is 32px wide
   - What's unclear: ExDoc's exact sidebar width constraint (not read from ExDoc source)
   - Recommendation: Start with `parapet-mark.svg` (most compact, reads best at small sizes), run `mix docs`, visually confirm. If the mark feels too spare without the wordmark, try `parapet-horizontal.svg`.

---

## Metadata

**Confidence breakdown:**
- Token catalog: HIGH — read directly from tokens.css/tokens.json
- Asset inventory: HIGH — read directly from SVG files with viewBox confirmed
- QA commands: HIGH — from 43-CONTEXT.md, dry-run executed this session
- ExDoc sidebar behavior: MEDIUM/LOW — inferred from ExDoc's known `<img>` rendering; exact size constraints assumed

**Research date:** 2026-06-24
**Valid until:** This research is stable until logo assets change (no expiry concern for a closed milestone)
