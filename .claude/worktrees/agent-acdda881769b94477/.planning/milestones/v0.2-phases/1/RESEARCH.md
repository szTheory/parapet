# Phase 1: Durable Evidence Spine (Ecto) - Research

**Researched:** 2024-05-11
**Domain:** Elixir Ecto Schemas, Igniter Code Generation, Database Persistence
**Confidence:** HIGH

## Summary

The Durable Evidence Spine requires injecting Ecto schemas (`Incident`, `TimelineEntry`, `ToolAudit`) and their corresponding migrations into the host application. Instead of Parapet bringing its own Ecto Repo and connecting to the database directly, it will define `Ecto.Schema` structs and utilize the host application's Ecto Repo.

**Primary recommendation:** Use `Igniter.Libs.Ecto.gen_migration/4` in a new `mix parapet.gen.spine` task to drop the necessary migration file into the host app, and configure `:parapet, :repo` in `config.exs` so Parapet knows which repository to use for API calls.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPINE-01 | Ecto schemas for Incidents with state machine. | Use Ecto.Schema mapping to `parapet_incidents` table. |
| SPINE-02 | Ecto schemas for Timeline Entries linked to Incidents. | Use `has_many` / `belongs_to` with `parapet_timeline_entries` table. |
| SPINE-03 | Ecto schemas for Tool Audits to log AI/MCP calls. | Use `Ecto.Schema` mapping to `parapet_tool_audits` table with `:map` fields for JSON payloads. |
| SPINE-04 | Enforce clear boundary preventing raw telemetry in Ecto. | Exposed via explicit `Parapet.Evidence` context module calls, never auto-hooked to high-volume telemetry events. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Incident State | Database (Postgres/SQLite) | API/Backend (Elixir) | Requires durable storage of open/investigating/resolved states. |
| Timeline Events | Database (Postgres/SQLite) | API/Backend (Elixir) | Append-only audit logs must survive restarts. |
| Tool Audit Log | Database (Postgres/SQLite) | API/Backend (Elixir) | Durable, queryable records of LLM/Operator mutations are necessary for security. |
| Telemetry Separation | API/Backend (Elixir) | — | Boundary must be enforced in code so high-volume time-series never hits Ecto. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | ~> 3.10 | Database migrations and Ecto types. | The standard Elixir relational database interface. |
| `ecto` | ~> 3.10 | Data validation, mapping, changesets. | Standard for building data boundaries in Elixir. |
| `igniter` | ~> 0.7 | Scaffolding and patching configuration. | Built into Parapet's existing installation path for DX. |
| `jason` | ~> 1.4 | JSON encoding for structured fields. | Native Ecto support for `:map` types in Postgres/SQLite. |

**Installation:**
```bash
mix deps.get
```

## Architecture Patterns

### Recommended Project Structure
```
lib/parapet/
├── spine/                  # Core Evidence Spine Context
│   ├── incident.ex         # Ecto schema for parapet_incidents
│   ├── timeline_entry.ex   # Ecto schema for parapet_timeline_entries
│   └── tool_audit.ex       # Ecto schema for parapet_tool_audits
└── evidence.ex             # Public API boundary (create_incident, append_timeline)
lib/mix/tasks/
└── parapet.gen.spine.ex    # Igniter task to install the schema migrations
```

### Pattern 1: Agnostic Repo Injection
**What:** Parapet schemas should not hardcode the application's Ecto Repo.
**When to use:** When distributing Ecto schemas in a shared library to host applications.
**Example:**
```elixir
# lib/parapet/evidence.ex
defmodule Parapet.Evidence do
  def repo do
    Application.fetch_env!(:parapet, :repo)
  end

  def create_incident(attrs) do
    %Parapet.Spine.Incident{}
    |> Parapet.Spine.Incident.changeset(attrs)
    |> repo().insert()
  end
end
```

### Pattern 2: Igniter Migration Generation
**What:** Use Igniter's built-in Ecto library to generate the timestamped migration file.
**When to use:** For providing the database tables to the host application.
**Example:**
```elixir
# lib/mix/tasks/parapet.gen.spine.ex
defmodule Mix.Tasks.Parapet.Gen.Spine do
  use Igniter.Mix.Task

  def igniter(igniter) do
    # Assuming the app has exactly one Repo, or list_repos(igniter) |> List.first()
    [repo | _] = Igniter.Libs.Ecto.list_repos(igniter)
    
    migration_body = """
      def change do
        create table(:parapet_incidents, primary_key: false) do
          add :id, :binary_id, primary_key: true
          add :state, :string, default: "open", null: false
          add :title, :string, null: false
          add :description, :text
          timestamps(type: :utc_datetime)
        end
        # ... more tables
      end
    """

    igniter
    |> Igniter.Libs.Ecto.gen_migration(repo, "add_parapet_evidence_spine", body: migration_body)
    |> Igniter.Project.Config.configure("config.exs", :parapet, [:repo], repo)
  end
end
```

### Anti-Patterns to Avoid
- **Coupling telemetry directly to Ecto:** Do not use `telemetry.attach` to listen for events like `[:phoenix, :endpoint, :stop]` and write an Ecto record. This will exhaust database connection pools immediately. Telemetry remains fast and ephemeral; Evidence is explicit and durable.
- **Hardcoding binary keys over integer IDs:** Ecto defaults to integers. We must explicitly define `:binary_id` (UUIDs) for Parapet records to prevent ID enumeration and merge conflicts if syncing logs across environments.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File creation | Custom `File.write` / regex timestamps | `Igniter.Libs.Ecto.gen_migration/4` | Handles timestamps correctly, prevents duplicate filenames, integrates with `mix igniter`. |
| Modifying `config.exs` | Regex or AST parsing | `Igniter.Project.Config.configure` | Ensures AST-safe modifications to the host application's config files without corrupting syntax. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None | Verified by source audit. This phase builds greenfield schemas; no existing data needs migration. |
| Live service config | None | N/A |
| OS-registered state | None | N/A |
| Secrets/env vars | None | N/A |
| Build artifacts | None | N/A |

## Common Pitfalls

### Pitfall 1: Missing Repo Configuration Fallback
**What goes wrong:** Parapet crashes when calling `Parapet.Evidence.repo/0` if the user didn't run the installer or configure the repo.
**Why it happens:** Missing config fallback handling.
**How to avoid:** Ensure the `Mix.Tasks.Parapet.Gen.Spine` patches `config.exs` to set `config :parapet, repo: MyApp.Repo`.

### Pitfall 2: Conflicting Table Names
**What goes wrong:** The migration fails because a host app already has a table called `incidents`.
**Why it happens:** Global database namespace.
**How to avoid:** Prefix all table names with `parapet_` (e.g., `parapet_incidents`, `parapet_timeline_entries`, `parapet_tool_audits`).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Mix (Elixir) | Core execution | ✓ | ~> 1.19 | — |
| Ecto SQL | Migrations | ✓ | ~> 3.10 | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test --stale` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPINE-01 | Schemas are valid and can be loaded. | unit | `mix test test/parapet/spine/incident_test.exs` | ❌ Wave 0 |
| SPINE-02 | Timeline schemas load correctly. | unit | `mix test test/parapet/spine/timeline_entry_test.exs` | ❌ Wave 0 |
| SPINE-03 | Tool Audit schemas validate payload. | unit | `mix test test/parapet/spine/tool_audit_test.exs` | ❌ Wave 0 |
| SPINE-04 | Generator task outputs valid config/migrations. | unit | `mix test test/mix/tasks/parapet.gen.spine_test.exs` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/parapet/spine/incident_test.exs`
- [ ] `test/parapet/spine/timeline_entry_test.exs`
- [ ] `test/parapet/spine/tool_audit_test.exs`
- [ ] `test/mix/tasks/parapet.gen.spine_test.exs`
- [ ] Setup `Ecto` sandbox in tests if executing schemas directly, or test functionally without real DB insert if preferred for library scope.

## Sources

### Primary (HIGH confidence)
- Local Code Inspection: Validated `Igniter.Libs.Ecto` availability in the environment and its capabilities.
- Local Database Inspection: `lib/parapet/metrics/ecto.ex` verified, telemetry boundary analyzed.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `ecto_sql` and `igniter` are canonical.
- Architecture: HIGH - the schema-without-repo abstraction is heavily used in libraries like Oban.
- Pitfalls: HIGH - derived from common Ecto namespace collision issues.

**Research date:** 2024-05-11
**Valid until:** 2025-05-11