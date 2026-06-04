# Phase 37: Archive Durability - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-04T16:42:16Z
**Phase:** 37-archive-durability
**Mode:** assumptions with explicit subagent research
**Areas analyzed:** archive truth model, result/failure shape, retention semantics, evidence bundle scope, ecosystem lessons, operator/DX posture

## Assumptions Presented

### Initial Assumptions

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Change Experimental archive API from `{:ok, :ok}` to structured run summaries/actionable errors. | Likely | `lib/parapet/evidence/archiver.ex`, `lib/mix/tasks/parapet.archive.ex`, `lib/parapet/evidence/archive_worker.ex`, `docs/stability.md` |
| Harden archive with filesystem staging/manifest semantics around existing JSONL path, not a DB table or new dependency. | Likely | `.planning/QUALITY-EVALUATION.md`, `lib/parapet/evidence/archiver.ex`, `.planning/REQUIREMENTS.md` |
| Bundle should include Parapet-owned incident evidence and exclude external provider data. | Likely | `lib/parapet/evidence.ex`, spine schemas, migrations |
| Preserve current `inserted_at < cutoff` retention semantics and pin exact boundary behavior. | Likely | `lib/parapet/spine/incident.ex`, `lib/parapet/evidence/archiver.ex`, current tests |
| Verification should focus on failure injection and exact summaries across archiver, Mix task, and worker. | Confident | current tests only prove happy path; `ARCH-02` and `ARCH-04` require actionable failure/summary behavior |

## Corrections Made

The user requested deeper discussion/research for every assumption instead of a simple yes/no confirmation. The resulting recommendations refined the initial bundle assumption:

- **Original assumption:** Bundle includes Incident + TimelineEntry + ToolAudit + incident-linked ActionItem; exclude transient ActionClaim locks.
- **Correction after code inspection/research:** Include incident-linked `ActionClaim` records too. The schema describes them as durable ownership records and stores terminal failure context, so deleting resolved incidents without archiving claims can lose Parapet-owned evidence.

## Subagent Research Summary

### Archive architecture

Recommended staged local export with manifest and atomic publish, then exact-id delete. Compared direct JSONL append/delete, staged temp file plus manifest, DB manifest/job table, and external object-store/backups. Recommendation: staged local artifacts are the right Phase 37 balance because they avoid new schema/dependency burden while making archive/delete truth inspectable.

### Result and DX shape

Recommended `{:ok, %Summary{}}` / `{:error, %Failure{}}` for library/worker callers, JSON success output for `mix parapet.archive`, and `Mix.raise/1` on CLI failure. Rejected log-only and `{:ok, :ok}` because they leave cron/Oban/operators unable to diagnose partial failure.

### Retention semantics

Recommended preserving current resolved-only `inserted_at < cutoff` behavior for Phase 37, adding deterministic clock/cutoff testing, and deferring `resolved_at` because it requires schema/generator/demo/resolution-path/backfill work. Recommended explicit child validation/counting with FK cascade as a backstop.

### Ecosystem lessons

Research compared etcd snapshots, GitLab backup archive flow, Django management commands and `dumpdata`, Rails status-oriented tasks, Sidekiq/GitLab job retry semantics, and Sentry retention/export boundaries. Patterns to copy: concrete artifacts, status/summary metadata, staging before destructive action, explicit export scope, retry-useful failures, and clear "not a backup system" documentation.

## External Research

- etcd snapshot docs: artifact status with hash/revision/size informs manifest/checksum/status recommendation.
- GitLab backup archive process: staging and metadata inform staged export before deletion.
- Django management command docs: command errors inform `Mix.raise/1` CLI failure posture.
- Django `dumpdata`: explicit export scope informs complete-bundle tests and hidden-record footguns.
- Rails migration status docs: status-oriented operational tasks inform inspectable archive summaries.
- Sidekiq and GitLab Sidekiq docs: retry/dead-job semantics inform meaningful Oban error tuples.
- Ecto docs: `Ecto.Multi` and migration FK semantics inform DB transaction/backstop recommendations.

## Auto-Resolved

Not applicable.
