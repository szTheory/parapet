# Phase 2: Database Scale & Pruning - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/parapet.gen.spine.ex` (Migration updates) | generator/migration | schema | `lib/mix/tasks/parapet.gen.spine.ex` | exact |
| `lib/mix/tasks/parapet.archive.ex` | utility | batch, file-I/O | `lib/mix/tasks/parapet.doctor.ex` | role-match |
| `lib/parapet/archive/oban_worker.ex` | service | event-driven | `lib/parapet/probe/oban_scheduler.ex` | exact |

## Pattern Assignments

### `lib/mix/tasks/parapet.gen.spine.ex` (generator/migration)

**Analog:** `lib/mix/tasks/parapet.gen.spine.ex`

**Composite Index & Foreign Key pattern** (lines 35-42):
```elixir
          create unique_index(:parapet_incidents, [:correlation_key], where: "state = 'open'")

          create table(:parapet_timeline_entries, primary_key: false) do
            add :id, :binary_id, primary_key: true
            add :type, :string, null: false
            add :payload, :map, default: %{}
            add :incident_id, references(:parapet_incidents, type: :binary_id, on_delete: :delete_all), null: false

            timestamps()
          end

          create index(:parapet_timeline_entries, [:incident_id])
```

---

### `lib/mix/tasks/parapet.archive.ex` (utility, batch, file-I/O)

**Analog:** `lib/mix/tasks/parapet.doctor.ex`

**Mix Task execution pattern** (lines 20-22, 70-73):
```elixir
  @impl Mix.Task
  def run(args) do
    {opts, checks, _} = OptionParser.parse(args, switches: [ci: :boolean])
    
    # ... logic ...
    
    if exit_code > 0, do: halt(exit_code)
    :ok
  end
```

**JSON Output Pattern** (lines 250-259):
```elixir
  defp print_json(results, exit_code) do
    output = %{
      exit_code: exit_code,
      checks: results
    }

    if Code.ensure_loaded?(Jason) do
      Mix.shell().info(Jason.encode!(output))
    else
      Mix.shell().info(inspect(output))
    end
  end
```

---

### `lib/parapet/archive/oban_worker.ex` (service, event-driven)

**Analog:** `lib/parapet/probe/oban_scheduler.ex`

**Optional Dependency (Conditional Compilation) & Oban Worker Pattern** (lines 1-15):
```elixir
defmodule Parapet.Probe.ObanScheduler do
  if Code.ensure_loaded?(Oban) do
    @moduledoc """
    Oban worker for scheduling synthetic probes without retries.
    """
    use Oban.Worker, max_attempts: 1

    @impl Oban.Worker
    def perform(%Oban.Job{args: %{"probe" => probe_str}}) do
      with {:ok, module} <- resolve_probe(probe_str),
           true <- probe_valid?(module) do
        apply(module, :execute, [])
      else
        _ -> {:error, :invalid_probe}
      end
    end
```

## Shared Patterns

### Conditional Compilation for Optional Dependencies
**Source:** `lib/parapet/probe/oban_scheduler.ex`
**Apply to:** Any files relying on `:oban` or `:jason` (since they are optional/host dependencies).
```elixir
  if Code.ensure_loaded?(Oban) do
    # Implementation relying on Oban
  end
```

## No Analog Found

| File / Feature | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Archival Export (JSONL/File I/O) & Ecto Repo Streaming | utility / db | batch, stream | No existing code streams from the Repo (`Repo.stream`) to export to a file. Planner should use standard Elixir `Stream` and `Ecto.Repo.stream` best practices from RESEARCH.md instead. |

## Metadata

**Analog search scope:** `lib/mix/tasks/*`, `priv/repo/migrations/*`, `lib/parapet/probe/*`
**Files scanned:** 6
**Pattern extraction date:** 2024-05-18
