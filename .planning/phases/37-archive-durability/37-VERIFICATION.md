---
phase: 37-archive-durability
verified: 2026-06-04T18:28:17Z
status: passed
score: 22/22 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: initial_verification_failed
  previous_score: 21/22
  closed_items:
    - "D-15: failure-injection tests now cover encode failure, verify mismatch, manifest failure, and delete-stage rerun/idempotency behavior."
  remaining_items: []
  regressions: []
---

# Phase 37: Archive Durability Verification Report

**Phase Goal:** Make archive/export/prune behavior preserve complete durable evidence or fail loudly with actionable results.
**Verified:** 2026-06-04T18:28:17Z
**Status:** passed
**Re-verification:** Yes - after D-15 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Archive maintenance treats incident evidence as a complete bundle for Parapet-owned records. | VERIFIED | `lib/parapet/evidence/archiver.ex:166` loads timeline entries, tool audits, action items, and action claims by selected incident ids; `test/parapet/evidence/archiver_test.exs:304` asserts serialized child lists and counts. |
| 2 | Partial failures return or surface actionable failure information. | VERIFIED | `Failure` carries stage, reason, run paths, and partial summary at `lib/parapet/evidence/archiver.ex:72`; failure stages are returned through write, verify, publish, manifest, and delete paths. |
| 3 | Resolved-only retention remains test-pinned, including boundary dates and active/investigating exclusions. | VERIFIED | Runtime query is `state == "resolved"` and `inserted_at < cutoff` at `lib/parapet/evidence/archiver.ex:156`; tests assert boundary, active/open/investigating, and recent records remain at `test/parapet/evidence/archiver_test.exs:367`. |
| 4 | Run summaries include counts and failure context useful to a host app or maintainer. | VERIFIED | `Summary` includes run ids, paths, counts, selected ids, bytes, and checksum at `lib/parapet/evidence/archiver.ex:33`; CLI failure output includes stage/run/count/path context at `lib/mix/tasks/parapet.archive.ex:56`. |
| 5 | D-01: archive uses a staged local export before deleting exact selected incident ids. | VERIFIED | Flow is select, load, write temp, verify, publish, manifest, then delete at `lib/parapet/evidence/archiver.ex:114`; delete uses `incident.id in ^selected_ids` at `lib/parapet/evidence/archiver.ex:269`. |
| 6 | D-02: every archive attempt returns or carries a manifest/run summary. | VERIFIED | `archive/3` returns `{:ok, %Summary{}}` or `{:error, %Failure{partial_summary: summary}}`; manifest path is part of both structs. |
| 7 | D-05: bundle includes Incident, TimelineEntry, ToolAudit, ActionItem, and ActionClaim records. | VERIFIED | Bundle loading covers all five record categories at `lib/parapet/evidence/archiver.ex:166`; test fixture and assertions cover all categories at `test/parapet/evidence/archiver_test.exs:224` and `test/parapet/evidence/archiver_test.exs:329`. |
| 8 | D-07: child counts are explicitly validated before prune. | VERIFIED | `verify_counts/2` compares decoded count totals to summary counts before publish/delete at `lib/parapet/evidence/archiver.ex:306`. |
| 9 | D-08: archive returns structured Summary or Failure tuples instead of `{:ok, :ok}`. | VERIFIED | `@spec archive/3` returns `{:ok, summary()} | {:error, failure()}` at `lib/parapet/evidence/archiver.ex:93`; tests assert `%Summary{}` and `%Failure{}`. |
| 10 | D-12: retention remains resolved incidents with inserted_at before cutoff. | VERIFIED | Query and moduledoc both state `inserted_at < cutoff`, not resolved-before-cutoff semantics. |
| 11 | D-13: cutoff behavior is deterministic in tests. | VERIFIED | Tests set deterministic `:archive_now` and assert exact cutoff at `test/parapet/evidence/archiver_test.exs:193` and `test/parapet/evidence/archiver_test.exs:321`. |
| 12 | D-15: failure-injection tests cover write, encode, manifest, delete, chunk, retry/idempotency, active exclusion, boundary, and counts. | VERIFIED | Core tests now cover write failure `test/parapet/evidence/archiver_test.exs:375`, encode failure `:409`, verify mismatch `:423`, manifest failure `:438`, delete failure `:391`, delete-stage rerun behavior `:453`, chunk max_rows `:365`, active/boundary exclusions `:367`, and counts `:329`. |
| 13 | D-16: implementation uses Phoenix/Ecto-native patterns and no new runtime dependency. | VERIFIED | Uses Ecto queries, repo transaction/stream/all/delete_all, Jason already present, and standard `File`/`:crypto`; no dependency change evidence in modified phase files. |
| 14 | D-17: failures include stage, run, selected, archived, deleted, and rerun context. | VERIFIED | Failure structs carry stage/run/path/partial summary; CLI includes stage, run_id, selected, archived, deleted, manifest_path, and reason at `lib/mix/tasks/parapet.archive.ex:56`. |
| 15 | D-09: mix parapet.archive prints machine-readable summary JSON on success. | VERIFIED | CLI encodes Summary-derived JSON at `lib/mix/tasks/parapet.archive.ex:29`; test decodes output at `test/mix/tasks/parapet.archive_test.exs:213`. |
| 16 | D-09: mix parapet.archive fails nonzero with clear Mix.raise/1 failure text. | VERIFIED | CLI calls `Mix.raise/1` on Failure at `lib/mix/tasks/parapet.archive.ex:34`; test asserts `Mix.Error` context at `test/mix/tasks/parapet.archive_test.exs:257`. |
| 17 | D-10: ArchiveWorker.perform/1 returns the same archive success/error tuple. | VERIFIED | Worker directly returns `Parapet.Evidence.Archiver.archive/3` at `lib/parapet/evidence/archive_worker.ex:18`; tests assert Summary and Failure pass-through. |
| 18 | D-11: returned values, CLI output/exit status, worker result, and manifest are truth surfaces. | VERIFIED | Library tuples, CLI JSON/Mix.raise, worker pass-through, and manifest JSON are implemented and tested. |
| 19 | D-03: archive is operational evidence export/prune, not host backup/restore. | VERIFIED | Moduledoc states the boundary and excluded host/external surfaces at `lib/parapet/evidence/archiver.ex:10`. |
| 20 | D-04: Phase 37 does not add a DB archive manifest/job table. | VERIFIED | No archive manifest/job migration or schema table artifact is present in the phase-modified implementation files. |
| 21 | D-06: external provider rows, telemetry samples, Prometheus data, Grafana state, and object-store contents remain out of bundle scope. | VERIFIED | Moduledoc explicitly excludes these surfaces at `lib/parapet/evidence/archiver.ex:10`. |
| 22 | D-14: docs state retention means resolved incidents created before cutoff, not resolved before cutoff. | VERIFIED | Moduledoc states `inserted_at < cutoff`, not `resolved_at`, at `lib/parapet/evidence/archiver.ex:15`. |

**Score:** 22/22 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/parapet/evidence/archiver.ex` | Staged archive/export/prune truth model and docs | VERIFIED | Substantive; defines Summary/Failure, staged flow, bundle loading, artifact verification, manifest writing, exact-id delete, and documented scope. |
| `test/parapet/evidence/archiver_test.exs` | Failure-injection and complete-bundle archive proofs | VERIFIED | Substantive; D-15 matrix now includes write, encode, verify mismatch, manifest failure, delete, rerun behavior, chunking, active exclusion, boundary, and counts. |
| `lib/mix/tasks/parapet.archive.ex` | Result-sensitive maintenance CLI | VERIFIED | Emits summary JSON on success and raises with structured context on failure. |
| `test/mix/tasks/parapet.archive_test.exs` | CLI summary/failure regression tests | VERIFIED | Covers success JSON, defaults, and Mix.Error failure context. |
| `lib/parapet/evidence/archive_worker.ex` | Optional Oban pass-through worker | VERIFIED | Compile-gated and delegates directly to archiver. |
| `test/parapet/evidence/archive_worker_test.exs` | Worker tuple pass-through tests | VERIFIED | Covers Summary, Failure, defaults, and Oban-unavailable branch. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Selected incident ids | Delete query | Exact id list | WIRED | `selected_ids` is materialized before write and passed to `delete_records/3`; delete query is `incident.id in ^selected_ids`. |
| Archive temp artifact | `delete_records` | Verify before prune | WIRED | `archive/3` runs `write_archive -> verify_archive -> publish_archive -> write_manifest -> delete_records`. |
| `Parapet.Evidence.Archiver.archive/3` | `mix parapet.archive` | Summary JSON or Mix.raise | WIRED | Mix task pattern matches `%Summary{}` and `%Failure{}` and surfaces both outcomes. |
| `Parapet.Evidence.Archiver.archive/3` | `ArchiveWorker.perform/1` | Tuple pass-through | WIRED | Worker returns the archive tuple unchanged. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `lib/parapet/evidence/archiver.ex` | `selected_ids`, `bundles`, `Summary.counts` | Ecto `repo.stream/2`, `repo.all/1`, and `repo.delete_all/1` over Parapet spine schemas | Yes | FLOWING |
| `lib/mix/tasks/parapet.archive.ex` | CLI summary/failure output | `%Summary{}` or `%Failure{}` returned from `Archiver.archive/3` | Yes | FLOWING |
| `lib/parapet/evidence/archive_worker.ex` | Worker result tuple | Direct `Archiver.archive/3` return | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Focused archive/CLI/worker tests | `mix test test/parapet/evidence/archiver_test.exs test/mix/tasks/parapet.archive_test.exs test/parapet/evidence/archive_worker_test.exs` | 14 tests, 0 failures | PASS |
| Formatting | `mix format --check-formatted` | exit 0 | PASS |
| Compile with warnings as errors | `mix compile --warnings-as-errors` | exit 0 | PASS |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| None discovered | `find scripts -path '*/tests/probe-*.sh'` plus phase plan/summary grep | No probe files or declarations found | SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| ARCH-01 | 37-01, 37-03 | Preserve complete resolved evidence bundle including incident, timeline, tool audit, and related owned evidence. | SATISFIED | Bundle loading and tests cover incident, timeline entries, nested tool audits, action items, and action claims. |
| ARCH-02 | 37-01, 37-02, 37-03 | Fail loudly/actionably on partial persistence/export/delete failure. | SATISFIED | Runtime returns staged `Failure` structs, CLI raises with context, worker passes failures through, and D-15 failure-injection coverage is now complete. |
| ARCH-03 | 37-01, 37-03 | Resolved-only retention contract, active/investigating exclusions, deterministic boundary dates. | SATISFIED | Query and tests pin `state == "resolved"` and `inserted_at < cutoff`; active/open/investigating and exact-boundary records remain. |
| ARCH-04 | 37-01, 37-02, 37-03 | Structured run summary with counts, skipped records, failures, and debug context. | SATISFIED | Summary includes counts, paths, selected ids, bytes, checksum; failures include stage/reason/partial summary; CLI/worker surface context. |

No orphaned Phase 37 requirement IDs were found in `.planning/REQUIREMENTS.md`: ARCH-01, ARCH-02, ARCH-03, and ARCH-04 are all declared in plan frontmatter and mapped to Phase 37.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | - | - | - | Debt/stub scan found no TBD/FIXME/XXX/TODO/HACK/placeholder markers in the Phase 37 modified implementation/test files. |

### Human Verification Required

None.

### Gaps Summary

No blocking gaps remain. The prior D-15 gap is closed by tests for encode failure, verification mismatch, manifest write failure, and delete-stage rerun behavior, alongside the previously present write/delete/chunk/active/boundary/count coverage. Later phases 38 and 39 cover scoped UI routes and adoption docs; neither defers or masks a remaining archive durability must-have.

---

_Verified: 2026-06-04T18:28:17Z_
_Verifier: the agent (gsd-verifier)_
