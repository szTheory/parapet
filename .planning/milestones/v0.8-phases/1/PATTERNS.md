# Phase 1: Durable Escalation Engine - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/escalation/policy.ex` | behaviour | contract/interface | `lib/parapet/notifier.ex` | exact |
| `lib/parapet/escalation/worker.ex` | worker | event-driven | `lib/parapet/notifier/oban_worker.ex` | exact |
| `lib/parapet/evidence.ex` | context | CRUD / transaction | `lib/parapet/evidence.ex` | exact |

## Pattern Assignments

### `lib/parapet/escalation/policy.ex` (behaviour, contract/interface)

**Analog:** `lib/parapet/notifier.ex`

**Behaviour Definition Pattern** (lines 1-5):
```elixir
defmodule Parapet.Notifier do
  @moduledoc """
  Behaviour for incident notification adapters.
  """
  @callback deliver(incident :: struct(), opts :: keyword()) :: {:ok, term()} | {:error, term()}
```

**Dispatch Logic Pattern** (lines 7-15):
```elixir
  def broadcast(incident) do
    notifiers = Application.get_env(:parapet, :notifiers, [])

    Enum.each(notifiers, fn {adapter, opts} ->
      dispatch(incident, adapter, opts)
    end)

    :ok
  end
```

---

### `lib/parapet/escalation/worker.ex` (worker, event-driven)

**Analog:** `lib/parapet/notifier/oban_worker.ex`

**Worker Module Definition Pattern** (lines 1-6):
```elixir
defmodule Parapet.Notifier.ObanWorker do
  @moduledoc """
  Oban worker for durable asynchronous dispatch of notifications.
  """
  use Oban.Worker, queue: :default
```

**Perform Logic and Entity Fetching Pattern** (lines 8-15):
```elixir
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id, "adapter" => adapter_str}}) do
    adapter = String.to_existing_atom(adapter_str)

    # We must fetch the incident to pass it to the adapter.
    incident = Parapet.Evidence.repo().get(Parapet.Spine.Incident, incident_id)

    if incident do
```

**Short-circuit Pattern** (lines 25-28):
```elixir
    else
      # If incident is not found, we shouldn't retry.
      {:discard, "Incident #{incident_id} not found."}
    end
```

---

### `lib/parapet/evidence.ex` (context, CRUD / transaction)

**Analog:** `lib/parapet/evidence.ex`

**Ecto.Multi Transaction Pattern** (lines 80-92):
This pattern will be useful for integrating Oban worker scheduling within the existing Ecto Multi when an incident is created.
```elixir
  def run_operator_command(opts) do
    incident_changeset = Keyword.fetch!(opts, :incident_changeset)
    timeline_attrs = Keyword.fetch!(opts, :timeline_attrs)
    audit_attrs = Keyword.fetch!(opts, :audit_attrs)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:incident, incident_changeset)
      |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} ->
        %TimelineEntry{}
        |> TimelineEntry.changeset(Map.put(timeline_attrs, :incident_id, incident.id))
      end)
```

**Timeline Entry Emission Pattern** (lines 53-58):
```elixir
  def append_timeline(incident_id, attrs \\ %{}) do
    %TimelineEntry{}
    |> TimelineEntry.changeset(Map.put(attrs, :incident_id, incident_id))
    |> repo().insert()
  end
```

## Shared Patterns

### Error Handling / Safe Execution
**Source:** `lib/parapet/notifier.ex`
**Apply to:** `Parapet.Escalation.Worker` or the policy execution logic to wrap behaviour execution safely.
```elixir
    {status, details} =
      try do
        case adapter.deliver(incident, opts) do
          {:ok, result} -> {"success", inspect(result)}
          {:error, reason} -> {"error", inspect(reason)}
          other -> {"error", inspect(other)}
        end
      rescue
        e -> {"error", inspect(e)}
      catch
        type, value -> {"error", "#{type}: #{inspect(value)}"}
      end
```

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`
**Files scanned:** 64
**Pattern extraction date:** 2024-05-24
