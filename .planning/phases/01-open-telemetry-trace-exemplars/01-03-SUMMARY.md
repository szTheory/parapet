---
phase: "01"
plan: "03"
subsystem: "spine/ui"
tags: ["ecto", "schema", "ui", "telemetry"]
dependency_graph:
  requires: ["01-02"]
  provides: ["trace_id_persistence", "trace_ui_link"]
  affects: ["priv/repo/migrations", "lib/parapet/spine", "priv/templates/parapet.gen.ui"]
tech_stack:
  added: []
  patterns: ["TDD", "schema-migration", "eex-templating"]
key_files:
  created:
    - priv/repo/migrations/20260516233447_add_trace_id_to_incidents.exs
  modified:
    - lib/parapet/spine/incident.ex
    - test/parapet/spine/incident_test.exs
    - priv/templates/parapet.gen.ui/operator_components.ex.eex
decisions:
  - "Used Application.get_env/3 in EEx templates for dynamic trace URL resolution with a fallback."
  - "Updated Enum.empty?(external_links) check in UI to account for the presence of trace_id to prevent empty state messages from rendering alongside trace links."
metrics:
  duration: 2
  completed_date: 2026-05-16
---
# Phase 01 Plan 03: Store trace_id on Incident schemas and surface dynamic trace links in Operator UI Summary

Implemented durable evidence for trace correlation by adding `trace_id` to the Incident schema and presenting a dynamic, configuration-driven trace link in the Operator UI components.

## Success Criteria Evaluation
- **Incidents store `trace_id`:** Achieved. Added to `Parapet.Spine.Incident` schema and created Ecto migration. Tests assert the field is present and castable via `changeset/2`.
- **The UI properly formats external trace URLs:** Achieved. Updated `operator_components.ex.eex` to conditionally render trace URLs dynamically replaced via `Application.get_env(:parapet, :trace_url_template)`.

## Deviations from Plan
None - plan executed exactly as written.

## Threat Flags
None.

## Self-Check: PASSED
