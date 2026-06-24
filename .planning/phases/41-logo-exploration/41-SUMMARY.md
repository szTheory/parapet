# Phase 41 — Logo Exploration & User Selection Gate (SUMMARY)

**Status:** Complete · 2026-06-24
**Requirements:** LOGO-01 ✓ · LOGO-02 ✓ · LOGO-03 ✓ · LOGO-04 ✓ (gate cleared)

## Outcome

Locked the Parapet identity after a **6-round** interactive tournament: a **stacked emblem** — a **corbelled parapet tower** (reads as a parapet/chess-rook, survives 16px) above **PARAPET** in **Space Grotesk** tight caps, with a single **Watch Blue `#256C82`** loophole accent.

## Rounds (all committed as provenance)

| Round | File | Result |
|---|---|---|
| 1 | `logo-options.html` | A/B/C/D icon-beside-text — rejected (not integrated) |
| 2 | `logo-round-2.html` | carved-crenellation wordmark — picked "Rook P lead" |
| 3 | `logo-round-3.html` | 9 rook-P variants — rejected (hand-built letters = crude 8-bit) |
| 4 | `logo-round-4.html` | 6 fresh directions, real OFL type — rook-tower concept liked |
| 5 | `logo-round-5.html` | corbelled tower × font/layout/sizing — picked stacked emblem |
| 6 | `logo-round-6.html` | deep stacked-emblem tournament — **locked S2** |

## Final assets (`brandbook/assets/`)

`parapet-logo.svg` (primary stacked) · `parapet-inverse.svg` · `parapet-mono.svg` · `parapet-horizontal.svg` (+ `-inverse`) · `parapet-mark.svg` (+ `-inverse`) · `favicon.svg`. All transparent, palette-locked, **outlined paths (font-independent)**, ≤1.8 KB each, no background cage, no primary subtitle.

## Key decisions / lessons

- **Don't hand-build letterforms** from rectangles — reads as crude 8-bit. Use real, well-drawn typefaces.
- Explore with **open (OFL) fonts** so the chosen look is shippable; **outline to paths** with `fonttools` (from the woff2) for a font-independent asset — no font binary committed, renders identically in HexDocs.
- Logo type = **Space Grotesk** (user-approved deviation from the doc's IBM Plex Sans); IBM Plex remains the UI/docs/code typeface.
- Tower kept restrained (a low tower, not a fortress) to respect the brand's calm, anti-castle posture while honoring the user's rook idea.

## Carry-forward to Phase 42

- Use `parapet-logo.svg` etc. as the canonical assets in the brand book gallery.
- `tokens.css` must include the logo's outlined approach note; UI type stays IBM Plex.
- Consider removing intermediate round HTMLs in Phase 43 QA to keep `brandbook/` lean (kept now as provenance).
