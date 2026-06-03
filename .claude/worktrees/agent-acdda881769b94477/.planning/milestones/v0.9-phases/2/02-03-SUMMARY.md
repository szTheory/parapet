---
phase: 02
plan: 03
title: Archive executors
status: completed
completed_at: 2026-05-19
commits:
  - 9ad8e7e
  - 8e68459
  - ff33799
  - eeb047e
files_changed:
  - lib/mix/tasks/parapet.archive.ex
  - test/mix/tasks/parapet.archive_test.exs
  - lib/parapet/evidence/archive_worker.ex
  - test/parapet/evidence/archive_worker_test.exs
---

# Phase 02 Plan 03 Summary

Implemented the two archival execution surfaces required by Phase 02: a `mix parapet.archive` CLI entrypoint for OS cron users and a conditionally compiled `Parapet.Evidence.ArchiveWorker` for Oban-backed scheduling.

## Completed Work

1. Added `Mix.Tasks.Parapet.Archive` with `--days` and `--path` parsing via `OptionParser`.
2. Looked up the host repo from `Application.fetch_env!(:parapet, :repo)` and delegated archive execution to `Parapet.Evidence.Archiver.archive/3`.
3. Printed machine-readable JSON success output from the Mix task.
4. Added `Parapet.Evidence.ArchiveWorker` behind `if Code.ensure_loaded?(Oban) do`.
5. Implemented worker execution using Oban job args with defaults for `days` and `path`.
6. Added repo-double tests covering explicit and default argument handling for both executors.

## Verification

`mix test test/mix/tasks/parapet.archive_test.exs`

Result:
```text
Compiling 1 file (.ex)
Generated parapet app
Running ExUnit with seed: 462705, max_cases: 16

..
Finished in 0.08 seconds (0.00s async, 0.08s sync)
2 tests, 0 failures
```

`mix test test/parapet/evidence/archive_worker_test.exs`

Result:
```text
Compiling 1 file (.ex)
Generated parapet app
Running ExUnit with seed: 697936, max_cases: 16

...
Finished in 0.07 seconds (0.00s async, 0.07s sync)
3 tests, 0 failures
```

`mix test test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs`

Result:
```text
Running ExUnit with seed: 611589, max_cases: 16

.....
Finished in 0.09 seconds (0.00s async, 0.09s sync)
5 tests, 0 failures
```

## Deviations from Plan

None.

## TDD Gate Compliance

- Task 1 RED commit: `9ad8e7e` (`test(02-03): add failing archive mix task test`)
- Task 1 GREEN commit: `8e68459` (`feat(02-03): implement parapet archive mix task`)
- Task 2 RED commit: `ff33799` (`test(02-03): add failing archive worker test`)
- Task 2 GREEN commit: `eeb047e` (`feat(02-03): implement archive oban worker`)

## Self-Check: PASSED

- Summary file created at `.planning/phases/02-database-scale/02-03-SUMMARY.md`
- Task commits present: `9ad8e7e`, `8e68459`, `ff33799`, `eeb047e`
