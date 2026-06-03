---
phase: 4
plan: 04-01
subsystem: "telemetry"
tags:
  - telemetry
  - async-delivery
  - label-policy
  - contract
dependency_graph:
  requires: []
  provides:
    - "Bounded public async/delivery telemetry contract helpers"
    - "Family-aware label policy validation for Phase 4 metadata"
  affects:
    - "lib/parapet/integrations/mailglass.ex"
    - "lib/parapet/integrations/chimeway.ex"
    - "lib/parapet/integrations/rindle.ex"
tech_stack:
  added: []
  patterns:
    - "Bounded telemetry contract"
    - "Allowlisted family metadata validation"
key_files:
  created:
    - "lib/parapet/telemetry/async_delivery.ex"
    - "test/parapet/telemetry/async_delivery_test.exs"
  modified:
    - "lib/parapet/internal/label_policy.ex"
    - "test/parapet/internal/label_policy_test.exs"
    - "test/parapet_test.exs"
requirements_completed:
  - DELV-01
  - TRIAGE-01
metrics:
  duration: 18
  tasks_completed: 2
  files_modified: 5
completed: 2026-05-17
---

# Phase 4 Plan 04-01: Async/Delivery Contract Summary

Bounded async and delivery telemetry primitives now define the six public Phase 4 families, normalize contract-safe outcomes, and enforce family-aware metadata allowlists before adapter migration begins.

## Accomplishments

- Added `Parapet.Telemetry.AsyncDelivery` as the shared contract surface for event families, outcome normalization, fault-plane normalization, retry-state normalization, delay buckets, and ref demotion.
- Extended `Parapet.Internal.LabelPolicy` with `assert_family_keys!/2` so Phase 4 metadata is validated against explicit per-family allowlists instead of regex checks alone.
- Added focused tests proving the public family set, normalization rules, ref shaping, delay bucketing, and family-aware label validation.

## Verification

- `mix test test/parapet/telemetry/async_delivery_test.exs test/parapet/internal/label_policy_test.exs test/parapet_test.exs`

## Decisions Made

- Kept the contract module as the single source of truth for the six public families and their allowed top-level keys.
- Demoted known exact identifiers into `metadata.refs` using `_ref` keys and dropped unknown pass-through fields from the public contract.
- Preserved the existing regex-based `assert_safe!/1` API for older metrics callers while layering stricter Phase 4 validation alongside it.

## Deviations from Plan

None. The work stayed within the planned Wave 1 contract and label-policy surface.

## Issues Encountered

- `mix test` initially failed because a module attribute attempted to call `event_name/1` during compilation; the family list was made explicit at compile time and the suite passed after that adjustment.

## Next Phase Readiness

Wave 2 adapters can now build against one explicit contract surface instead of inventing provider-specific metadata rules.
