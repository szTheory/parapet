# Phase 2: Database Scale & Pruning - Research

**Researched:** 2024-05-20
**Domain:** Database, Ecto migrations, Data Archival
**Confidence:** HIGH

## Summary

Phase 2 ensures the `parapet_incidents`, `parapet_timeline_entries`, and `parapet_tool_audits` tables scale effectively over time without overwhelming the host database. The strategy employs an **Export + Hard Delete** archival approach using JSONL, preventing database bloat without relying on soft deletes. To achieve this safely, we transition the `parapet_tool_audits` foreign key to `on_delete: :delete_all` to enable PostgreSQL to handle cascading deletes synchronously.

Additionally, we add composite indexes (`[:state, :inserted_at]` and `[:<parent>_id, :inserted_at]`) to avoid full table scans during UI reads and archival sweeps. Both a conditionally compiled Oban worker and a standard Mix task will be provided for scheduling flexibility.

**Primary recommendation:** Implement chunked processing using `Ecto.Repo.stream/2` combined with `Stream.chunk_every/2` in a single un-nested transaction. Write the serialized JSONL payload to a file, and immediately execute a chunk-based `Repo.delete_all/2` to safely trigger the database-level cascading deletes.

<user_constraints>
## User Constraints (from ASSUMPTIONS.md)

### Locked Decisions
- Export & Hard Delete over Soft Delete to protect host DB.
- `parapet_tool_audits` constraint altered to `on_delete: :delete_all`.
- Composite indexes on `[:state, :inserted_at]`, `[:incident_id, :inserted_at]`, and `[:timeline_entry_id, :inserted_at]`.
- Archiver uses `Ecto.Repo.stream/2` and outputs JSON Lines (JSONL).
- Upgrade migration generator `mix parapet.gen.archive_indexes` required for existing users (via Igniter).
- `mix parapet.gen.spine` template updated for new users.

### The Agent's Discretion
- Chunk size and stream iteration strategy for the archiver.
- Implementation details of `mix parapet.archive` and conditional compilation of `Parapet.Evidence.ArchiveWorker`.

### Deferred Ideas (OUT OF SCOPE)
- Soft deletes.
- Other export formats (e.g., CSV, Parquet).
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Archival Logic | API / Backend (Archiver) | Database | Elixir chunking with `File.stream!`; Database handles cascading deletes. |
| Background Scheduling | Oban Worker | OS Cron (Mix task) | Oban handles distributed execution; Mix task handles simple single-node environments. |
| Migrations | Database | Igniter / CLI | Igniter generates standard Ecto migrations strictly applied to the user's local DB. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ecto | ~> 3.10 | Database querying and migrations | Core Elixir DB layer, handles `stream/2` and `delete_all` natively. |
| Jason | ~> 1.4 | JSON serialization | Ubiquitous standard for writing to JSONL formats. |
| Igniter | ~> 0.7 | Code generation | Safe AST-based parsing and migration generation. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Oban | optional | Cron scheduling | When the host application uses Oban for robust background jobs. |

## Architecture Patterns

### Recommended Project Structure
```text
lib/parapet/
├── evidence/
│   ├── archiver.ex       # JSONL stream and cascading delete logic
│   └── archive_worker.ex # Conditionally compiled Oban worker
lib/mix/tasks/
├── parapet.archive.ex    # CLI interface for OS cron
├── parapet.gen.archive_indexes.ex # Igniter upgrade generator for existing users
└── parapet.gen.spine.ex  # (Updated) Initial installation generator
```

### Pattern 1: Conditionally Compiled Oban Worker
**What:** Exposing an Oban worker only if the host application possesses the dependency.
**When to use:** Integrating optional background job libraries without forcing the dependency onto users who rely on basic OS cron.
**Example:**
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Evidence.ArchiveWorker do
    use Oban.Worker, queue: :default, max_attempts: 3
    
    @impl Oban.Worker
    def perform(%Oban.Job{args: args}) do
      # Run archiver logic
      :ok
    end
  end
end
```

### Pattern 2: Chunked Stream + Hard Delete
**What:** Streaming incidents, preloading dependencies, formatting them, and deleting them in chunks to avoid massive lock accumulation and memory bloat.
**When to use:** Batch archiving of large datasets reliably.
**Example:**
```elixir
Repo.transaction(fn ->
  query
  |> Repo.stream(max_rows: 500)
  |> Stream.chunk_every(100)
  |> Enum.each(fn incident_chunk ->
    # 1. Preload nested associations cleanly via the chunked structs
    full_incidents = Repo.preload(incident_chunk, [timeline_entries: :tool_audits])
    
    # 2. Write to file
    jsonl = Enum.map(full_incidents, &format_as_jsonl/1) |> Enum.join("\n")
    File.write!(path, jsonl <> "\n", [:append, :utf8])
    
    # 3. Hard delete using chunk IDs, relying on DB-level CASCADE (on_delete: :delete_all)
    ids = Enum.map(incident_chunk, & &1.id)
    Repo.delete_all(from i in Incident, where: i.id in ^ids)
  end)
end, timeout: :infinity)
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pagination for Archiving | `offset`/`limit` loops | `Ecto.Repo.stream/2` | `offset` suffers from extreme performance degradation on large tables; `stream` uses cursor-based DB chunks. |
| Cascading Deletes in Code | Iterative `Repo.delete_all` for child records | DB `ON DELETE CASCADE` | Let PostgreSQL handle referential integrity and synchronized deletion via the `on_delete: :delete_all` constraint. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Host Ecto DB references (`parapet_tool_audits` constraint) | Code edit + schema alteration via `mix parapet.gen.archive_indexes`. |
| Live service config | None | None |
| OS-registered state | None | None |
| Secrets/env vars | None | None |
| Build artifacts | None | None |

## Common Pitfalls

### Pitfall 1: Streaming without a Transaction
**What goes wrong:** `Ecto.Repo.stream/2` fails instantly with a "must be inside a transaction" error (in PostgreSQL).
**Why it happens:** PostgreSQL cursors only live within a transaction boundary.
**How to avoid:** Always wrap the stream execution inside `Repo.transaction(fn -> ... end)`.

### Pitfall 2: Reversing `drop constraint` in `change/0`
**What goes wrong:** Ecto cannot automatically infer how to reverse an explicit `drop constraint` in a `def change` block.
**Why it happens:** The `down` direction requires the full definition of the previous constraint, which Ecto doesn't store.
**How to avoid:** Use explicit `def up` and `def down` blocks in the `mix parapet.gen.archive_indexes` migration instead of a unified `change/0`.

## Code Examples

### Ecto Migration: Dropping and Replacing a Constraint Safely
```elixir
def up do
  drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey")
  alter table(:parapet_tool_audits) do
    modify :timeline_entry_id, references(:parapet_timeline_entries, type: :binary_id, on_delete: :delete_all)
  end
end

def down do
  drop constraint(:parapet_tool_audits, "parapet_tool_audits_timeline_entry_id_fkey")
  alter table(:parapet_tool_audits) do
    modify :timeline_entry_id, references(:parapet_timeline_entries, type: :binary_id, on_delete: :nilify_all)
  end
end
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REQ-01 | Generates correct migration for upgrade | unit | `mix test test/mix/tasks/parapet.gen.archive_indexes_test.exs` | ❌ Wave 0 |
| REQ-02 | Spine correctly includes composite indexes | unit | `mix test test/mix/tasks/parapet.gen.spine_test.exs` | ✅ Wave 0 (needs update) |
| REQ-03 | Archiver formats JSONL and cascades deletes | integration | `mix test test/parapet/evidence/archiver_test.exs` | ❌ Wave 0 |
| REQ-04 | Mix task triggers archiver | unit | `mix test test/mix/tasks/parapet.archive_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/evidence/archiver_test.exs`
- [ ] `test/mix/tasks/parapet.gen.archive_indexes_test.exs`
- [ ] `test/mix/tasks/parapet.archive_test.exs`
- [ ] `test/parapet/evidence/archive_worker_test.exs`

## Sources

### Primary (HIGH confidence)
- `ASSUMPTIONS.md` (Local project directives regarding Export + Hard Delete)
- `lib/mix/tasks/parapet.gen.spine.ex` (Current baseline Ecto schemas)
- Ecto Documentation (`Ecto.Repo.stream/2`, `Ecto.Migration`).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Ecto + File Streams represent perfectly idiomatic Elixir.
- Architecture: HIGH - Offloading cascading deletion constraints directly to the DB eliminates locking risks and complex multi-repo deletion commands.
- Pitfalls: HIGH - PostgreSQL strictness around stream cursors and migrations is thoroughly verified.
