# Roadmap

## Milestones

- [x] **v1.2 Authoring DX & Maturity** — Phases 30-33, 6 plans, shipped 2026-06-03. Archive: [v1.2-ROADMAP.md](milestones/v1.2-ROADMAP.md)
- [x] **v1.3 Operator UI Polish & Design System** — Phases 34-36, 4 plans, shipped 2026-06-04. Archive: [v1.3-ROADMAP.md](milestones/v1.3-ROADMAP.md)
- [x] **v1.4 Trust Hardening & Host-App Compatibility** — Phases 37-39, 8 plans, shipped 2026-06-04. Archive: [v1.4-ROADMAP.md](milestones/v1.4-ROADMAP.md)

## Current Work

**v1.5 Brand Book & Logo System** — started 2026-06-23

| Phase | Goal | Requirements | Status |
|-------|------|--------------|--------|
| 40 — Brand Pressure-Test & Critique Gate | De-risk before authoring: distill load-bearing brand values, build WCAG AA contrast matrix, freeze logo acceptance checklist | BRAND-01, BRAND-02, BRAND-03 | Not started |
| 41 — Logo Exploration & User Selection Gate | Author 4 distinct on-brand SVG logo directions, render comparison gallery, STOP for user selection | LOGO-01, LOGO-02, LOGO-03, LOGO-04 | Not started |
| 42 — Token System & HTML Brand Book | Emit tokens.css + tokens.json, expand selected logo into full variation set, build self-contained brand book | TOKEN-01, TOKEN-02, TOKEN-03 | Not started |
| 43 — Collateral, Wiring & QA/Audit Gate | COLLAT-01, COLLAT-02, COLLAT-03 | Complete |

### Phase Checklist

- [x] **Phase 40: Brand Pressure-Test & Critique Gate** - Distill brand reference, build WCAG AA matrix, freeze logo acceptance checklist
- [x] **Phase 41: Logo Exploration & User Selection Gate** - 6-round tournament → locked S2 (corbelled-tower stacked emblem, Space Grotesk); outlined asset set shipped
- [x] **Phase 42: Token System & HTML Brand Book** - tokens.css/json, full logo variation set, self-contained index.html brand book
- [x] **Phase 43: Collateral, Wiring & QA/Audit Gate** - Build collateral, swap HexDocs assets, pass hygiene audit

## Phase Details

### Phase 40: Brand Pressure-Test & Critique Gate

**Goal**: A maintainer has a distilled, cite-backed brand reference, a proven WCAG AA contrast matrix, and a frozen logo acceptance checklist — all before any SVG is authored.

**Depends on**: Nothing (first phase)

**Requirements**: BRAND-01, BRAND-02, BRAND-03

**Success Criteria** (what must be TRUE):

  1. A maintainer can open `brandbook/notes/research.md` and read the load-bearing values (color tokens with roles, type scale, spacing/radius/shadow tokens, voice rules, the four logo directions, and the AVOID list) — each with a citation back to `prompts/parapet-brand-identity-deep-research.md` — without needing to read the 1,874-line source doc.
  2. Every text-on-surface token pairing in the brand palette has a recorded WCAG AA contrast result in `brandbook/notes/accessibility.md`, with any failing pair flagged, so token usage in the brand book is provably accessible before any HTML is written.
  3. `brandbook/notes/decision-log.md` names the exact off-brand properties of `docs/assets/parapet-logo.svg`/`favicon.svg` (off-palette `#0f172a`/`#38bdf8`, Arial, rectangular background cage, detached lockup) as anti-criteria, alongside a frozen logo acceptance checklist (transparent, no cage, unified mark+type, no primary subtitle, ≥1 integrated typemark, palette-locked, favicon-legible at 16px).
  4. No value in any output file is invented or re-derived — every token, rule, and direction is traceable to the research doc.

**Plans**: TBD

---

### Phase 41: Logo Exploration & User Selection Gate

**Goal**: Four distinct, on-brand, hand-authored SVG logo directions are rendered side-by-side in a `file://`-openable comparison gallery, and the user selects one before any downstream token or brand-book build begins.

**Depends on**: Phase 40

**Requirements**: LOGO-01, LOGO-02, LOGO-03, LOGO-04

**Blocking note**: This phase ends with a **HARD HUMAN GATE** (LOGO-04). Phase 42 and Phase 43 are **blocked** until the user selects a direction and records the choice in `decision-log.md`. No downstream phase may begin until this selection is committed.

**Success Criteria** (what must be TRUE):

  1. Four distinct SVG logo directions (stepped-parapet mark, integrated typemark, P-monogram, edge+sightline) are hand-authored as optimized, transparent-background SVGs — including at least one fully-integrated custom typemark where the motif is worked into the wordmark itself — with no rectangular background cage and no subtitle on the primary lockup.
  2. A `file://`-openable `brandbook/notes/logo-options.html` renders all four directions side-by-side on Limestone, Deep Slate, and Stone preview surfaces at hero, inline, and 16px sizes, each with a one-line rationale, requiring no network connection.
  3. Each direction is shown in single-ink monochrome and cropped to a 16px favicon thumbnail, so small-size legibility is provable before the user commits to a winner.
  4. The user has selected one direction (or issued a blend instruction), and the choice plus rationale is recorded in `brandbook/notes/decision-log.md` — this record must exist before Phase 42 begins.

**Plans**: TBD

**UI hint**: yes

---

### Phase 42: Token System & HTML Brand Book

**Goal**: Design tokens (CSS + JSON) verbatim from the research doc are on disk, the selected logo is expanded into its full variation set, and a self-contained `file://`-openable HTML brand book presents the complete system.

**Depends on**: Phase 41 (user selection gate must be complete)

**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03

**Success Criteria** (what must be TRUE):

  1. `brandbook/tokens/tokens.css` and `brandbook/tokens/tokens.json` express the research doc's color, type-scale, spacing (8px grid), radius, shadow, and border tokens verbatim — with no new values invented and no re-derivation — and both files agree on every value.
  2. The selected logo is expanded into at least eight named variation files in `brandbook/assets/` — primary horizontal lockup (no subtitle), integrated typemark, icon-only logomark, stacked, monochrome, inverse/dark-background, optional tagline lockup, and favicon — all as optimized transparent SVGs.
  3. `brandbook/index.html` opens correctly from `file://` with no build step and no network dependency, and displays the logo gallery (transparent default + preview swatches), color system (swatch + hex + role), type-scale specimens, spacing/radius/shadow tokens, voice/tone + microcopy, logo do/don't, and accessibility notes.
  4. Every color, size, and spacing value visible in the brand book is driven by `tokens.css` custom properties — no hardcoded hex or pixel values appear in the HTML/CSS output.

**Plans**: TBD

**UI hint**: yes

---

### Phase 43: Collateral, Wiring & QA/Audit Gate

**Goal**: Token-driven collateral examples are built, the off-brand HexDocs assets are replaced with zero-config path-stable swaps, and the repo passes the hygiene audit.

**Depends on**: Phase 42

**Requirements**: COLLAT-01, COLLAT-02, COLLAT-03

**Success Criteria** (what must be TRUE):

  1. Three collateral artifacts open correctly from `file://` — `brandbook/examples/components.html` (buttons, cards, badges, callouts), `brandbook/examples/landing-section.html` (Deep Slate hero with restrained stepped mark), and `brandbook/examples/readme-header.svg` (README/social banner) — each driven by the token system.
  2. `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` are replaced with the on-brand winners; `mix.exs` doc block paths are unchanged; and `mix docs` renders the new mark without error or warning.
  3. The repo-hygiene audit passes: `brandbook/` is within the ≤ ~250 KB size budget, contains zero raster or font binaries, has no full-viewBox rectangular background in any logo asset, and has no off-palette hex in any SVG or CSS file.
  4. The git diff for this milestone is scoped exclusively to `brandbook/`, the two `docs/assets/*.svg` files, and the `mix.exs` doc block — no unrelated files are touched.

**Plans**: 3/3 plans complete

- [x] 43-01-PLAN.md — COLLAT-01: collateral examples (components.html, landing-section.html, readme-header.svg)
- [x] 43-02-PLAN.md — COLLAT-02: zero-config HexDocs logo/favicon swap + trim exploration HTMLs
- [x] 43-03-PLAN.md — COLLAT-03: repo-hygiene QA gate + v1.5 milestone audit + ledger updates

---

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 40. Brand Pressure-Test & Critique Gate | 1/1 | Complete | 2026-06-23 |
| 41. Logo Exploration & User Selection Gate | 6/6 | Complete | 2026-06-24 |
| 42. Token System & HTML Brand Book | 3/3 | Complete | 2026-06-24 |
| 43. Collateral, Wiring & QA/Audit Gate | 3/3 | Complete | 2026-06-24 |
