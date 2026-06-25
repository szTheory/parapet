---
gsd_state_version: 1.0
milestone: v1.6
milestone_name: Operator UI Brand & Design-System Audit
status: executing
stopped_at: Phase 45 UI-SPEC approved
last_updated: "2026-06-25T15:53:03.015Z"
last_activity: 2026-06-25
progress:
  total_phases: 7
  completed_phases: 1
  total_plans: 8
  completed_plans: 5
  percent: 14
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-24 after v1.5 Brand Book & Logo System milestone completed)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 45 — primitive-components

## Current Position

Phase: 45 (primitive-components) — EXECUTING
Plan: 2 of 4
Status: Ready to execute
Last activity: 2026-06-25

## Performance Metrics

**Velocity:**

- Total plans completed: 21 (v1.3)
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 40 | 0 | — | — |
| 41 | 0 | — | — |
| 42 | 0 | — | — |
| 43 | 3 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 43 P01 | 268 | - tasks | - files |
| Phase 43 P02 | 180 | 2 tasks | 7 files |
| Phase 43 P03 | 225 | 3 tasks | 4 files |
| Phase 44 P03 | 22m | 2 tasks | 3 files |
| Phase 44 P04 | 5m45s | 2 tasks | 4 files |

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
- [Phase ?]: Codeblock tint hex excluded from examples/ to pass palette gate; use var(--stone) spans
- [Phase ?]: readme-header.svg tagline as <text> element (IBM Plex Mono) — practical for README banner, palette-clean
- [Phase ?]: parapet-mark.svg chosen for ExDoc sidebar logo — most compact 32x52 viewBox, mix docs clean
- [Phase ?]: Zero-config path-stable HexDocs swap complete: mix.exs unchanged, five exploration HTMLs deleted
- [Phase ?]: Use File.cp! for woff2 binary copy to avoid Igniter string-encoding corruption
- [Phase ?]: IBM Plex latin woff2 vendored via python3 fontTools.subset: 53 KB total, 65% under 150 KB ceiling
- [Phase ?]: Gallery route isolated to demo router only (live_session :parapet_gallery, D-13)
- [Phase ?]: Audit matrix initialized with todo status; #7FB4C6 dark-link operator exception documented for Phase-50 GUARD-04 (D-07/D-08)
- [Phase ?]: Dark warning button fg corrected to #101820 (parapet-black) on #D97706 bg: 5.62:1 WCAG AA pass; original plan specified #F8F4EC which yielded 2.9:1
- [Phase ?]: @themes re-pinned to brand token hexes: six status triplets, dark links on surface+bg (#7FB4C6 D-07), focus rings at 3:1 floor

### Pending Todos

None.

### Blockers/Concerns

None. The Phase 41 human gate (LOGO-04) is RESOLVED — user locked the stacked-emblem identity (decision-log.md D-003). Phase 43's only outward-facing change is the HexDocs logo/favicon swap (user pre-approved; zero-config, path-stable).

## Candidate Work

| Category | Item | Target | Status | Notes |
|----------|------|--------|--------|-------|
| Brand | Self-hosted webfont bundle (`@font-face` IBM Plex woff2) | v1.6+ | deferred | Requires font binary — excluded from repo-lean constraint |
| Brand | Raster exports (PNG/ICO favicons, OpenGraph social-card images) | v1.6+ | deferred | Raster-free constraint for this milestone |
| Brand | Token → Tailwind/daisyUI theme generator and HEEx snippets | v1.6+ | deferred | Separate milestone scope |
| Brand | Retheme generated Operator LiveView UI to new tokens | v1.6+ | deferred | Host-owned; separate milestone |
| Brand | Animated/motion logo, Figma source-of-truth, multi-page PDF brand book | future | deferred | Out of scope for v1.5 |

## Session Continuity

Last session: 2026-06-25T15:53:03.010Z
Stopped at: Phase 45 UI-SPEC approved
Resume file: None
Next step: Plan Phase 43 (collateral + HexDocs wiring + cleanup + audit) → then execute

## Operator Next Steps

- New context: read `.planning/phases/43-collateral-wiring/43-CONTEXT.md`, then execute Phase 43.
- Build collateral (`brandbook/examples/`), swap `docs/assets/parapet-logo.svg`+`favicon.svg`, verify `mix docs`, trim exploration HTMLs, write `v1.5-MILESTONE-AUDIT.md`.
- Do NOT re-open the logo — it is locked (decision-log.md D-003).
