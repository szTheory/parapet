---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Brand Book & Logo System
status: planning
last_updated: "2026-06-23T00:00:00.000Z"
last_activity: 2026-06-23
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-23 after v1.5 Brand Book & Logo System milestone started)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** v1.5 Brand Book & Logo System — Phase 40 (Brand Pressure-Test & Critique Gate)

## Current Position

Phase: 40 — Brand Pressure-Test & Critique Gate
Plan: —
Status: Ready to plan
Last activity: 2026-06-23 — Roadmap created for v1.5

Progress: `░░░░░░░░░░` 0% (0/4 phases complete)

## Performance Metrics

**Velocity:**

- Total plans completed: 18 (v1.3)
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 40 | 0 | — | — |
| 41 | 0 | — | — |
| 42 | 0 | — | — |
| 43 | 0 | — | — |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v1.5 scope: brand book and logo system only. No new runtime deps, public API changes, or library behavior changes — this milestone touches docs/brand assets only; the public surface stays frozen.
- Logo constraints (user-stated, non-negotiable): no rectangular background cage; unified mark+type (never icon-left-of-plain-text); no subtitle on the primary lockup (separate optional tagline lockup); ≥1 fully-integrated typemark; hand-authored SVG.
- Repo-lean constraint: SVG/HTML/CSS/JSON only — zero rasters, zero font binaries. Size budget ≤ ~250 KB for `brandbook/`.
- Phase 41 ends with a hard human gate (LOGO-04): user selects one direction before any downstream phase runs. Phases 42 and 43 are blocked on this selection.
- Source of truth: `prompts/parapet-brand-identity-deep-research.md` (1,874-line brand research). No re-derivation or re-litigating of brand strategy — operationalize only.
- HexDocs swap is zero-config path-stable: `docs/assets/parapet-logo.svg` and `docs/assets/favicon.svg` paths unchanged so `mix.exs` doc block requires no edits.
- [Phase 38]: Keep scoped route ownership in generated host-owned LiveView/component code rather than adding a Parapet router abstraction. — Preserves host auth/router ownership and Parapet core compile-out boundary. (carried from v1.4)
- [Phase 39]: Plan 02 preserved the original quality evaluation as a historical audit snapshot and appended a dated v1.4 closeout instead of rewriting prior findings. (carried from v1.4)

### Pending Todos

None.

### Blockers/Concerns

Phase 41 contains a hard human gate (LOGO-04). Execution must pause after the comparison gallery is built and wait for the user to record their logo selection in `brandbook/notes/decision-log.md` before Phase 42 can begin.

## Candidate Work

| Category | Item | Target | Status | Notes |
|----------|------|--------|--------|-------|
| Brand | Self-hosted webfont bundle (`@font-face` IBM Plex woff2) | v1.6+ | deferred | Requires font binary — excluded from repo-lean constraint |
| Brand | Raster exports (PNG/ICO favicons, OpenGraph social-card images) | v1.6+ | deferred | Raster-free constraint for this milestone |
| Brand | Token → Tailwind/daisyUI theme generator and HEEx snippets | v1.6+ | deferred | Separate milestone scope |
| Brand | Retheme generated Operator LiveView UI to new tokens | v1.6+ | deferred | Host-owned; separate milestone |
| Brand | Animated/motion logo, Figma source-of-truth, multi-page PDF brand book | future | deferred | Out of scope for v1.5 |

## Session Continuity

Last session: 2026-06-23
Stopped at: Roadmap created, STATE.md initialized for v1.5
Resume file: None
Next step: Plan Phase 40 with `/gsd-plan-phase 40`

## Operator Next Steps

- Plan Phase 40: `/gsd-plan-phase 40`
