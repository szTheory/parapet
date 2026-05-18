---
phase: 07
plan: 02
subsystem: recovery-contract
tags:
  - capabilities
  - operator
  - recovery
  - audit
dependency_graph:
  requires:
    - 07-01
  provides:
    - preview-first recovery seam
    - named recovery contract
  affects:
    - lib/parapet/operator.ex
    - lib/parapet/capabilities.ex
tech_stack:
  added:
    - None
  patterns:
    - Preview-Confirm Recovery
    - Stale-Preview Rejection
    - Named Capability Dispatch
key_files:
  - lib/parapet/capabilities.ex
  - lib/parapet/operator.ex
  - lib/parapet/operator/action_payload.ex
  - test/parapet/capabilities_test.exs
  - test/parapet/operator_test.exs
decisions:
  - Use `preview_token` and `expires_at` in `recovery_preview` timeline entries to enforce safety.
  - Require `idempotency_key` for any `:execute_mitigation` action type in `ActionPayload`.
  - Fail-closed on mismatched or stale recovery previews.
metrics:
  duration: 45m
  completed_date: "2026-05-10"
---

# Phase 07 Plan 02: Named Recovery Contract Summary

The Phase 7 recovery contract has been implemented, evolving the thin capability registry into a robust, preview-first execution seam. This ensures that mutating recovery flows require human review of a bounded scope before execution, and that the execution remains exact-scope by rejecting stale or mismatched previews.

## Key Changes

### 1. Named Capability Registry (`Parapet.Capabilities`)
- Restructured the registry to support named recovery identifiers: `:retry_async_item`, `:requeue_dead_letter`, and `:request_manual_provider_check`.
- Added explicit storage for `preview` and `execute` callbacks alongside metadata like `target_kind` and `preview_only`.
- Enforced deterministic deduplication and validation of capability IDs.

### 2. Preview-First Operator APIs (`Parapet.Operator`)
- Added `preview_runbook_step/3` to resolve capabilities from runbook metadata and generate a bounded preview payload.
- Added `confirm_runbook_step/4` to execute recovery actions after validating a matching, non-expired `preview_token`.
- Implemented `compute_preview/3` to generate protocol-compliant preview data, allowing host-wired overrides.
- Implemented `find_recent_preview/3` to verify tokens against durable timeline evidence.

### 3. Action Payload Enforcement (`Parapet.Operator.ActionPayload`)
- Updated `ActionPayload` and `Parapet.Operator.valid_payload?/1` to strictly require an `idempotency_key` for any mutating recovery confirmation (`:execute_mitigation`).

## Verification Results

### Automated Tests
- `mix test test/parapet/capabilities_test.exs`: PASSED (4 tests)
- `mix test test/parapet/operator_test.exs`: PASSED (8 tests)
  - Verified successful preview generation with token and expiration.
  - Verified successful confirmation and execution.
  - Verified stale-preview rejection (expired token).
  - Verified mismatched-preview rejection.
  - Verified error handling for unwired or missing capabilities.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Missing TimelineEntry alias**
- **Found during:** Task 2 execution (test run)
- **Issue:** `TimelineEntry` was used in a `from` query within `Parapet.Operator.find_recent_preview/3` without being aliased or fully qualified.
- **Fix:** Used the fully qualified name `Parapet.Spine.TimelineEntry` in the query.
- **Files modified:** `lib/parapet/operator.ex`
- **Commit:** `ee89932`

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `lib/parapet/operator.ex` | 382-386 | Default preview data (target_refs, count, etc.) are mocked but protocol-compliant; intended to be overridden by host-wired callbacks. |

## Self-Check: PASSED
- [x] All tasks executed
- [x] Each task committed individually
- [x] All deviations documented
- [x] SUMMARY.md created
- [x] STATE.md updated
- [x] ROADMAP.md updated
- [x] Final metadata commit made
