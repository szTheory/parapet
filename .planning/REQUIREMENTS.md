# Requirements

## Milestone v1.5 Brand Book & Logo System

**Defined:** 2026-06-23
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

**Goal:** Operationalize the existing text-only brand research into a shippable, self-contained, repo-lean HTML brand book under `brandbook/` — with real on-brand hand-authored SVG logo assets (presented as options for selection), design tokens (CSS + JSON), and marketing/UI collateral — and replace the off-brand HexDocs logo/favicon.

**Source artifacts:** `prompts/parapet-brand-identity-deep-research.md` (1,874-line brand research, ground truth) · approved plan `/Users/jon/.claude/plans/existing-brand-book-is-jaunty-mitten.md`

## Brand Pressure-Test

- [ ] **BRAND-01**: A maintainer can read a single distilled brand reference (`brandbook/notes/research.md`) capturing the research doc's load-bearing values — color tokens with roles, type scale, spacing/radius/shadow tokens, voice rules, the four logo directions, and the AVOID list — each cited back to `prompts/parapet-brand-identity-deep-research.md`, with no value re-derived or invented.
- [ ] **BRAND-02**: Every text-on-surface token pairing in the brand palette is checked for WCAG AA contrast and recorded in `brandbook/notes/accessibility.md`, flagging any failing pair, so token usage in the brand book is provably accessible.
- [ ] **BRAND-03**: `brandbook/notes/decision-log.md` records why the existing `docs/assets/parapet-logo.svg`/`favicon.svg` are off-brand (off-palette `#0f172a`/`#38bdf8`, Arial, rectangular background cage, detached lockup) as explicit anti-criteria, alongside a frozen logo acceptance checklist (transparent, no cage, unified mark+type, no primary subtitle, ≥1 integrated typemark, palette-locked, favicon-legible at 16px).

## Logo System

- [ ] **LOGO-01**: Four distinct, on-brand, transparent-background logo directions are hand-authored as optimized SVGs grounded in named brand directions (stepped-parapet mark, integrated typemark, P-monogram, edge+sightline), including at least one fully-integrated custom typemark where the motif is worked into the wordmark itself.
- [ ] **LOGO-02**: A side-by-side comparison gallery (`brandbook/notes/logo-options.html`) renders every direction on Limestone / Deep Slate / Stone preview surfaces at hero, inline, and 16px sizes, each with a one-line rationale, openable from `file://` with no network dependency.
- [ ] **LOGO-03**: Each direction demonstrates it survives reduction — shown in single-ink monochrome and cropped to a 16px favicon — so small-size legibility is provable before a winner is chosen.
- [ ] **LOGO-04**: The user selects one direction (or a blend instruction) at the gallery gate, and the choice plus rationale is recorded in `decision-log.md` before any downstream token or brand-book build begins. *(Hard human gate — blocks Phases 42–43.)*

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
| BRAND-01 | 40 | Pending |
| BRAND-02 | 40 | Pending |
| BRAND-03 | 40 | Pending |
| LOGO-01 | 41 | Pending |
| LOGO-02 | 41 | Pending |
| LOGO-03 | 41 | Pending |
| LOGO-04 | 41 | Pending |
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
