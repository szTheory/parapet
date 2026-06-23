# Phase 41 — Logo Exploration & User Selection Gate (PLAN)

**Milestone:** v1.5 Brand Book & Logo System
**Requirements:** LOGO-01, LOGO-02, LOGO-03, LOGO-04
**Goal:** Hand-author 4 distinct on-brand SVG logo directions, render them side-by-side, and STOP for the user to pick one. Hard human gate before Phase 42.

## Approach

Author each direction grounded in a named brand direction (research.md §3). Judge against the frozen acceptance checklist (decision-log D-002). Use live IBM Plex Sans for exploration wordmarks (fair direction comparison); the winning wordmark is hand-refined to outlined paths in Phase 42. Verify visually via headless-Chrome renders before presenting.

## Directions

- **A — Stepped parapet** (§6.2-1): low crenellated wall, signal sightline through the openings, shared ground line.
- **B — Integrated typemark** (required): the wordmark stands on a stepped parapet wall + sightline; no separate icon.
- **C — P-as-parapet monogram** (§6.2-2): squared P, crenellated bowl, signal slot through the counter; avatar-first.
- **D — Edge & sightline** (§6.2-3): low wall + wordmark share one continuous sightline; stone horizon above.

## Tasks

1. **LOGO-01** — author `explorations/option-{a,b,c,d}.svg` (lockups) + `-mark.svg` (favicons): transparent, palette-locked, unified mark+type, ≥1 integrated typemark (B).
2. **LOGO-02** — `notes/logo-options.html`: each direction on Limestone/Deep Slate/Stone × hero/inline/16px + rationale; opens from `file://`.
3. **LOGO-03** — prove mono (grayscale) + 16px favicon reduction in the gallery.
4. **LOGO-04 (GATE)** — present to user; record the chosen direction + tweaks in `decision-log.md` D-003. **Blocks Phase 42.**

## Done when

- 4 directions exist as valid, transparent, palette-locked SVGs and render correctly.
- Gallery opens from `file://` and shows all directions across surfaces/sizes.
- User has selected a direction (recorded in decision-log) — only then is the phase complete.

## Note / deviation

Exploration wordmarks use live IBM Plex Sans (font-dependent) rather than outlined paths, to compare directions fairly without hand-tracing four wordmarks. The winner's wordmark is converted to outlined, font-independent paths in Phase 42 (where it matters and is done once). Dark-surface cells intentionally show the un-inverted mark to motivate the Phase 42 inverse variant.
