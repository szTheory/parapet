---
gsd_state_version: 1.0
milestone: none
milestone_name: Released Maintenance
status: quiet
stopped_at: v1.0 closed; no concrete feature slice is open
last_updated: "2026-05-27T07:00:00.000Z"
last_activity: 2026-05-27 -- post-1.0 strategic assessment landed; v1.1 target retargeted from SLO-W1 to Actionable Recovery (see .planning/NEXT-STEP-ASSESSMENT.md); SLO-W1 + CI matrix + supply-chain hardening deferred to v1.2; two threads opened (actionable-recovery-design, release-gate-enforcement); first phase LEARNINGS file written (22-LEARNINGS.md)
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-26 — v1.0 shipped; quiet stable-line mode active)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** released maintenance on a stable release line

## Current Position

Milestone: none — QUIET
Default branch posture: `main` is stable and releasable by default
Status: if `release_gate` is green and release truth is coherent, the default answer is that there is nothing to do
Last activity: 2026-05-26 -- quiet-default release-train policy codified; feature work now requires a concrete PR-shaped slice

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity:**

- Total plans completed: 0 (no active milestone)
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| No active slice | — | — | — |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 19 P02 | 5 | 2 tasks | 2 files |
| Phase 19 P04 | 19 | 3 tasks | 59 files |
| Phase 20 P02 | 1 | 1 tasks | 1 files |
| Phase 20 P03 | 2 | 2 tasks | 4 files |
| Phase 20 P05 | 9 | 3 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v1.0 scope: Freeze depth = stability tiers + deprecation policy (not a full hardening pass). Proportionate verification gate (REL-03) replaces a security/perf audit.
- Demo in v1.0: Demo app confirmed in-scope as a CI contract test for the frozen surface (not deferred to v1.1).
- SLO-B1 dropped: `Parapet.SLO.Provider` returning multiple slices is the bundle abstraction; documented as a pattern (DOCS-05) instead of a separate abstraction.
- After `v1.0.0`, `main` is treated as the stable release line: green `release_gate`, repo hygiene, and coherent Release Please truth are the default merge posture.
- Patch/minor releases continue through Release Please PRs on `main`; do not auto-publish on every merge.
- Quiet-default rule: if `main` is green and there is no concrete release-affecting work, remain silent and do not invent milestone motion.
- Serious feature work is PR-only and should open as an explicit scoped slice before it becomes active milestone work.
- [Phase ?]: Integration guides follow sigra.md template with content verified against .ex source files
- [Phase ?]: Content verified against .ex source
- [Phase ?]: Explicit file lists for Getting Started, Guides, Reference groups; regex only for Integration Guides — prevents capture overlap Pitfall 6
- [Phase ?]: CODE_OF_CONDUCT* glob in Hex files: whitelist; file dropped per 20-01 user decision — glob is harmless without the file (GOV-03 not required)

### Pending Todos

None.

### Blockers/Concerns

- None for the shipped `v1.0.0` line. The release outcome is settled: `v0.10.0` and `v1.0.0` exist, GitHub/Hex/HexDocs resolve, and the one-time `1.0.0` pin has already been removed. New work should assume `main` stays releasable and should avoid one-off release config drift unless staging a deliberate version cut.

## Candidate Work

| Category | Item | Target | Status | Notes |
|----------|------|--------|--------|-------|
| Operator UI | v1.1 Actionable Recovery (Preview/Confirm flow + 4–6 playbooks + audit propagation) | v1.1 | candidate | Highest-leverage next milestone per 2026-05-27 strategic assessment; see `.planning/threads/actionable-recovery-design.md` |
| SLO tooling | SLO-W1 flag-based `mix parapet.gen.slo` Igniter task | v1.2 | deferred from v1.1 | Design resolved; build it after recovery loop closes |
| CI | Multi-version Elixir/OTP CI matrix | v1.2 | candidate | Maturity signal |
| Supply chain | SHA-pinned actions, Dependabot config (currently missing), `MAINTAINING.md`, branch-protection enforcement | v1.2 | candidate | See `.planning/threads/release-gate-enforcement.md` for bypass-closure work |
| Polish | Logo/favicon, demo Docker Compose, v0.x → v1.0 migration guide, deployment guide | v1.2 | candidate | Adopter-facing trust work |
| Team workflow | Responder coordination, handoff, on-call rotation hooks (PagerDuty/Opsgenie/webhook) | v1.3 | candidate | JTBD-MAP #2 |
| Cross-boundary | Multi-app journey correlation + vertical packs | v1.4+ | long-tail | JTBD-MAP #4 |

## Session Continuity

Last session: 2026-05-27T07:00:00.000Z
Stopped at: post-1.0 strategic assessment landed; v1.1 target = Actionable Recovery (candidate); quiet stable-line mode still active until user opens the milestone
Resume file: .planning/NEXT-STEP-ASSESSMENT.md
Next step: Stay quiet by default. When the user is ready to open v1.1, the seed lives in `.planning/threads/actionable-recovery-design.md` — kick off via `/gsd:new-milestone` or `/gsd:discuss-phase` from there. Concurrent threads (e.g., `release-gate-enforcement` for v1.2) should not auto-promote.
