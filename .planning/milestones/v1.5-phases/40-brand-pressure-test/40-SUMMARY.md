# Phase 40 — Brand Pressure-Test & Critique Gate (SUMMARY)

**Status:** Complete · 2026-06-23
**Requirements:** BRAND-01 ✓ · BRAND-02 ✓ · BRAND-03 ✓

## What shipped

| File | Requirement | Notes |
|---|---|---|
| `brandbook/notes/research.md` | BRAND-01 | Distilled brand reference — colors+roles, type scale, spacing/radius/shadow, voice/microcopy, 4 logo directions, AVOID list. Every value cited `§N L#` to the source doc; nothing re-derived. |
| `brandbook/notes/accessibility.md` | BRAND-02 | WCAG AA matrix — 26 text pairings (all pass) + status sets + UI/non-text. Computed, not estimated. |
| `brandbook/notes/contrast.py` | BRAND-02 | Reproducible contrast calculator (WCAG 2.1 relative luminance). |
| `brandbook/notes/decision-log.md` | BRAND-03 | Off-brand critique (A1–A5 anti-criteria) + frozen 10-point logo acceptance checklist + open D-003 selection slot. |

## Key findings

1. **Palette is accessible as specified** — 100% of text-on-surface pairings meet WCAG AA (lowest 4.58:1). No recoloring needed.
2. **Focus ring fails on dark surfaces** — Watch Blue `#256C82` is only 2.70:1 on Deep Slate (< 3:1 for focus indicators). → New rule: light focus ring (`#F8F4EC`) on dark; encode `--focus-ring` + `--focus-ring-on-dark` in Phase 42 tokens.
3. **Existing logo confirmed off-brand on 5 counts** — rectangular cage, Tailwind off-palette colors (`#0f172a`/`#38bdf8`), Arial, detached lockup, neon feel. These are now explicit anti-criteria; replaced in Phase 43.

## Carry-forward to later phases

- **Phase 41:** judge all 4 logo directions against the frozen acceptance checklist; prove mono + 16px reduction.
- **Phase 42:** tokens.css must add `--focus-ring-on-dark`; status chips must pair color + word + icon (never color alone).
- **Phase 43:** QA grep for off-palette hex must catch any stray `#0f172a`/`#38bdf8`.

## Deviations

- Added `brandbook/notes/contrast.py` (not in original manifest) so the contrast matrix is reproducible rather than asserted. Tiny (~2.8 KB), self-contained, justified by BRAND-02's "provably accessible" bar.
