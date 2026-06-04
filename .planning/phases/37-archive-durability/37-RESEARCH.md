# Phase 37: Archive Durability - Research

**Phase:** 37 - Archive Durability
**Date:** 2026-06-04
**Status:** Complete

## Research Complete

Phase 37 should harden the existing archive path by making the destructive prune step depend on a verified local evidence export. The implementation should stay boring: no new dependency, no schema table, no object store, and no host backup ownership.

## Current Code Findings

### Existing archive flow

- `lib/parapet/evidence/archiver.ex` currently streams resolved incidents older than `DateTime.utc_now() - retention_days`, preloads `timeline_entries: :tool_audits`, appends JSONL directly to the final path, and deletes each streamed chunk inside the same transaction.
- The current return contract is `{:ok, :ok}` through `repo.transaction/1`.
- `mix parapet.archive` ignores the archive result and always prints `{"status":"ok","result":"ok"}` after invocation.
- `Parapet.Evidence.ArchiveWorker.perform/1` already returns `Parapet.Evidence.Archiver.archive/3`, so structured results can propagate to Oban without a new worker contract.

### Evidence bundle

- The archive currently preserves `Incident`, `TimelineEntry`, and nested `ToolAudit` records.
- It does not preserve incident-linked `ActionItem` or `ActionClaim` records, even though both are Parapet-owned evidence surfaces.
- `ActionClaim` is especially important because it stores terminal failure context and idempotency/ownership history. Its migration uses `on_delete: :delete_all`, so incident deletion can remove claims unless the archive captures them first.
- Demo `ActionItem` linkage uses `on_delete: :nilify_all`, but that should not be relied on as archive truth. Incident-linked action items must be selected and serialized before the prune so the archive bundle is complete.

### Test surface

- `test/parapet/evidence/archiver_test.exs` proves one happy path only: resolved-only selection, nested timeline/tool audit preload, chunk size, and investigating exclusion.
- `test/mix/tasks/parapet.archive_test.exs` proves CLI argument parsing and static success JSON only.
- `test/parapet/evidence/archive_worker_test.exs` proves optional Oban worker compile behavior and happy path result only.
- Existing fake repos are already a useful failure-injection seam. They should be expanded rather than replaced with full DB integration tests.

## External Pattern Findings

### Ecto transaction composition

Ecto.Multi supports named transactional steps and makes failures identify the operation, failed value, and changes so far. The plan can use either `Ecto.Multi` or explicit transaction control flow, but the failure struct must capture a stage name and partial summary either way. `Ecto.Multi.run/3` functions must return `{:ok, value}` or `{:error, value}`, and an error aborts later operations.

Source: https://hexdocs.pm/ecto/Ecto.Multi.html

### Database delete semantics

Foreign-key `on_delete` behavior is a backstop, not proof that the export is complete. The archive should count and serialize Parapet-owned child records before deleting exact incident ids.

Source: https://hexdocs.pm/ecto_sql/Ecto.Migration.html

### Operational command behavior

Django's custom management command pattern is a useful analogy for Mix task behavior: a maintenance command should surface actionable command failure instead of producing successful output after a partial or ambiguous operation. For Parapet, `Mix.raise/1` is the right CLI failure shape because it exits nonzero and is testable.

Source: https://docs.djangoproject.com/en/5.2/howto/custom-management-commands/

### Snapshot/export status

etcd snapshot operations expose status details such as hash, revision, key count, and size. Parapet should copy the "artifact plus inspectable status" pattern, not the backup semantics. A JSONL export with a manifest/run summary containing count, byte, checksum, and stage metadata is sufficient for this phase.

Source: https://etcd.io/docs/v3.6/tasks/operator/how-to-save-database/

### Background job retry context

Sidekiq's error-handling guidance reinforces that background job systems rely on meaningful exceptions/results for retry and dead-job diagnosis. Parapet's Oban worker should return the archiver's structured error tuple so retry/dead-job behavior carries stage, run id, and partial summary context.

Source: https://github.com/sidekiq/sidekiq/wiki/Error-Handling

## Recommended Architecture

### Staged local export

Use a run-scoped temp path derived from the requested archive path:

- final artifact: caller-provided `path`
- temp artifact: sibling temp file including `run_id`
- manifest: sibling manifest path, such as `#{path}.#{run_id}.manifest.json`

The exact naming can change during execution, but it must be deterministic enough for tests and support issue attachment.

### Run sequence

1. Compute deterministic `started_at`, `cutoff`, and `run_id`.
2. Select exact eligible incident ids with current runtime semantics: `state == "resolved"` and `inserted_at < cutoff`.
3. Fetch/preload complete Parapet-owned evidence for those ids:
   - incidents
   - timeline entries
   - tool audits
   - incident-linked action items
   - incident-linked action claims
4. Serialize one JSON object per incident bundle to a run-scoped temp JSONL file.
5. Verify temp artifact:
   - selected count matches archived count
   - child per-table counts match serialized bundle counts
   - bytes written is nonzero when records are selected
   - checksum is computed
   - every line decodes as JSON
6. Publish artifact and manifest atomically enough for local filesystem semantics.
7. Delete only the selected incident ids after publish/verification succeeds.
8. Return `{:ok, %Summary{}}` with published paths, counts, checksum, and timestamps.

### Failure shape

Return `{:error, %Parapet.Evidence.Archiver.Failure{}}` with:

- `status: :error`
- `stage`
- `reason`
- `run_id`
- `path`
- `temp_path`
- `manifest_path`
- `partial_summary`

Useful stages:

- `:select_records`
- `:write_archive`
- `:verify_archive`
- `:publish_archive`
- `:write_manifest`
- `:delete_records`

The failure value should answer what happened and whether it is safe to rerun. If export/publish fails before delete, no records should be pruned. If delete fails after a verified publish, the failure should say records were not fully pruned and include exact selected/deleted counts.

### Summary shape

Recommended struct fields:

- `status`
- `run_id`
- `schema_version`
- `path`
- `temp_path`
- `manifest_path`
- `retention_days`
- `cutoff`
- `started_at`
- `finished_at`
- `selected_ids`
- `selected_count`
- `archived_count`
- `deleted_count`
- `skipped_count`
- `counts`
- `bytes_written`
- `checksum`
- `failure_stage`
- `failure_reason`

The final implementation may omit or rename fields only if tests still prove all Phase 37 decisions and success criteria.

## Validation Architecture

### Required test dimensions

- Complete bundle serialization: incident, timeline entries, tool audits, action items, and action claims are present in archived JSONL.
- Exact resolved-only selection: active/open/investigating incidents remain untouched.
- Exact cutoff boundary: `inserted_at == cutoff` is not archived; `inserted_at < cutoff` is archived.
- Deterministic clock/cutoff: internal option or helper pins timestamps in tests without becoming a prominent host-facing API.
- Write failure: no incident deletion and an error failure with stage `:write_archive` or equivalent.
- Encode failure: no incident deletion and an actionable error.
- Manifest mismatch/decode verification failure: no incident deletion.
- Publish/manifest write failure: no incident deletion.
- Delete failure: archive artifact remains published, deleted count is accurate, return is `{:error, %Failure{stage: :delete_records}}`.
- CLI failure: `mix parapet.archive` raises/fails nonzero and does not print success JSON after failure.
- CLI success: prints machine-readable summary JSON.
- Oban worker: returns the same success/error tuple from the archiver.

### Suggested commands

- `mix test test/parapet/evidence/archiver_test.exs`
- `mix test test/mix/tasks/parapet.archive_test.exs`
- `mix test test/parapet/evidence/archive_worker_test.exs`
- `mix test`
- `mix format --check-formatted`
- `mix compile --warnings-as-errors`

## Pitfalls

- Do not add a DB-backed archive run table in this phase. It changes install contents and durable schema burden.
- Do not switch retention semantics to `resolved_at`; the schema has no such field.
- Do not treat host backups, object stores, or external provider data as Parapet-owned archive scope.
- Do not rely on `on_delete` cascades as the archive proof.
- Do not keep appending directly to the final JSONL path before verification.
- Do not let `mix parapet.archive` print success after partial failure.
- Do not add new runtime dependencies for checksum or file staging. Use standard library primitives.

## Planning Recommendation

Plan in three waves:

1. Core archiver data model, staged artifact flow, complete bundle queries, and failure-injection tests.
2. CLI and optional Oban worker surfaces that propagate the structured summary/failure contract.
3. Compatibility notes, ExDoc/CHANGELOG coverage for the Experimental API change, full-suite verification, and planning gap closure.

