# Phase 40 — Brand Pressure-Test & Critique Gate (PLAN)

**Milestone:** v1.5 Brand Book & Logo System
**Requirements:** BRAND-01, BRAND-02, BRAND-03
**Goal:** De-risk before authoring any asset — produce a distilled, cite-backed brand reference, a proven WCAG AA contrast matrix, and a frozen logo acceptance checklist.

## Approach

Content-only phase (no SVG yet). Read the 1,874-line brand research doc in full; distill the load-bearing values into `brandbook/notes/` with line citations; compute (not estimate) contrast; freeze acceptance criteria from the off-brand critique.

## Tasks

1. **research.md** (BRAND-01) — distill colors+roles, type scale, spacing/radius/shadow, voice/microcopy, the 4 logo directions, and the AVOID list, each cited `§N L#` to `prompts/parapet-brand-identity-deep-research.md`. No re-derivation.
2. **accessibility.md** (BRAND-02) — compute WCAG AA contrast for every text-on-surface token pair + status sets + focus ring + key non-text pairs via `brandbook/notes/contrast.py`; record pass/fail; capture actionable findings.
3. **decision-log.md** (BRAND-03) — record the off-brand defects of `docs/assets/*.svg` as anti-criteria (A1–A5) and a frozen logo acceptance checklist; open the D-003 selection slot for Phase 41.

## Done when

- All three notes exist, open as plain Markdown, and contain only cited/computed values.
- Contrast matrix is reproducible (`python3 brandbook/notes/contrast.py`).
- Acceptance checklist is frozen and maps each item to an anti-criterion or constraint.
