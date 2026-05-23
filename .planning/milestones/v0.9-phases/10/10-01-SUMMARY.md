---
phase: 10-tighten-archive-retention-semantics
plan: 01
status: completed
completed_at: 2026-05-22
---

# Phase 10 Plan 01 Summary

## Objective

Repair the archive-retention contract in runtime code and regression tests without widening the public `mix parapet.archive` surface.

## Completed Work

1. Narrowed `Parapet.Evidence.Archiver.archive_query/2` from a negative `open` filter to an explicit resolved-only predicate while preserving the existing cutoff, chunked stream, preload, JSONL export, and delete flow.
2. Updated `Mix.Tasks.Parapet.Archive` documentation to state that only resolved incidents older than the retention window are archived, without changing flags, defaults, or the JSON success payload.
3. Reworked the archiver regression test so an old `investigating` incident is a negative proof case that remains active and is excluded from the archive output.
4. Extended the mix task and archive worker tests with old `investigating` fixtures so both entry surfaces prove they inherit the corrected retention rule and still use the bounded transaction-backed stream path.

## Verification

```bash
mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs
```

Result: passed (`6 tests, 0 failures`).

## Deviations from Plan

The plan's validation snippets used the obsolete `mix test -x` flag. Verification was rerun with the same targeted test files but without `-x`, which is required by the current Mix task interface.

## Self-Check: PASSED
