# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-10)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Execute milestone v0.2: Durable Evidence Spine, LiveView Operator UI, and Sibling Ecosystem Integrations.

## Current Position

Phase: 3
Plan: 4
Status: Complete
Last activity: Completed 03-04-PLAN.md

Progress: [█░░░░░░░░░] 10% (v0.2)

## Performance Metrics

**Velocity:**
- Total plans completed: 1
- Average duration: 30m
- Total execution time: 30m

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Durable Evidence Spine (Ecto) | 1/TBD | 30m | 30m |
| 2. In-App Operator UI (LiveView) | 0/TBD | — | — |
| 3. Sibling Ecosystem Integrations | 0/TBD | — | — |

**Recent Trend:** N/A

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Key decisions affecting v0.2 work:

- Decided to implement dynamic Repo lookup via `Application.get_env(:parapet, :repo)` to decouple from specific host database.
- Decided to test schema changesets purely without hitting a Repo to ensure decoupling from specific host application databases.
- Strict boundary between ephemeral high-volume telemetry (Prometheus/Grafana) and durable low-volume evidence (Ecto/PostgreSQL).
- Ecto must NOT be used for raw telemetry. It models incidents, timelines, and tool audits.
- LiveView Operator UI supplements, but does NOT replace, Grafana. UI focuses on application mutation, form actions, and safe mitigations.
- Sibling ecosystem integrations (Chimeway, Mailglass, Rulestead, etc.) are implemented as optional adapters (via `Code.ensure_loaded?`), adhering to the "compile out cleanly" constraint.
- AI/MCP tool calls that execute app mutations must be audited and recorded via `Parapet.Ecto.ToolAudit`.
- Confirmed that Parapet core safely excludes explicit direct Phoenix dependencies.
- Used static analysis of doctor checks rather than dynamically injecting a router module in ExUnit to prevent global compilation side-effects.

### Pending Todos

None yet.

### Blockers/Concerns

- Threadline compatibility check required during Phase 3 to align audit/timeline logic.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Testing | `Sigra.setup/0 is undefined or private` error during `mix test` in `Parapet.Integrations.SigraTest`. Out of scope for Phase 1 Plan 1. | deferred | Phase 1 Plan 1 |

## Session Continuity

Last session: 2024-05-11
Stopped at: Completed 03-03-PLAN.md
Resume file: None
