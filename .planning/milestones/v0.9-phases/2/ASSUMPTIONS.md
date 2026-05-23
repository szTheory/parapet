# Phase 2 Assumptions & Decisions

## Context
Phase 2 focuses on keeping the Ecto evidence tables (`Incident`, `TimelineEntry`, `ToolAudit`) fast and lean over time by implementing automated pruning and ensuring database indexes are optimized for >100k row scale.

## Assumptions
- **Export & Hard Delete over Soft Delete**: Adding a `deleted_at` column would retain dead tuples and bloat the host database, defeating the "fast and lean" objective. We assume an export-then-delete approach is required to protect the host application's primary transactional database.
- **Tool Audit Orphan Bloat**: The `parapet_tool_audits` table currently uses `on_delete: :nilify_all`. If we delete old timelines, we risk creating massive silent database bloat with orphaned audits. We assume this constraint must be altered to `on_delete: :delete_all`.
- **Composite Index Needs**: At scale, the Archiver and Operator UI will need `[:state, :inserted_at]` on Incidents, `[:incident_id, :inserted_at]` on TimelineEntries, and `[:timeline_entry_id, :inserted_at]` on ToolAudits to avoid full table scans.
- **Oban Optionality**: `Oban` is an optional dependency. We assume the Oban cron worker (`Parapet.Evidence.ArchiveWorker`) must be conditionally compiled and that a generic `mix parapet.archive` task must exist for OS cron users.
- **Migration Delivery**: Existing projects have already run `mix parapet.gen.spine`. We assume a new Igniter task (e.g., `mix parapet.gen.archive_indexes`) is needed for upgrading existing projects, while `mix parapet.gen.spine` must be updated for new installations.

## Decisions Made (Autonomous Recommendations)
- **Archival Strategy**: Implement an **Export + Hard Delete** strategy. We will use `Ecto.Repo.stream/2` to fetch old, resolved incidents in chunks, write them to a structured format, and then delete them.
- **Export Format**: **JSON Lines (JSONL)**. It natively supports Ecto's nested maps without a mapping layer, relies on the ubiquitous `Jason` library, and is easily ingested by BigQuery/Snowflake or external analysis tools.
- **Schema Updates**: The new composite indexes and the `on_delete: :delete_all` alteration will be added to the base `parapet.gen.spine` template AND provided as an upgrade migration generator for existing users.
