# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-12)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Executing v0.6 milestone (Change Correlation & Audit Trailing).

## Current Position

Phase: 03
Plan: 03
Status: Completed
Last activity: Completed 03-03-PLAN.md

Progress: [XXXXXXX...] 77%

## Accumulated Context

### Pending Todos

None yet.

### Blockers/Concerns

None.

## Decisions Made

- Decided on Phase 3 architecture: Parapet will emit standard `[:parapet, :audit, :*]` telemetry events, define `Parapet.Audit.Writer` and `Parapet.Audit.Reader` behaviors configured via Application config, and bypass internal Ecto writes when deferred storage is enabled (falling back to Threadline).
- Used DummyRepo approach for isolated Ecto testing in Scoria adapter without hitting real DB.
- Updated Igniter implementation to use modern arity 1 `igniter/1` callbacks for tasks.
- Excluded Resolvable protocol implementations from public API docs check.
- Wrapped OpenTelemetry calls in safe `Code.ensure_loaded?` and `rescue` blocks to prevent crashes when OTel is not present.
- Ensured `trace_id` is only appended to `metadata` and never `tags` to prevent cardinality explosion in Prometheus.
- Used Application.get_env/3 in EEx templates for dynamic trace URL resolution with a fallback.
- Updated Enum.empty?(external_links) check in UI to account for the presence of trace_id to prevent empty state messages from rendering alongside trace links.
- Used `Code.ensure_loaded?(Threadline)` to check for Threadline dependency safely before routing.
- Adapted `to_threadline_shape` to support maps to accommodate telemetry payloads.
- Added telemetry event handler for `[:parapet, :audit, :created]` events.

## Session Continuity

Last session: 2026-05-24
Stopped at: Completed 03-02-PLAN.md
Resume file: None
