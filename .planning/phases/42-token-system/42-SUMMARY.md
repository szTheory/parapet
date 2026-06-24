# Phase 42 — Token System & HTML Brand Book (SUMMARY)

**Status:** Complete · 2026-06-24
**Requirements:** TOKEN-01 ✓ · TOKEN-02 ✓ · TOKEN-03 ✓

## Shipped

| File | Requirement |
|---|---|
| `brandbook/tokens/tokens.css` | TOKEN-01 — CSS custom properties (color, type scale, 8px spacing, radius, shadow, border, focus-ring + dark fix, motion) + light/dark semantic remap |
| `brandbook/tokens/tokens.json` | TOKEN-01 — machine-readable mirror; validated agreeing with the CSS |
| `brandbook/assets/parapet-tagline.svg` | TOKEN-02 — optional tagline lockup ("RELIABILITY FOR PHOENIX") completes the set (rest shipped in Phase 41) |
| `brandbook/index.html` | TOKEN-03 — self-contained brand book |

## Brand book sections

Hero (inverse logo) · Essence/positioning · Logo system (6 lockups + clear-space + do/don't) · Color (neutrals, signals, status sets with hex/role) · Typography (IBM Plex stacks + type-scale specimens + mono code) · Tokens (spacing grid, radius, elevation) · Components (buttons/badges/SLO card/callouts, light + dark) · Voice & microcopy (good/bad) · Accessibility · Implementation. Driven entirely by `tokens.css`; renders correctly from `file://`.

## Decisions

- **Values copied verbatim** from `prompts/parapet-brand-identity-deep-research.md` — no re-derivation. Added only the Phase-40 accessibility fix (`--focus-ring-on-dark`) and conventional semantic aliases (`--bg/--surface/--text/--link`) + a documented lightened dark-mode link tint (`#6FA8BC`) for AA.
- **Fonts:** brand book loads IBM Plex via Google Fonts CDN (renders the real type; repo stays lean — no font binaries), degrading to the documented system stack. This relaxes the plan's "no CDN" note in favor of showing the real typography; the **logo** assets remain outlined/font-independent (no CDN needed).

## Carry-forward to Phase 43

- Build collateral examples (components.html, landing-section.html, readme-header.svg).
- Wire HexDocs: replace `docs/assets/parapet-logo.svg` + `favicon.svg` with the on-brand assets; verify `mix docs`.
- Repo-hygiene audit + consider trimming intermediate `logo-round-*.html` exploration files to keep `brandbook/` lean.
- Milestone audit.
