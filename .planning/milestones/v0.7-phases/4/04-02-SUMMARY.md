---
phase: 4
plan: 04-02
subsystem: "integrations"
tags:
  - telemetry
  - mailglass
  - chimeway
  - delivery
dependency_graph:
  requires:
    - "04-01-SUMMARY.md"
  provides:
    - "Mailglass translation onto normalized delivery families"
    - "Chimeway translation onto normalized delivery families"
  affects:
    - "lib/parapet/integrations/mailglass.ex"
    - "lib/parapet/integrations/chimeway.ex"
    - "Phase 5 delivery metrics and SLO work"
tech_stack:
  added: []
  patterns:
    - "Grouped telemetry attachment"
    - "Provider telemetry normalization"
key_files:
  created: []
  modified:
    - "lib/parapet/integrations/mailglass.ex"
    - "lib/parapet/integrations/chimeway.ex"
    - "test/parapet/integrations/mailglass_test.exs"
    - "test/parapet/integrations/chimeway_test.exs"
requirements_completed:
  - DELV-01
  - TRIAGE-01
metrics:
  duration: 28
  tasks_completed: 3
  files_modified: 4
completed: 2026-05-17
---

# Phase 4 Plan 04-02: Delivery Adapter Contract Summary

Mailglass and Chimeway now emit normalized Phase 4 delivery telemetry families with bounded metadata, explicit webhook-vs-provider fault separation, and ref-only handling for exact identifiers.

## Accomplishments

- Reworked `Parapet.Integrations.Mailglass` onto `[:parapet, :delivery, :outbound]`, `:provider_feedback`, and `:webhook_ingest` with grouped attachments and contract-aware metadata shaping.
- Reworked `Parapet.Integrations.Chimeway` around the one proven upstream surface in this repo, normalizing provider failure separately from callback-delay signals instead of inventing unsupported states.
- Replaced the old thin journey-shim tests with Phase 4 characterization and contract tests that prove bounded metadata, normalized outcomes, and safe ref demotion.

## Verification

- `mix test test/parapet/integrations/mailglass_test.exs test/parapet/integrations/chimeway_test.exs test/parapet/integrations/rindle_test.exs`

## Decisions Made

- Treated Mailglass outbound send completion as `:attempted` at the public contract boundary, leaving richer delivery confirmation to provider feedback and webhook families.
- Scoped Chimeway normalization to the currently proven `[:chimeway, :event, :failed]` upstream event and used metadata cues only to distinguish provider failure from callback-delay/webhook-plane failure.
- Dropped unproven or high-cardinality fields from public metadata, keeping only the exact identifier refs needed by the contract tests.

## Deviations from Plan

None on scope. The plan stayed within the expected adapter and test surface.

## Issues Encountered

- The first delegated attempt only landed red-phase tests and stopped early; the adapter rewrites and verification were completed in the main thread.
- The initial adapter implementation called `Parapet.Telemetry.AsyncDelivery.shape_metadata/2` with reversed arguments, which prevented events from emitting until the call sites were corrected.

## Next Phase Readiness

The delivery adapters now speak one public contract, so Wave 3 can document a stable namespace and Phase 5 can build delivery metrics/SLOs without provider-specific branching.
