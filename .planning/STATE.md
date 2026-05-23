---
gsd_state_version: 1.0
milestone: v0.10
milestone_name: Adopter Success
status: roadmap_complete
last_updated: "2026-05-23T00:00:00.000Z"
last_activity: 2026-05-23
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-23)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 15 — Packaging Credibility Gate (first phase of v0.10 Adopter Success).

## Current Position

Phase: 15 of 18 (Packaging Credibility Gate)
Plan: — (not yet planned)
Status: Ready to plan
Last activity: 2026-05-23 — v0.10 roadmap created (Phases 15-18, 11/11 requirements mapped)

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: —
- Trend: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [v0.10 roadmap]: Land hex.pm metadata + CHANGELOG (ADOPT-01/02) first as a low-cost credibility gate that unblocks all downstream adoption work.
- [v0.10 roadmap]: Build code surfaces (SLO packs, deepened runbook templates) before the docs that name them, so docs never reference uncompilable code.
- [v0.10 roadmap]: Treat the `warning:` DSL surface as a research flag on the recovery phase — plan-phase verifies `Parapet.Runbook.step/2` actually renders `warning:` before any template uses it (Elixir silently swallows unknown macro keyword args).
- [v0.10 roadmap]: Coarse granularity → 4 cohesive phases instead of the 6 research-suggested; the deferred demo (DEMO-01) and SLO wizard are out of scope.

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 16]: HTTP `SliceSpec` selector format is the one open code question — verify `AsyncDelivery.selector/2` handles HTTP `status_code` matchers or add a small HTTP selector helper. Run `--research-phase` only if the code-read reveals a gap.
- [Phase 17]: Cross-file tension — FEATURES.md says `warning:`/`requires_preview:`/`kind: :guidance` already exist; SUMMARY.md says `warning:` must land before templates use it. Resolve by verifying the live DSL surface before writing template content.
- [Phase 18]: Threadline is "conceptual interoperability" — its integration guide must be honest about what is actually wired vs aspirational. Low-traffic guidance thresholds are SRE-community consensus, not canonical — validate against Parapet's actual generated rule shapes during authoring.

## Deferred Items

Items acknowledged and carried forward (not in the v0.10 roadmap):

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Demo | DEMO-01 runnable demo app (`examples/demo_app/`) + CI check | Deferred to v0.10.x | v0.10 requirements |
| SLO tooling | SLO-W1 interactive `mix parapet.gen.slo` wizard | Deferred to v1.0+ | v0.10 requirements |
| SLO bundles | SLO-B1 cross-integration SLO slice bundles | Deferred to v1.0+ | v0.10 requirements |
| Release | API / telemetry freeze | Deferred to v1.0 (MILESTONE-ARC.md) | v0.10 requirements |

## Session Continuity

Last session: 2026-05-23
Stopped at: v0.10 roadmap created (Phases 15-18); REQUIREMENTS.md traceability populated (11/11 mapped)
Resume file: None
Next step: `/gsd:plan-phase 15`
