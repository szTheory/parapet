---
phase: 37-archive-durability
plan: 03
subsystem: evidence
tags: [archive, docs, changelog, verification]

requires:
  - phase: 37-archive-durability
    provides: staged archive runtime and caller surfaces
provides:
  - ExDoc-facing archive result contract
  - Experimental API changelog notice
  - focused and repository-level archive verification evidence
affects: [archive, release-notes, verification]

tech-stack:
  added: []
  patterns:
    - changelog notice for Experimental return-shape change
    - explicit retention limitation in module documentation

key-files:
  created:
    - .planning/phases/37-archive-durability/37-03-SUMMARY.md
  modified:
    - lib/parapet/evidence/archiver.ex
    - CHANGELOG.md

key-decisions:
  - "docs/stability.md already covers Parapet.Evidence.Archiver and Parapet.Evidence.ArchiveWorker as Experimental, so no stability table change was required."
  - "Phase 37 verification found no dependency, migration, install-template, or backup-ownership expansion."

patterns-established:
  - "Experimental API return-shape changes are documented in CHANGELOG.md and in ExDoc-facing module docs."

requirements-completed: [ARCH-01, ARCH-02, ARCH-03, ARCH-04]

duration: 0h 07m
completed: 2026-06-04
---

# Phase 37 Plan 03: Archive Compatibility and Verification Summary

**Archive result contract documentation, Experimental changelog note, and full repository verification for archive durability**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-04T19:23:00Z
- **Completed:** 2026-06-04T19:30:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Documented `archive/3` returning `{:ok, %Summary{}}` and `{:error, %Failure{}}` in `Parapet.Evidence.Archiver` moduledoc.
- Documented the archive boundary as Parapet-owned evidence export/prune, not host backup/restore.
- Documented the retention limitation: resolved incidents created before cutoff via `inserted_at < cutoff`, not resolved-before-cutoff semantics.
- Added an Unreleased changelog note for the Experimental archive return-shape change and CLI failure behavior.
- Ran focused archive verification plus repository-level format, compile, and full test suite.

## Task Commits

1. **Tasks 1-2: archive docs and verification evidence** - `20495ab` (docs)

## Files Created/Modified

- `lib/parapet/evidence/archiver.ex` - Adds ExDoc-facing return shape, archive scope, and retention limitation text.
- `CHANGELOG.md` - Adds Unreleased note for Experimental archive API and CLI behavior changes.

## Decisions Made

- Left `docs/stability.md` unchanged because it already lists `Parapet.Evidence.Archiver` and `Parapet.Evidence.ArchiveWorker` as Experimental surfaces.
- Confirmed Phase 37 did not add runtime dependencies, install contents, schema migrations, object-store config, or host backup ownership.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` - passed, 10 tests, 0 failures
- `mix format --check-formatted` - passed
- `mix compile --warnings-as-errors` - passed
- `mix test` - passed, 535 tests, 0 failures
- `git diff -- mix.exs priv/repo examples/demo_app/priv/repo priv/templates` - no diff

## Next Phase Readiness

Phase 37 is ready for phase-level verification. Archive durability now has staged export/prune runtime behavior, honest caller surfaces, documentation of the Experimental return-shape change, and full-suite verification evidence.

---
*Phase: 37-archive-durability*
*Completed: 2026-06-04*
