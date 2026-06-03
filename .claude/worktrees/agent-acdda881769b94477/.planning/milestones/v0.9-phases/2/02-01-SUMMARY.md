---
phase: 02
plan: 01
title: Archive index generators
status: completed
completed_at: 2026-05-19
commits:
  - d672456
  - 2c6cbcc
  - e05aaac
  - acda0ef
files_changed:
  - lib/mix/tasks/parapet.gen.archive_indexes.ex
  - test/mix/tasks/parapet.gen.archive_indexes_test.exs
  - lib/mix/tasks/parapet.gen.spine.ex
  - test/mix/tasks/parapet.gen.spine_test.exs
---

# Phase 02 Plan 01 Summary

Implemented the archive index upgrade generator for existing installs and updated the spine generator so new installs get the cascading delete FK and the three composite evidence indexes by default.

## Completed Work

1. Added `Mix.Tasks.Parapet.Gen.ArchiveIndexes` to generate `update_parapet_evidence_indexes_and_constraints` with explicit `up/0` and `down/0`.
2. Added structural tests for the generated upgrade migration, including FK constraint replacement and composite indexes.
3. Updated `Mix.Tasks.Parapet.Gen.Spine` to emit `on_delete: :delete_all` for `parapet_tool_audits.timeline_entry_id`.
4. Updated the spine generator test to assert the new FK behavior and composite indexes from the migration AST.

## Verification

`mix test test/mix/tasks/parapet.gen.archive_indexes_test.exs`

Result:
```text
Running ExUnit with seed: 705345, max_cases: 16

.
Finished in 0.08 seconds (0.08s async, 0.00s sync)
1 test, 0 failures
```

`mix test test/mix/tasks/parapet.gen.spine_test.exs`

Result:
```text
Compiling 1 file (.ex)
Generated parapet app
Running ExUnit with seed: 997468, max_cases: 16

.
Finished in 0.08 seconds (0.08s async, 0.00s sync)
1 test, 0 failures
```

`mix test test/mix/tasks/parapet.gen.archive_indexes_test.exs test/mix/tasks/parapet.gen.spine_test.exs`

Result:
```text
Running ExUnit with seed: 616952, max_cases: 16

..
Finished in 0.08 seconds (0.08s async, 0.00s sync)
2 tests, 0 failures
```

## Deviations from Plan

None.

## Self-Check: PASSED

- Summary file created at `.planning/phases/02-database-scale/02-01-SUMMARY.md`
- Task commits present: `d672456`, `2c6cbcc`, `e05aaac`, `acda0ef`
