# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-18)

**Core value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.
**Current focus:** Ready for v0.8 Escalation & Auto-Remediation milestone planning.

## Current Position

Phase: 1
Plan: 1
Status: Ready for Phase 1 execution
Last activity: 2026-05-18 - Phase 1 plan verified

Progress: [          ] 0%

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
- Added shared async/delivery metric families plus a bounded `Parapet.SLO.SliceSpec` seam for provider-owned reliability slices.
- Added explicit `Parapet.SLO.MailglassDelivery`, `Parapet.SLO.ChimewayDelivery`, and `Parapet.SLO.RindleAsync` provider catalogs.
- Reworked `mix parapet.gen.prometheus` into a provider-first generator that writes split recording and alert artifacts plus a compatibility aggregate.
- Added bounded Phase 6 triage summaries under `incident.runbook_data["triage"]` plus append-only `triage_snapshot` chronology for async and delivery incidents.
- Replaced generic workbench derivation with a durable evidence-backed triage contract and chronology-first incident detail ordering.
- Narrowed `ActionItem` to incident-linked exact follow-up work with bounded kinds for concrete async and delivery objects.
- We defaulted preview_only and requires_preview to false for backward compatibility with existing simple mitigations.
- The generator copies fixed templates to create host-owned modules instead of using dynamic workflow DSLs.

## Session Continuity

Last session: 2026-05-18
Stopped at: Phase 7 Plan 1 execution wrap-up
Resume file: None
