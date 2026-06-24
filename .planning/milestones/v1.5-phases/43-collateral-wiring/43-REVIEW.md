---
phase: 43-collateral-wiring
reviewed: 2026-06-24T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - brandbook/examples/components.html
  - brandbook/examples/landing-section.html
  - brandbook/examples/readme-header.svg
  - docs/assets/parapet-logo.svg
  - docs/assets/favicon.svg
findings:
  critical: 1
  warning: 3
  info: 2
  total: 6
status: issues_found
---

# Phase 43: Code Review Report

**Reviewed:** 2026-06-24
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Five static brand assets reviewed: two HTML component/landing examples and three SVG files (readme banner, logo, favicon). All files are well-formed and parse cleanly. All CSS custom property references in the HTML files resolve to defined tokens. No off-brand hex colors appear anywhere. No unintended external network calls exist beyond the declared Google Fonts link.

Three substantive issues were found. The most impactful is the `favicon.svg` being non-square (32×52), which will cause the tower mark to render noticeably smaller or distorted in browser tab favicon areas. The `landing-section.html` hero ghost button has a nearly invisible border on its dark background due to wrong token tier. The `components.html` description text makes a false claim about having no hardcoded px values.

---

## Critical Issues

### CR-01: `favicon.svg` non-square dimensions cause distorted/undersized tab icon

**File:** `docs/assets/favicon.svg:1`

**Issue:** `favicon.svg` has `width="32" height="52"` with `viewBox="4 6 32 52"` — a portrait aspect ratio of 32:52. Browsers render favicons into a square icon space (typically 16×16 or 32×32). A non-square SVG favicon is either stretched to fill the square (distorting the corbelled tower into a squashed shape) or letterboxed (resulting in an ~10px effective render width at 16px size, making the tower barely legible). `mix.exs` confirms this file is wired to HexDocs as the favicon (`favicon: "docs/assets/favicon.svg"`), so this is a production concern.

The mark path data spans x: 7–33 (26 units wide) and y: 10–56 (46 units tall) in SVG coordinate space. The viewBox correctly crops to the mark, but the intrinsic shape is portrait, not square. A square viewBox needs to be established with equal padding on the narrow axis.

**Fix:** Add horizontal whitespace to the viewBox so the contained region is square, then update `width`/`height` to match:

```svg
<!-- Before -->
<svg viewBox="4 6 32 52" width="32" height="52" ...>

<!-- After: viewBox widens to make the 32-unit wide crop square by matching the 52-unit height -->
<!-- Tower x spans 7-33 (26 units), centering in a 52-unit square starting at x=7 leaves 26 units of spare H space -->
<!-- Expand left/right margin: (52-26)/2 = 13 units each side => x_min = 7-13 = -6, width = 52 -->
<svg viewBox="-6 6 52 52" width="32" height="32" role="img" aria-label="Parapet">
```

Adjust exact x_min to taste for optical centering — the key requirement is that the viewBox width equals its height. The `docs/assets/parapet-logo.svg` file is identical and should receive the same fix if it is used in any square-constrained context (HexDocs sidebar typically does not require a square, but unifying the aspect ratio is lower-risk).

---

## Warnings

### WR-01: `landing-section.html` ghost button border nearly invisible on dark hero

**File:** `brandbook/examples/landing-section.html:42`

**Issue:** `.btn-ghost` sets `border-color: var(--border)`. The hero section uses `background: var(--deep-slate)` directly (not via `data-theme="dark"`), so `--border` resolves to its light-surface value: `rgba(16, 24, 32, 0.12)`. Composited over `#18232B` (deep-slate), this produces `rgb(23, 33, 41)` against a background of `rgb(24, 35, 43)` — a delta of ~1–2 per channel, which is essentially invisible. The "View on GitHub" ghost button will appear borderless in practice.

The token system already provides `--border-dark: 1px solid rgba(248, 244, 236, 0.16)` for exactly this situation; the hero simply needs to use it.

**Fix:**
```css
/* Replace in landing-section.html .btn-ghost rule */
.btn-ghost {
  background: transparent;
  color: var(--limestone);
  border-color: var(--border-dark);   /* was var(--border) — wrong tier for dark surface */
}
```

Alternatively, add `data-theme="dark"` to the `.hero` element so the CSS cascade remaps `--border` automatically and dark-mode overrides are inherited by all descendant components.

---

### WR-02: `components.html` claims no hardcoded px but contains many

**File:** `brandbook/examples/components.html:105`

**Issue:** The page description reads: *"Every color, size, and spacing value comes from `../tokens/tokens.css` custom properties — no hardcoded hex or px in this file."* This claim is false. The `<style>` block contains numerous hardcoded pixel values that are not sourced from tokens: `9px 16px` button padding, `6px` badge gap, `3px 10px` badge padding, `10px` status dot size, `8px 12px` input padding, `72px` textarea min-height, and `1080px` max-width. The `8px` button border-radius is even called out in `tokens.css` as intentionally not a token, but it still contradicts the stated claim.

This is a documentation-correctness defect: adopters reading this as a reference implementation will have a false understanding of how completely tokenized the system is.

**Fix:** Update the description to accurately reflect what is and is not tokenized:

```html
<!-- Before -->
<p class="lead">Token-driven components shown in light and dark. Every color, size, and spacing
value comes from <code>../tokens/tokens.css</code> custom properties — no hardcoded hex or px
in this file.</p>

<!-- After -->
<p class="lead">Token-driven components shown in light and dark. All <strong>colors</strong> and
<strong>spacing</strong> values come from <code>../tokens/tokens.css</code> custom properties.
Component-level micro-geometry (button padding, badge sizing, border widths) uses intentional
hardcoded values per the token spec.</p>
```

---

### WR-03: Button horizontal padding inconsistency between `components.html` and `landing-section.html`

**File:** `brandbook/examples/components.html:40`, `brandbook/examples/landing-section.html:39`

**Issue:** The `.btn` rule has different horizontal padding in the two files: `9px 16px` in `components.html` and `9px 18px` in `landing-section.html`. If these files are used as reference implementations to copy button styles into a real UI, the inconsistency will produce differently-sized buttons from the "same" component.

**Fix:** Align horizontal padding to a single canonical value. `18px` maps cleanly to `var(--space-5)` (24px) minus `var(--space-2)` (8px) = 16px, or use the space token directly. Pick one and apply it to both files:

```css
/* Canonical: use 16px (components.html value) or 18px (landing-section.html value) — pick one */
.btn { padding: 9px 16px; }  /* apply in both files */
```

---

## Info

### IN-01: SVGs omit `<title>` child element (aria-label present, JAWS compatibility gap)

**Files:** `brandbook/examples/readme-header.svg:1`, `docs/assets/parapet-logo.svg:1`, `docs/assets/favicon.svg:1`

**Issue:** All three SVGs use `role="img"` with `aria-label` but omit a `<title>` child element. WCAG 2.1 and ARIA 1.2 both accept `aria-label` on an SVG with `role="img"` as sufficient for screen reader support. However, JAWS (market-leading Windows screen reader) historically reads `<title>` more reliably than `aria-label` on SVG elements when served inline or as HexDocs HTML. Adding `<title>` costs nothing and improves cross-reader robustness.

**Fix:**
```svg
<svg ... role="img" aria-labelledby="svg-title-id">
  <title id="svg-title-id">Parapet</title>
  ...
</svg>
```

---

### IN-02: `readme-header.svg` tagline font (IBM Plex Mono) will not render on GitHub

**File:** `brandbook/examples/readme-header.svg:32`

**Issue:** The tagline `<text>` element specifies `font-family="'IBM Plex Mono', 'SFMono-Regular', Consolas, monospace"`. When GitHub renders an SVG embedded as a README `<img>`, it sandboxes the SVG and blocks external font loading (no Google Fonts, no CDN). IBM Plex Mono will not load; the browser falls back to `SFMono-Regular` or `Consolas`. The wordmark is correctly outlined paths (font-independent), so only the tagline is affected. The fallback stack is reasonable monospace and likely matches well visually, but the precise letterforms will differ from the brand spec.

The file's own comment (`Hex values are hardcoded from the 12-value palette only (no CSS vars — SVG file context)`) correctly acknowledges the SVG context, but the font limitation is undocumented.

**Fix (option A — minimal):** Add a comment to `readme-header.svg` documenting the known fallback:
```xml
<!-- NOTE: IBM Plex Mono is referenced but will not load when served as <img> on GitHub.
     Fallback stack (SFMono-Regular → Consolas → monospace) is acceptable. -->
```

**Fix (option B — pixel-perfect):** Outline the tagline text into paths (same technique used for the wordmark), eliminating the font dependency entirely. This is the fully brand-safe approach if exact letterform control matters for the banner.

---

_Reviewed: 2026-06-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
