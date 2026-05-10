# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-09)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Phase 3 — SLO DSL, Login Journey, and Deploy Markers

## Current Position

Phase: 2 of 4 (HTTP, Ecto & Oban)
Plan: 2 of 2 in current phase
Status: Complete
Last activity: 2026-05-09 — Completed 02-02-PLAN.md

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 20m
- Total execution time: 2h 10m

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Foundation | 5/5 | 1h 45m | 21m |
| 2. Metrics | 2/2 | 25m | 12m |
| 3. SLO + Integrations | TBD | — | — |
| 4. Artifacts + DX | TBD | — | — |

**Recent Trend:** No data yet

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Key decisions affecting Phase 1 work:

- Single `parapet` package for v0.1 — no premature boundary splits; admin/UI package boundary designed in but deferred
- Telemetry-first in v0.1, no DB-backed evidence spine — establishes contract before committing to a schema
- Generator for scaffolding, library for runtime — host-owned principle requires adopters to inspect and modify
- Output a structured JSON manifest via stdout for downstream ingestion.
- Moved Parapet.Application to Parapet.Internal.Application to avoid false positives in public API checks while maintaining internal functionality.
- Implemented a hardcoded label policy regex to prevent high cardinality explosions rather than making it configurable, ensuring strict safety rails out of the box.
- Used `Sourceror.to_string(zipper.node) =~ "Parapet.Plug.Metrics"` instead of verbose Igniter context-aware function matching to determine if the Endpoint was already patched, prioritizing simplicity and speed in the generator.

- Ecto timing converts native duration metrics to milliseconds for proper bucketing.
- Oban explicitly tracks and aliases `worker`, `queue`, and `state` on both counter and distribution to support `rate()`-based metric reporting correctly.
- Added Oban module conditionally mapped against `Code.ensure_loaded?(Oban)` enabling optional library deployment.

### Pending Todos

None yet.

### Blockers/Concerns

- **Phase 3 research flag**: Multi-window burn-rate PromQL is nuanced; Sloth/Pyrra rule formats need direct study before Phase 3 planning. Run `/gsd-research-phase 3` before planning Phase 3.
- **Phase 3/4 research flag**: Sigra telemetry event schema must be confirmed stable before Phase 3 integration work begins.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-05-09
Stopped at: Phase 2 Complete
Resume file: (Phase 3 Planning next)
