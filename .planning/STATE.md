---
gsd_state_version: 1.0
milestone: v1.4
milestone_name: Trust Hardening & Host-App Compatibility
status: Awaiting next milestone
last_updated: "2026-06-04T21:54:13.925Z"
last_activity: 2026-06-04 — Milestone v1.4 completed and archived
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-04 after v1.4 Trust Hardening & Host-App Compatibility milestone)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Planning next milestone

## Current Position

Phase: Milestone v1.4 complete
Plan: —
Status: Awaiting next milestone
Last activity: 2026-06-04 — Milestone v1.4 completed and archived

## Performance Metrics

**Velocity:**

- Total plans completed: 18 (v1.3)
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
| 28 | 5 | - | - |
| 29 | 4 | - | - |
| 32 | 2 | - | - |
| 35 | 1 | - | - |
| 37 | 3 | - | - |
| 38 | 3 | - | - |
| 39 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: —

*Updated after each plan completion*
| Phase 28 P01 | 8 | 2 tasks | 2 files |
| Phase 28 P02 | 33s | 1 tasks | 1 files |
| Phase 28-demo-seed-ci-lane P03 | 4 | 1 tasks | 1 files |
| Phase 28 P04 | 34 | 1 tasks | 1 files |
| Phase 28 P05 | 40 | 2 tasks | 3 files |
| Phase 31 P01 | 4m | 1 tasks | 2 files |
| Phase 32 P01 | 0 min | 2 tasks | 2 files |
| Phase 32 P02 | 0 min | 2 tasks | 2 files |
| Phase 33 P01 | 11min | 3 tasks | 5 files |
| Phase 33 P02 | 12min | 3 tasks | 4 files |
| Phase 35 P01 | 7 min | 3 tasks | 4 files |
| Phase 36 P01 | 10 min | 3 tasks | 8 files |
| Phase 37 P01 | 20 min | 4 tasks | 2 files |
| Phase 37 P02 | 8 min | 2 tasks | 3 files |
| Phase 37 P03 | 7 min | 2 tasks | 2 files |
| Phase 38 P01 | 8min | 3 tasks | 5 files |
| Phase 38 P03 | 4min | 3 tasks | 6 files |
| Phase 39 P01 | 6min | 2 tasks | 4 files |
| Phase 39 P02 | 6min | 2 tasks | 3 files |

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
- [Phase ?]: runbook_data[module] string key is the only mechanism enabling Preview/Confirm; inline steps is display-only
- [Phase ?]: Incident 4 added as always-insert alongside existing 3; replayability via mix demo.reset per D-10/D-11
- [Phase 32]: Keep `release_gate` as the stable required status check while CI expands into an Elixir/OTP matrix.
- [Phase 36]: Browser screenshot proof uses local Chromium automation against the demo app and writes durable PNG evidence under the Phase 36 planning directory without adding repo dependencies.
- [Phase 38]: Keep scoped route ownership in generated host-owned LiveView/component code rather than adding a Parapet router abstraction. — Preserves host auth/router ownership and Parapet core compile-out boundary.
- [Phase 38]: Derive the active Operator UI base path from the current LiveView URI path only. — Avoids using scheme, host, query, or user params as redirect targets while supporting nested host scopes.
- [Phase 38]: No generated route-bearing form surfaces were found, so no form route handling was added. — The form audit returned no matches; adding form route behavior would invent unsupported semantics.
- [Phase 38]: Document scoped mounting as host-owned router guidance rather than adding a mix parapet.gen.ui option. — Preserves host router ownership and keeps the generator CLI stable.
- [Phase 38]: Treat Phoenix entries in mix.lock as transitive dependency evidence while rejecting direct root :phoenix and :phoenix_live_view deps. — The lockfile already contains Phoenix through existing transitive packages, so the root dependency contract is the stable boundary.
- [Phase 38]: Keep external links outside operator_base_path; only local Operator UI emitters are routed through scoped helpers. — External evidence links must stay external while scoped route helpers cover host-local navigation.
- [Phase 39]: Plan 01 documented scoped UI mounting as host-owned router and auth guidance — Preserves the Phase 38 decision to avoid generator flags and Parapet-owned router abstractions.
- [Phase 39]: Plan 01 kept adoption proof to documentation and ExUnit docs guards only — No runtime, API, dependency, auth, router ownership, or install-surface changes were introduced.
- [Phase 39]: Plan 02 preserved the original quality evaluation as a historical audit snapshot and appended a dated v1.4 closeout instead of rewriting prior findings.
- [Phase 39]: Plan 02 closed only the named v1.4 risk slices and kept unrelated quality-evaluation findings open for future milestone planning.

### Pending Todos

None.

### Blockers/Concerns

None. v1.4 closed with 10/10 requirements satisfied, milestone audit passed, and no open artifact audit items.

## Candidate Work

| Category | Item | Target | Status | Notes |
|----------|------|--------|--------|-------|
| SLO tooling | SLO-W1 flag-based `mix parapet.gen.slo` Igniter task | v1.2 | shipped | Delivered in Phase 31 |
| Architecture | Move `Parapet.SLO` state off `Application` env (registry refactor; lands before SLO-W1) | v1.2 | shipped | Delivered in Phase 30; thread closed |
| CI | Multi-version Elixir/OTP CI matrix | v1.2 | shipped | Delivered in Phase 32 |
| Supply chain | SHA-pinned actions, Dependabot config, `MAINTAINING.md`, branch-protection enforcement | v1.2 | shipped | Delivered in Phases 32-33 |
| Polish | Logo/favicon, demo Docker Compose, v0.x → v1.0 migration guide, deployment guide | v1.2 | shipped | Delivered in Phase 33 |
| Recovery extensions | MCP Preview surface (read-only) for recovery actions; per-capability cooldown rules; adapter-provided capabilities (Rulestead → `:revert_feature_flag`) | v1.2/v1.3 | deferred from v1.1 | Defer until MCP graduates from Experimental |
| Team workflow | Responder coordination, handoff, on-call rotation hooks (PagerDuty/Opsgenie/webhook) | v1.3 | candidate | JTBD-MAP #2 |
| Cross-boundary | Multi-app journey correlation + vertical packs | v1.5+ | long-tail | JTBD-MAP #4 |

## Session Continuity

Last session: 2026-06-04T21:35:59.622Z
Stopped at: Completed 39-02-PLAN.md
Resume file: None
Next step: Start the next milestone with /gsd-new-milestone

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
