---
phase: 37-archive-durability
plan: 01
subsystem: evidence
tags: [archive, evidence, jsonl, manifest, retention]

requires: []
provides:
  - staged local archive export before incident prune
  - structured archive Summary and Failure result contract
  - complete Parapet-owned evidence bundle serialization
  - exact selected-id deletion after verified artifact publish
affects: [archive, cli, oban-worker, docs]

tech-stack:
  added: []
  patterns:
    - staged JSONL artifact with sidecar manifest
    - explicit child evidence queries by foreign key
    - structured operational result tuples

key-files:
  created:
    - .planning/phases/37-archive-durability/37-01-SUMMARY.md
  modified:
    - lib/parapet/evidence/archiver.ex
    - test/parapet/evidence/archiver_test.exs

key-decisions:
  - "Incident child evidence is queried explicitly by foreign key because the spine schemas do not declare Incident has_many associations."
  - "The manifest is written after archive publish and before prune so delete-stage failures still leave inspectable artifact metadata."

patterns-established:
  - "Archive failures return Failure structs with stage, run paths, and partial summary context."
  - "Archive tests pin deterministic clock/run id through internal application configuration without adding public arity."

requirements-completed: [ARCH-01, ARCH-02, ARCH-03, ARCH-04]

duration: 0h 20m
completed: 2026-06-04
---

# Phase 37 Plan 01: Core Archive Durability Summary

**Verified JSONL archive export with structured run summaries, complete Parapet-owned incident bundles, and exact-id prune semantics**

## Performance

- **Duration:** 20 min
- **Started:** 2026-06-04T18:55:00Z
- **Completed:** 2026-06-04T19:15:00Z
- **Tasks:** 4
- **Files modified:** 2

## Accomplishments

- Replaced direct final-file append/delete behavior with staged JSONL export, verification, publish, manifest, and exact selected-id deletion.
- Added `%Parapet.Evidence.Archiver.Summary{}` and `%Parapet.Evidence.Archiver.Failure{}` result structs for operational success and failure context.
- Expanded archive serialization to include incidents, timeline entries, nested tool audits, incident-linked action items, and incident-linked action claims.
- Added focused fake-repo tests for deterministic cutoff selection, complete bundle counts, write/publish failure no-prune behavior, and delete mismatch failures.

## Task Commits

1. **Tasks 1-4: staged archive durability contract and verification** - `296e4d6` (feat)

## Files Created/Modified

- `lib/parapet/evidence/archiver.ex` - Defines Summary/Failure structs, staged archive flow, bundle loading, artifact verification, manifest writing, and exact-id deletion.
- `test/parapet/evidence/archiver_test.exs` - Covers deterministic summary fields, complete owned evidence bundle serialization, no-prune export failures, and delete-stage failure context.

## Decisions Made

- Incident-linked child evidence is loaded with explicit `repo.all/1` queries over `incident_id` and `timeline_entry_id`, avoiding reliance on undeclared schema associations.
- Manifest JSON is written before prune so a delete-stage failure leaves a supportable artifact and run summary path.
- Deterministic tests use internal `Application` configuration for clock and run id rather than changing the public `archive/3` arity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Avoided undeclared association preload**
- **Found during:** Task 2 (complete evidence bundle)
- **Issue:** The existing code preloaded `timeline_entries: :tool_audits`, but `Incident` does not declare these associations. Extending that pattern to action items/claims would make the archive path fragile.
- **Fix:** Loaded timeline entries, tool audits, action items, and action claims with explicit Ecto queries keyed by selected incident ids.
- **Files modified:** `lib/parapet/evidence/archiver.ex`, `test/parapet/evidence/archiver_test.exs`
- **Verification:** `mix test test/parapet/evidence/archiver_test.exs`
- **Committed in:** `296e4d6`

---

**Total deviations:** 1 auto-fixed (Rule 2)
**Impact on plan:** The implementation still satisfies the planned bundle and prune truth model while using a more reliable Phoenix/Ecto-native pattern.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/parapet/evidence/archiver_test.exs` - passed
- `mix format --check-formatted` - passed
- `mix compile --warnings-as-errors` - passed

## Next Phase Readiness

Plan 02 can update `mix parapet.archive` and `Parapet.Evidence.ArchiveWorker` to consume the new structured archive result tuple.

---
*Phase: 37-archive-durability*
*Completed: 2026-06-04*
