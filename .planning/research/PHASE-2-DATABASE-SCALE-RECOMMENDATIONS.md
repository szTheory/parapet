# Phase 2 Database Scale & Pruning Recommendations

## Executive Summary
To scale the Parapet Operator UI and keep host application databases fast and lean, we must address the bloat caused by high-volume evidence tables (`Incident`, `TimelineEntry`, `ToolAudit`). This document outlines cohesive, one-shot recommendations for handling Ecto database pruning, composite indexing, and migration strategies idiomatic to the Elixir/Phoenix ecosystem.

---

## 1. Pruning Strategy: `Parapet.Evidence.Archiver`

**Goal:** Prevent table bloat over time (>100k rows) while honoring enterprise compliance needs where required.

### Recommendation: Hard Deletion with Optional Export Callback
In the Elixir ecosystem (similar to Oban's pruning or Logger's rotation), time-based **Hard Deletion** is the idiomatic standard for operational data. Adding `deleted_at` (soft deletes) fails the primary goal of keeping the database lean and introduces significant schema/query complexity.

*   **Approach:** 
    *   Introduce a mix task (`mix parapet.archive`) and an Oban cron worker template (`Parapet.Evidence.Archiver`).
    *   By default, it will perform a batch hard-delete of `Incident` records (and cascading to `TimelineEntry`/`ToolAudit`) where `state == "resolved"` and `updated_at < threshold` (e.g., 90 days).
    *   **Export Hook:** Define a `Parapet.Evidence.Archiver` behaviour. Before deleting, the archiver passes the batch of records to an optional, user-configured module. This allows enterprise host applications to export the records to S3, a data warehouse, or local disk without forcing Parapet to depend on `ex_aws_s3` or other heavy storage libraries.
*   **Tradeoffs:**
    *   *Pros:* Keeps Ecto tables extremely fast, requires no changes to existing complex queries, zero external dependencies, highly idiomatic.
    *   *Cons:* Default is permanent data loss, requiring users to explicitly implement the export callback if compliance dictates long-term retention.
*   **UI/UX impact:** Keeps the Operator UI lightning fast by ensuring the working set of data is always bounded.

## 2. Composite Indexing for Scale

**Goal:** Ensure fast query performance for evidence tables as they approach 100k+ rows.

### Recommendation: Targeted B-Tree Indexes
Based on how the Operator UI and Archiver will access data, the following composite indexes must be added:

1.  **`parapet_incidents`**
    *   `CREATE INDEX ... ON parapet_incidents (state, inserted_at)`
    *   *Rationale:* The Operator UI primarily queries `WHERE state = 'open' ORDER BY inserted_at DESC`. The Archiver primarily queries `WHERE state = 'resolved' AND updated_at < ?`. This index explicitly covers both paths perfectly.
2.  **`parapet_timeline_entries`**
    *   `CREATE INDEX ... ON parapet_timeline_entries (incident_id, inserted_at)`
    *   *Rationale:* The UI loads timelines per-incident, strictly chronologically. The current index `[:incident_id]` is insufficient for massive timelines; adding `inserted_at` avoids in-memory sorts and speeds up cursor pagination.
3.  **`parapet_tool_audits`**
    *   *Verdict:* Keep the existing `[:timeline_entry_id]` index. Audits are always fetched via their parent timeline entry; no complex filtering occurs across the entire table.

## 3. Migration and DX (Developer Experience) Strategy

**Goal:** Seamlessly upgrade existing users without breaking new installs.

### Recommendation: `mix parapet.gen.archive`
*   **Approach:** Create a dedicated Igniter task, `mix parapet.gen.archive`.
    *   **For the DB:** It generates a new Ecto migration containing the `CREATE INDEX` commands above. (It does *not* modify the original `parapet.gen.spine` migration, adhering to Ecto's append-only migration philosophy for existing users, while we can safely update `parapet.gen.spine` for *new* users).
    *   **For the App:** It injects the Oban cron worker into the host application's `config.exs` under the `Oban` `:plugins` configuration (if Oban is present).
*   **Tradeoffs:**
    *   *Pros:* Principle of least surprise. Users run the generator, apply the migration, and the cron job is wired up automatically.
    *   *Cons:* Requires the user to explicitly run `mix parapet.gen.archive` to get the performance benefits. We should add a check in `mix parapet.doctor` to warn users if the indexes are missing.

---
**Conclusion:** This architecture completely resolves the database scale gray areas. It respects the solo founder's time (out-of-the-box cron generation), respects system boundaries (no bloated AWS deps), and sets the foundation for Phase 3's cursor pagination in the Operator UI.