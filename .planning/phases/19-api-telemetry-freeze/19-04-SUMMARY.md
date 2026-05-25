---
phase: 19-api-telemetry-freeze
plan: "04"
subsystem: stability-annotation
tags: [stability, experimental, moduledoc, exdoc, public-api]
dependency_graph:
  requires: ["19-01"]
  provides: ["STAB-01-experimental", "mix-verify-public-api-exit-0"]
  affects: ["docs/stability.md cross-links", "mix verify.public_api gate"]
tech_stack:
  added: []
  patterns: ["ExDoc admonition callout", "stability tier annotation"]
key_files:
  created: []
  modified:
    - lib/parapet/mcp/server.ex
    - lib/parapet/mcp/prometheus_client.ex
    - lib/parapet/automation/circuit_breaker.ex
    - lib/parapet/automation/claim_service.ex
    - lib/parapet/automation/executor.ex
    - lib/parapet/probe.ex
    - lib/parapet/probe/native_scheduler.ex
    - lib/parapet/probe/oban_scheduler.ex
    - lib/parapet/evidence/archiver.ex
    - lib/parapet/evidence/retrospective.ex
    - lib/parapet/evidence/archive_worker.ex
    - lib/parapet/capabilities.ex
    - lib/parapet/metrics/accrue.ex
    - lib/parapet/metrics/async_delivery.ex
    - lib/parapet/metrics/ecto.ex
    - lib/parapet/metrics/exemplar_store.ex
    - lib/parapet/metrics/exemplar_telemetry.ex
    - lib/parapet/metrics/http.ex
    - lib/parapet/metrics/oban.ex
    - lib/parapet/metrics/probe.ex
    - lib/parapet/metrics/prometheus_formatter.ex
    - lib/parapet/metrics/rulestead.ex
    - lib/parapet/metrics/scoria.ex
    - lib/parapet/metrics/sigra.ex
    - lib/parapet/metrics/validator.ex
    - lib/parapet/integrations/accrue.ex
    - lib/parapet/integrations/chimeway.ex
    - lib/parapet/integrations/mailglass.ex
    - lib/parapet/integrations/rindle.ex
    - lib/parapet/integrations/rulestead.ex
    - lib/parapet/integrations/scoria.ex
    - lib/parapet/integrations/sigra.ex
    - lib/parapet/integrations/threadline.ex
    - lib/parapet/notifier/slack.ex
    - lib/parapet/notifier/teams.ex
    - lib/parapet/notifier/oban_worker.ex
    - lib/parapet/escalation/worker.ex
    - lib/parapet/plug/mcp.ex
    - lib/parapet/plug/webhook.ex
    - lib/parapet/plug/metrics.ex
    - lib/parapet/operator/action_payload.ex
    - lib/parapet/operator/workbench_contract.ex
    - lib/parapet/spine/incident.ex
    - lib/parapet/spine/timeline_entry.ex
    - lib/parapet/spine/tool_audit.ex
    - lib/parapet/spine/action_item.ex
    - lib/parapet/spine/action_claim.ex
    - lib/parapet/spine/system_event.ex
    - lib/parapet/spine/system_event_pruner.ex
    - lib/parapet/spine/alert_processor.ex
    - lib/parapet/slo.ex
    - lib/parapet/slo/http.ex
    - lib/parapet/slo/login_journey.ex
    - lib/parapet/slo/oban.ex
    - lib/parapet/slo/chimeway_delivery.ex
    - lib/parapet/slo/mailglass_delivery.ex
    - lib/parapet/slo/rindle_async.ex
    - lib/parapet/slo/scoria_eval.ex
    - lib/parapet/slo/generator.ex
    - lib/mix/tasks/verify.public_api.ex
decisions:
  - "D-01: Experimental callout exact text — `> #### Experimental {: .warning}` with stability.html cross-link"
  - "D-12: All 8 Spine schemas annotated Experimental; Parapet.Capabilities annotated Experimental"
  - "D-14: lib/parapet/slo.ex callout added to @moduledoc only; @deprecated define/2 unchanged"
  - "Deviation Rule 1: Fixed .Resolvable filter bug in verify.public_api (String.contains? needed no trailing dot)"
metrics:
  duration: "19 minutes"
  completed: "2026-05-25"
  tasks_completed: 3
  files_modified: 59
---

# Phase 19 Plan 04: Experimental Module Callout Annotations Summary

Annotated every Experimental-tier public module (~58 modules across MCP, Automation, Probe, Evidence helpers, Metrics, Integrations, Notifier adapters, Plug, Operator schemas, Escalation worker, all 8 Spine schemas, legacy Parapet.SLO module, and SLO preset/generator modules) with the `> #### Experimental {: .warning}` ExDoc callout cross-linking stability.html; combined with Plan 03 this makes `mix verify.public_api` exit 0 with no `:unclassified` module.

## Tasks Completed

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Experimental callouts — MCP, Automation, Probe, Evidence, Capabilities | 4550aef | 12 files |
| 2 | Experimental callouts — Metrics and Integrations | b1e923a | 21 files |
| 3 | Experimental callouts — Notifier, Plug, Operator, Spine, SLO; gate exit 0 | 381a049 | 27 files (+1 gate fix) |

## Outcome

- All ~58 Experimental-tier public modules carry the `> #### Experimental {: .warning}` callout with `stability.html` cross-link.
- `lib/parapet/slo.ex` carries the callout; `@deprecated "Use a Parapet.SLO.Provider module instead"` on `define/2` is byte-for-byte unchanged.
- `mix compile --warnings-as-errors` exits 0 after each task.
- `mix verify.public_api` exits 0 — no `:unclassified` module remains across the full public surface.
- STAB-01 (Experimental portion) fully satisfied.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed .Resolvable exclusion filter in mix verify.public_api**

- **Found during:** Task 3 — `mix verify.public_api` flagged `Parapet.SLO.Resolvable` as unclassified
- **Issue:** The gate filter used `String.contains?(name, ".Resolvable.")` (with trailing dot) which only matches intermediate segments like `Parapet.SLO.Resolvable.Impl`, not a terminal module `Parapet.SLO.Resolvable` where the string ends without a trailing dot. `String.contains?("Parapet.SLO.Resolvable", ".Resolvable.")` returns `false`.
- **Fix:** Changed to `String.contains?(name, ".Resolvable")` (no trailing dot required) so both terminal and non-terminal `.Resolvable` modules are excluded. This aligns with the design intent described in 19-CONTEXT.md and 19-RESEARCH.md.
- **Files modified:** `lib/mix/tasks/verify.public_api.ex` (line 72)
- **Commit:** 381a049 (included in Task 3 commit)

## Threat Flags

None — documentation/metadata-only edits. No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries.

## Self-Check: PASSED

All 59 modified files verified to contain the correct callout string. Key spot-checks:
- `lib/parapet/mcp/server.ex` — contains `#### Experimental {: .warning}`
- `lib/parapet/slo.ex` — contains `#### Experimental {: .warning}` AND `@deprecated "Use a Parapet.SLO.Provider module instead"` unchanged
- `lib/parapet/spine/incident.ex` — contains `#### Experimental {: .warning}`
- `mix verify.public_api` exits 0 — all modules classified, none unclassified
