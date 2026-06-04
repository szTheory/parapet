# Phase 37: Archive Durability - Context

**Gathered:** 2026-06-04 (assumptions mode with subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make Parapet's existing archive/export/prune path preserve complete Parapet-owned evidence for resolved incidents or fail loudly with actionable results. This phase hardens the archive truth model for `Parapet.Evidence.Archiver`, `mix parapet.archive`, and the optional Oban `ArchiveWorker`; it does not turn Parapet into a host backup system, add external storage providers, add a durable archive job schema, or change generated UI route behavior.

</domain>

<decisions>
## Implementation Decisions

### Archive truth model
- **D-01:** Replace the direct final-file append/delete flow with a staged local export: select exact eligible incident ids, preload the complete Parapet-owned bundle, write JSONL to a run-specific temp artifact, verify counts/bytes/checksum/decodeability, publish the artifact/manifest, then delete only the exact selected ids.
- **D-02:** Add a manifest/run summary for every archive attempt. It should include at least `run_id`, archive schema version, path/temp path, retention days, cutoff timestamp, started/finished timestamps, selected ids/counts, archived counts, deleted counts, skipped records, failure stage/reason, bytes written, and checksum.
- **D-03:** Treat the archive as operational evidence export/prune, not backup/restore. Host database backups and object-store retention remain host-owned responsibilities and documentation topics, not core Phase 37 runtime behavior.
- **D-04:** Do not add a DB archive manifest/job table in Phase 37. It would improve resumability, but it changes install contents, schema permanence, and host maintenance burden.

### Evidence bundle
- **D-05:** The complete Parapet-owned bundle for each archived incident includes `Parapet.Spine.Incident`, associated `TimelineEntry`, associated `ToolAudit`, incident-linked `ActionItem`, and incident-linked `ActionClaim` records.
- **D-06:** External provider records, host app domain rows, telemetry samples, Prometheus data, Grafana state, and object-store contents are outside the archive bundle. The archive may preserve references already stored inside Parapet evidence payloads.
- **D-07:** Validate/count child records explicitly before prune and include per-table counts in the summary. Database foreign-key `on_delete` behavior remains a safety backstop, not the only archive truth model.

### Result and failure shape
- **D-08:** Change the Experimental archive return contract from `{:ok, :ok}` to `{:ok, %Parapet.Evidence.Archiver.Summary{}}` and `{:error, %Parapet.Evidence.Archiver.Failure{}}`, or equivalently named structs under `Parapet.Evidence.Archiver`.
- **D-09:** `mix parapet.archive` should print the same machine-readable summary as JSON on success and fail nonzero with a clear `Mix.raise/1` message on failure. It must not print `{"status":"ok"}` after partial export/delete failure.
- **D-10:** `Parapet.Evidence.ArchiveWorker.perform/1` should return the same archive success/error tuple so Oban retry/dead-job behavior carries meaningful failure context.
- **D-11:** Logs and telemetry are optional supplements, not the source of truth. Phase 37 success/failure must be observable from returned values, CLI output/exit status, worker result, and written manifest.

### Retention semantics
- **D-12:** Preserve the current resolved-only `inserted_at < cutoff` runtime behavior for Phase 37 because the schema has no `resolved_at` and adding one would require migrations, generator/demo updates, resolution-path changes, and backfill semantics.
- **D-13:** Make cutoff/clock behavior deterministic for tests through an internal option or helper so boundary cases are pinned exactly. This should not become a prominent host-facing API unless planning finds a clear need.
- **D-14:** Document the semantic limitation: current retention means "resolved incidents created before the cutoff", not "incidents resolved before the cutoff". A later `resolved_at` lifecycle phase can improve that if it is worth the schema/API cost.

### Verification and DX
- **D-15:** Focus Phase 37 tests on trust-boundary failures: write failure, encode failure, manifest mismatch, delete failure, partial chunk behavior, retry/idempotency behavior, active/investigating exclusions, exact cutoff boundary, and summary counts.
- **D-16:** Keep implementation boring and Phoenix/Ecto-native: host repo remains explicit, Oban remains optional/compile-out clean, no new runtime dependencies, no object-store auth/config surface, and no hidden ownership of host backup policy.
- **D-17:** Favor 3am operator ergonomics: every failure should answer what path/run failed, what stage failed, what was selected, what was archived, what was deleted, what remains safe to rerun, and what the maintainer should inspect next.

### the agent's Discretion
- Exact struct module names and field names, provided they are stable enough for ExDoc and tests and remain obviously tied to archive runs.
- Whether the manifest is a sidecar JSON file, a final JSON summary next to the JSONL, or embedded in a run directory, provided the artifact is inspectable and atomic publish semantics are test-pinned.
- Exact checksum algorithm, provided it uses standard library primitives and is included in tests.
- Whether to support append compatibility immediately or move toward run-specific archive files. If preserving append behavior, staging must still prevent ambiguous partial appends.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and trust diagnosis
- `.planning/ROADMAP.md` - Phase 37 goal and success criteria.
- `.planning/REQUIREMENTS.md` - `ARCH-01` through `ARCH-04`.
- `.planning/QUALITY-EVALUATION.md` - archive/delete ambiguity diagnosis and "do not build a full backup system" boundary.
- `.planning/PROJECT.md` - v1.4 trust-hardening posture and stable-main constraints.
- `.planning/STATE.md` - current milestone/phase position.

### Existing archive implementation
- `lib/parapet/evidence/archiver.ex` - current direct JSONL append plus delete flow.
- `lib/mix/tasks/parapet.archive.ex` - current CLI always prints success after invoking archiver.
- `lib/parapet/evidence/archive_worker.ex` - optional Oban worker integration.
- `test/parapet/evidence/archiver_test.exs` - current happy-path archive proof.
- `test/mix/tasks/parapet.archive_test.exs` - current CLI proof.
- `test/parapet/evidence/archive_worker_test.exs` - current worker proof.

### Evidence schema and ownership
- `lib/parapet/evidence.ex` - public evidence context and host repo lookup.
- `lib/parapet/spine/incident.ex` - incident lifecycle fields and absence of `resolved_at`.
- `lib/parapet/spine/timeline_entry.ex` - durable incident timeline records.
- `lib/parapet/spine/tool_audit.ex` - durable tool execution audit records.
- `lib/parapet/spine/action_item.ex` - incident-linked operator follow-up records.
- `lib/parapet/spine/action_claim.ex` - incident-linked durable ownership/failure records.
- `priv/repo/migrations/20260521010000_create_parapet_action_claims.exs` - action claim FK/delete behavior.
- `examples/demo_app/priv/repo/migrations/20260525000000_add_parapet_spine_tables.exs` - demo spine FK/delete behavior.
- `examples/demo_app/priv/repo/migrations/20260525000001_add_action_item_kind_and_incident_id.exs` - action item incident linkage.

### Product and research prompts
- `prompts/PARAPET-GSD-IDEA.md` - telemetry vs durable evidence distinction and operator-grade DX.
- `prompts/parapet-brand-identity-deep-research.md` - calm, evidence-first, Phoenix-native product posture.
- `prompts/parapet-engineering-dna-from-sibling-libs.md` - host-owned, inspectable, SRE-grade engineering posture.
- `prompts/sre-observability-elixir-lib-deep-reseach.md` - observability-library lessons and evidence posture.
- `prompts/prior-art/threadline-audit-lib-domain-model-reference.md` - audit/export/retention lessons and operator trust criteria.

### External pattern references
- `https://etcd.io/docs/v3.6/tasks/operator/how-to-save-database/` - snapshot artifact/status pattern.
- `https://docs.gitlab.com/administration/backup_restore/backup_archive_process/` - staging/metadata/restore-test lessons.
- `https://docs.djangoproject.com/en/5.2/howto/custom-management-commands/` - command failure behavior analogous to `Mix.raise/1`.
- `https://docs.djangoproject.com/en/4.1/ref/django-admin/#dumpdata` - explicit export scope and hidden-record footguns.
- `https://guides.rubyonrails.org/active_record_migrations.html` - status-oriented operational task precedent.
- `https://github.com/sidekiq/sidekiq/wiki/Error-Handling` - retry/dead-job error context lessons.
- `https://docs.gitlab.com/development/sidekiq/` - job retry/operability lessons.
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - transactional DB composition.
- `https://hexdocs.pm/ecto_sql/Ecto.Migration.html` - FK `on_delete` behavior and migration semantics.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Parapet.Evidence.Archiver.archive/3` already centralizes archive selection, preloading, JSON encoding, file write, and delete behavior.
- `Mix.Tasks.Parapet.Archive` already gives a human/cron entry point and can become the primary machine-readable success/failure surface without adding a new command.
- `Parapet.Evidence.ArchiveWorker` already compiles only when Oban is available and can propagate archive result tuples into normal Oban retry semantics.
- Existing fake repo tests are a good base for failure injection because they already model transaction, stream, preload, and delete calls.

### Established Patterns
- Parapet keeps host ownership explicit: repo is host-configured, generated/install surfaces stay inspectable, optional dependencies compile out cleanly, and Parapet avoids taking over host auth/router/storage policy.
- Durable evidence is a product trust boundary. Telemetry/logging may be helpful, but Parapet's stronger claim needs inspectable records and explicit outcomes.
- Existing archive tests prove only happy-path resolved-only behavior and nested timeline/tool-audit export. They do not prove partial failure behavior, exact boundary semantics, action item/claim preservation, or summary accuracy.
- The archive API is Experimental in `docs/stability.md`, so this is the right phase to improve the result shape before users automate around `{:ok, :ok}`.

### Integration Points
- Update `Parapet.Evidence.Archiver` with staging, manifest, structured summary/failure structs, deterministic cutoff, bundle preloads/counts, and exact-id deletion.
- Update `mix parapet.archive` to print success summaries and raise/fail nonzero on archive failures.
- Update `Parapet.Evidence.ArchiveWorker` to pass through success/error tuples for Oban.
- Expand `test/parapet/evidence/archiver_test.exs`, `test/mix/tasks/parapet.archive_test.exs`, and `test/parapet/evidence/archive_worker_test.exs` for failure injection and summary assertions.

</code_context>

<specifics>
## Specific Ideas

- Preferred summary shape: `%Parapet.Evidence.Archiver.Summary{status: :ok, run_id: "...", path: "...", manifest_path: "...", retention_days: 90, cutoff: ~U[...], selected_count: 17, archived_count: 17, deleted_count: 17, skipped_count: 0, bytes_written: 124880, checksum: "...", started_at: ..., finished_at: ...}`.
- Preferred failure shape: `%Parapet.Evidence.Archiver.Failure{status: :error, stage: :write_archive | :verify_manifest | :delete_records | :publish_archive, reason: term, run_id: "...", path: "...", partial_summary: %Summary{...}}`.
- Preferred operator microcopy for CLI/docs: "Archive failed before prune" when staging/publish fails, and "Archive failed after publish; records were not fully pruned" only if a delete-stage failure leaves DB rows intact. Avoid vague "archive failed" output without stage/context.
- The default archive artifact should be easy to attach to a support issue: JSONL plus manifest JSON is more useful than logs alone.
- If planning discovers append compatibility is necessary, append only after staging verification and record enough run metadata to detect duplicate or partial appends.

</specifics>

<deferred>
## Deferred Ideas

- Add `resolved_at` retention semantics in a later schema/migration phase if the product wants "N days after resolution" instead of the current "resolved incidents created before cutoff" behavior.
- Add a DB-backed archive run table if host apps need cross-process resumability, in-UI archive status, or long-term archive-run auditability.
- Add external storage/object-store sinks as host-owned adapter documentation or a later explicit extension point.
- Add archive status UI. Phase 37 has no UI deliverable; Phase 39 docs may cover supportability, and a later UI phase can expose summaries if needed.

### Reviewed Todos (not folded)

None.

</deferred>
