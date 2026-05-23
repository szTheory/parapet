---
phase: 02
plan: 02
title: Evidence archiver
status: completed
completed_at: 2026-05-19
commits:
  - 487ae0f
  - a63201f
files_changed:
  - lib/parapet/evidence/archiver.ex
  - test/parapet/evidence/archiver_test.exs
---

# Phase 02 Plan 02 Summary

Implemented `Parapet.Evidence.Archiver.archive/3` to stream old non-open incidents in bounded chunks, append each archived incident to JSONL on disk, preload nested timeline/tool audit evidence before export, and hard delete archived incident IDs after each chunk.

## Completed Work

1. Added `Parapet.Evidence.Archiver` with a single transactional archive flow over `Parapet.Spine.Incident`.
2. Filtered incidents to `state != "open"` and `inserted_at` older than the retention window.
3. Streamed incidents with configurable chunk sizing via `config :parapet, :archive_chunk_size`, defaulting to `100`.
4. Serialized incidents, timeline entries, tool audits, and timestamps into JSONL and appended each line batch with `File.write!/3`.
5. Added an integration-style test using an in-memory repo double that verifies transaction usage, nested preload calls, JSONL output, and chunked `delete_all` behavior.

## Verification

`mix test test/parapet/evidence/archiver_test.exs`

Result:
```text
Running ExUnit with seed: 630808, max_cases: 16

.
Finished in 0.08 seconds (0.00s async, 0.08s sync)
1 test, 0 failures
```

## Deviations from Plan

None.

## TDD Gate Compliance

- RED commit: `487ae0f` (`test(02-02): add failing archiver integration test`)
- GREEN commit: `a63201f` (`feat(02-02): implement evidence archiver`)

## Self-Check: PASSED

- Summary file created at `.planning/phases/02-database-scale/02-02-SUMMARY.md`
- Task commits present: `487ae0f`, `a63201f`
