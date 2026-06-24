# Requirements

## Milestone v1.5 Brand Book & Logo System

**Defined:** 2026-06-23
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

**Goal:** Operationalize the existing text-only brand research into a shippable, self-contained, repo-lean HTML brand book under `brandbook/` — with real on-brand hand-authored SVG logo assets (presented as options for selection), design tokens (CSS + JSON), and marketing/UI collateral — and replace the off-brand HexDocs logo/favicon.

**Source artifacts:** `prompts/parapet-brand-identity-deep-research.md` (1,874-line brand research, ground truth) · approved plan `/Users/jon/.claude/plans/existing-brand-book-is-jaunty-mitten.md`

## Brand Pressure-Test

- [x] **BRAND-01**: A maintainer can read a single distilled brand reference (`brandbook/notes/research.md`) capturing the research doc's load-bearing values — color tokens with roles, type scale, spacing/radius/shadow tokens, voice rules, the four logo directions, and the AVOID list — each cited back to `prompts/parapet-brand-identity-deep-research.md`, with no value re-derived or invented.
- [x] **BRAND-02**: Every text-on-surface token pairing in the brand palette is checked for WCAG AA contrast and recorded in `brandbook/notes/accessibility.md`, flagging any failing pair, so token usage in the brand book is provably accessible.
- [x] **BRAND-03**: `brandbook/notes/decision-log.md` records why the existing `docs/assets/parapet-logo.svg`/`favicon.svg` are off-brand (off-palette `#0f172a`/`#38bdf8`, Arial, rectangular background cage, detached lockup) as explicit anti-criteria, alongside a frozen logo acceptance checklist (transparent, no cage, unified mark+type, no primary subtitle, ≥1 integrated typemark, palette-locked, favicon-legible at 16px).

## Logo System

- [x] **LOGO-01**: On-brand, transparent-background logo directions hand-authored as optimized SVGs grounded in named brand directions, including a fully-integrated typemark. *(Delivered across 6 rounds; final = corbelled-parapet-tower stacked emblem.)*
- [x] **LOGO-02**: Side-by-side comparison galleries (`logo-options.html`, `logo-round-2..6.html`) render directions on Limestone / Deep Slate / Stone at multiple sizes, openable from `file://`.
- [x] **LOGO-03**: Each direction proven in single-ink monochrome and at 16px favicon before selection.
- [x] **LOGO-04**: User locked **S2** (Space Grotesk tight-caps stacked emblem); choice + 6-round rationale recorded in `decision-log.md` D-003. Final outlined asset set in `brandbook/assets/`. *(Gate cleared.)*

## Token System & HTML Brand Book

- [ ] **TOKEN-01**: `brandbook/tokens/tokens.css` (CSS custom properties) and `brandbook/tokens/tokens.json` (same values, machine-readable) express the research doc's color, type-scale, spacing (8px grid), radius, shadow, and border tokens verbatim, with no new values invented.
- [ ] **TOKEN-02**: The selected logo is expanded into the full variation set as separate optimized transparent SVGs in `brandbook/assets/` — primary horizontal lockup (no subtitle), integrated typemark, icon-only logomark, stacked, monochrome, inverse/dark-background, optional tagline lockup, and favicon.
- [ ] **TOKEN-03**: A self-contained `brandbook/index.html` brand book — driven by `tokens.css` — presents the logo gallery (transparent default, on preview swatches), color system (swatch + hex + role), type-scale specimens, spacing/radius/shadow tokens, voice/tone + microcopy, logo do/don't, and accessibility notes, and opens correctly from `file://` with no build step or network dependency.

## Collateral, Wiring & QA

- [ ] **COLLAT-01**: Implementation-ready collateral is built on the tokens — `brandbook/examples/components.html` (buttons/cards/badges/callouts), `brandbook/examples/landing-section.html` (Deep Slate hero with a restrained stepped mark), and `brandbook/examples/readme-header.svg` (README/social banner) — each opening from `file://`.
- [ ] **COLLAT-02**: The off-brand `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` are replaced with the on-brand winners, `mix.exs` logo/favicon paths are left unchanged (zero-config swap), and `mix docs` renders the new mark without error.
- [ ] **COLLAT-03**: A repo-hygiene audit passes — `brandbook/` within the size budget (≤ ~250 KB), zero raster/font binaries, no full-viewBox rectangular background in any logo asset, no off-palette hex in any SVG/CSS, and the git diff scoped to `brandbook/`, the two `docs/assets/*.svg`, and the `mix.exs` doc block.

## Future Requirements

Tracked but deferred — not in this milestone's roadmap.

- Self-hosted webfont bundle (`@font-face` IBM Plex woff2) for pixel-consistent offline rendering.
- Raster exports: PNG/ICO favicons and OpenGraph social-card images.
- Token → Tailwind/daisyUI theme generator and HEEx component snippets for the generated Operator UI.
- Retheme the generated Operator LiveView UI to the new tokens (host-owned; separate milestone).
- Animated/motion logo, Figma source-of-truth, multi-page PDF brand book.

## Out Of Scope

Explicitly excluded for this milestone, with reasoning, to prevent scope creep.

| Exclusion | Reason |
|---|---|
| Rectangular background "cage" on any logomark | User constraint — transparent/background-free is the default; backgrounds appear only as gallery preview swatches |
| Subtitle/slogan on the primary logo lockup | User constraint — taglines live only in a separate optional lockup |
| Generic icon-left-of-plain-text lockups | User constraint — mark and type must be visually unified |
| Large binary artifacts (rasters, font files) | Repo-lean, vector-first only — binaries get out of control if not contained |
| New runtime deps, public API changes, library behavior changes | This milestone touches docs/brand assets only; the public surface stays frozen |
| Re-deriving or "improving" the brand strategy / palette / voice | The research doc is the source of truth; this milestone operationalizes, it does not re-litigate |

## Traceability

| Requirement | Phase | Status |
|---|---:|---|
| BRAND-01 | 40 | Complete |
| BRAND-02 | 40 | Complete |
| BRAND-03 | 40 | Complete |
| LOGO-01 | 41 | Complete |
| LOGO-02 | 41 | Complete |
| LOGO-03 | 41 | Complete |
| LOGO-04 | 41 | Complete |
| TOKEN-01 | 42 | Pending |
| TOKEN-02 | 42 | Pending |
| TOKEN-03 | 42 | Pending |
| COLLAT-01 | 43 | Pending |
| COLLAT-02 | 43 | Pending |
| COLLAT-03 | 43 | Pending |

**Coverage:**
- v1.5 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0 ✓

---
*Requirements defined: 2026-06-23*
*Last updated: 2026-06-23 after initial definition*
