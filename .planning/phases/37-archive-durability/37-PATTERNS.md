# Phase 37: Archive Durability - Pattern Map

**Generated:** 2026-06-04
**Status:** Complete

## Files To Modify

| File | Role | Closest Existing Pattern | Notes |
|------|------|--------------------------|-------|
| `lib/parapet/evidence/archiver.ex` | Core archive/export/prune implementation | Existing direct archiver implementation | Keep host repo explicit, avoid new deps, preserve Experimental callout. |
| `test/parapet/evidence/archiver_test.exs` | Core failure-injection and bundle tests | Existing `FakeRepo` Agent test harness | Expand fake repo to model action items, action claims, write/delete failures, deterministic clock. |
| `lib/mix/tasks/parapet.archive.ex` | Operator/cron CLI surface | Existing Mix task shape | Continue using `OptionParser`; change output from static success to encoded summary JSON and `Mix.raise/1` on failure. |
| `test/mix/tasks/parapet.archive_test.exs` | CLI contract tests | Existing `Mix.Shell.Process` test harness | Assert success JSON contains summary fields and failure path raises without success JSON. |
| `lib/parapet/evidence/archive_worker.ex` | Optional Oban worker surface | Existing compile-gated Oban module | Keep compile-out behavior; no new dependency or queue ownership changes. |
| `test/parapet/evidence/archive_worker_test.exs` | Optional worker tests | Existing `if Code.ensure_loaded?(Oban)` split | Assert worker passes through `{:ok, %Summary{}}` and `{:error, %Failure{}}`. |
| `docs/stability.md` | Stability contract reference | Existing public API tier table and Experimental policy | Keep Experimental classification; mention new summary/failure structs only if executor adds public nested modules. |
| `CHANGELOG.md` | Experimental API change notice | Existing semver changelog headings | Add unreleased note for `Parapet.Evidence.Archiver.archive/3` return contract if execution changes it. |

## Data Flow

1. Caller passes `repo`, archive `path`, and `retention_days`.
2. Archiver computes `cutoff` from clock and selects exact eligible incident ids.
3. Archiver loads all Parapet-owned child data by selected ids.
4. Archiver writes run-scoped temp JSONL and manifest summary.
5. Archiver verifies archive artifact before any prune.
6. Archiver publishes artifact/manifest.
7. Archiver deletes only selected incident ids.
8. CLI and worker expose the same summary/failure truth.

## Concrete Code Excerpts

### Current direct append and delete flow

`lib/parapet/evidence/archiver.ex` currently contains:

```elixir
File.write!(path, jsonl <> "\n", [:append, :utf8])

ids = Enum.map(incidents, & &1.id)
repo.delete_all(from(incident in Incident, where: incident.id in ^ids))
```

This is the main ambiguity to replace with staged write, verification, publish, and exact-id prune.

### Current CLI success behavior

`lib/mix/tasks/parapet.archive.ex` currently contains:

```elixir
_result = Parapet.Evidence.Archiver.archive(repo, path, days)

Mix.shell().info(Jason.encode!(%{status: "ok", result: "ok"}))
```

This must become result-sensitive output.

### Current worker pass-through

`lib/parapet/evidence/archive_worker.ex` already contains:

```elixir
Parapet.Evidence.Archiver.archive(repo, path, days)
```

The worker likely needs only test updates unless execution discovers Oban-specific formatting concerns.

## Implementation Guidance

- Prefer nested structs such as `Parapet.Evidence.Archiver.Summary` and `Parapet.Evidence.Archiver.Failure` to keep the API tied to the Experimental module.
- Keep all filesystem helpers private unless tests need a narrow injectable option.
- Add an internal `:now` option or private helper for deterministic cutoff tests, but do not promote it as a host-facing feature.
- Use standard library checksum functionality such as `:crypto.hash/2` and `Base.encode16/2`; no new dependency.
- Normalize structs with the existing recursive approach, but make sure action items and action claims are included as child lists in each incident bundle.
- Keep delete queries constrained to exact selected ids, not recomputed cutoff queries.
- Make zero-selected runs valid: no destructive action, summary count zero, artifact/manifest behavior should be test-pinned by executor.

## Verification Focus

- Archiver tests should fail before implementation for missing action item/claim bundle data.
- Failure-injection tests must assert deletion did not happen for pre-delete failures.
- Delete-stage tests must assert returned failure context identifies `:delete_records` and includes selected/deleted counts.
- CLI tests must assert failure raises and no `{"status":"ok"}` line is emitted on failure.
- Worker tests must assert exact tuple pass-through.

