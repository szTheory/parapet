---
gsd_state_version: 1.0
milestone: v1.1
milestone_name: Actionable Recovery
status: executing
stopped_at: Completed 28-01-PLAN.md
last_updated: "2026-05-28T19:09:03.051Z"
last_activity: 2026-05-28
progress:
  total_phases: 7
  completed_phases: 5
  total_plans: 15
  completed_plans: 13
  percent: 71
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-27 — v1.1 Actionable Recovery milestone opened)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 28 — demo-seed-ci-lane

## Current Position

Phase: 28 (demo-seed-ci-lane) — EXECUTING
Plan: 4 of 5
Status: Ready to execute
Last activity: 2026-05-28

## Performance Metrics

**Velocity:**

- Total plans completed: 10 (v1.1 starting)
- Average duration: — min
- Total execution time: 0.0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 23 | 0 | — | — |
| Phase 24 | 0 | — | — |
| Phase 25 | 0 | — | — |
| Phase 26 | 0 | — | — |
| Phase 27 | 0 | — | — |
| Phase 28 | 0 | — | — |
| Phase 29 | 0 | — | — |
| 23 | 2 | - | - |
| 24 | 3 | - | - |
| 25 | 3 | - | - |
| 26 | 1 | - | - |
| 27 | 1 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 28 P01 | 8 | 2 tasks | 2 files |
| Phase 28 P02 | 33s | 1 tasks | 1 files |
| Phase 28-demo-seed-ci-lane P03 | 4 | 1 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- v1.1 scope: operator-in-the-loop execution only. Out of scope: autonomous remediation, cross-app correlation, multi-tenant action scoping.
- v1.1 is a wiring milestone, not a redesign: every load-bearing primitive (`Parapet.Capabilities`, `Parapet.Operator.preview/confirm_runbook_step`, `ActionPayload`, `ClaimService`, `CircuitBreaker`, `Parapet.Runbook` DSL) already ships in v1.0.
- Zero new runtime or dev dependencies. Zero `mix.lock` churn.
- Phase 23 lands FIRST because telemetry naming + schema columns become irreversible under the v1.0 stability freeze the moment they ship.
- `Parapet.Recovery` registry uses the existing `Parapet.Capabilities` Agent (NOT `Application.put_env`) to avoid repeating the v0.10 `Parapet.SLO` mistake (Pitfall 13 in research).
- Two of six prebuilt playbooks (Retry Storm, Suppression Drift) stay guidance-only by design — every obvious automated mitigation worsens the failure (continues v0.10 "guidance-only runbooks where no allowlisted capability fits" decision).
- `Parapet.Recovery` ships Stable-tier from day one in Phase 29; the 4-callback shape is frozen because adding required callbacks in v1.2 would be breaking under the v1.0 stability promise.
- Operator-clicked Confirm path is the v1.1 architectural defect closure: today it skips `ClaimService` while the Oban auto-execution path goes through it. Phase 25 closes the gap.
- [Phase ?]: Reuse frozen-allowlist atom :retry_async_item in DemoApp.Recovery.RetryAsyncItem — non-allowlisted id raises ArgumentError at Parapet.Capabilities.register_recovery/2
- [Phase ?]: demo.reset leads with ecto.drop so seeds stay always-insert and replayability comes from the drop (D-10)
- [Phase ?]: Do not double-start Parapet.Capabilities in demo app

### Pending Todos

None.

### Blockers/Concerns

None. v1.1 starts on a green `main`, 24 v1.1 requirements mapped 100% across 7 phases. Research confidence is HIGH (`.planning/research/SUMMARY.md`).

## Candidate Work

| Category | Item | Target | Status | Notes |
|----------|------|--------|--------|-------|
| SLO tooling | SLO-W1 flag-based `mix parapet.gen.slo` Igniter task | v1.2 | deferred from v1.1 | Design resolved; build it after recovery loop closes |
| Architecture | Move `Parapet.SLO` state off `Application` env (registry refactor; lands before SLO-W1) | v1.2 | candidate | See `.planning/threads/slo-state-off-application-env.md` |
| CI | Multi-version Elixir/OTP CI matrix | v1.2 | candidate | Maturity signal |
| Supply chain | SHA-pinned actions, Dependabot config, `MAINTAINING.md`, branch-protection enforcement | v1.2 | candidate | See `.planning/threads/release-gate-enforcement.md` |
| Polish | Logo/favicon, demo Docker Compose, v0.x → v1.0 migration guide, deployment guide | v1.2 | candidate | Adopter-facing trust work |
| Recovery extensions | MCP Preview surface (read-only) for recovery actions; per-capability cooldown rules; adapter-provided capabilities (Rulestead → `:revert_feature_flag`) | v1.2/v1.3 | deferred from v1.1 | Defer until MCP graduates from Experimental |
| Team workflow | Responder coordination, handoff, on-call rotation hooks (PagerDuty/Opsgenie/webhook) | v1.3 | candidate | JTBD-MAP #2 |
| Cross-boundary | Multi-app journey correlation + vertical packs | v1.4+ | long-tail | JTBD-MAP #4 |

## Session Continuity

Last session: 2026-05-28T19:08:59.566Z
Stopped at: Completed 28-01-PLAN.md
Resume file: None
Next step: `/gsd:discuss-phase 28` to gather context for Demo Seed + CI Lane (or `/gsd:plan-phase 28` to skip discuss).
