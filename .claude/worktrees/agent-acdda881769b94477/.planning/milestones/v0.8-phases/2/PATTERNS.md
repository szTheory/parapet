# Phase 2: Bounded Runbook Execution - Pattern Map

**Mapped:** 2026-05-18
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/runbook.ex` | config | configuration | `lib/parapet/runbook.ex` | exact |
| `lib/parapet/automation/executor.ex` | background worker | event-driven | `lib/parapet/escalation/worker.ex` | role-match |
| `lib/parapet/spine/alert_processor.ex` | service | event-driven | `lib/parapet/spine/alert_processor.ex` | exact |

## Pattern Assignments

### `lib/parapet/runbook.ex` (config, configuration)

**Analog:** `lib/parapet/runbook.ex`

**DSL pattern** (lines 19-33):
```elixir
  defmacro step(id, opts) do
    quote do
      @steps %{
        id: unquote(id),
        # ... existing fields ...
        requires_preview: Keyword.get(unquote(opts), :requires_preview, false),
        preview_only: Keyword.get(unquote(opts), :preview_only, false),
        auto_execute: Keyword.get(unquote(opts), :auto_execute, false), # Target addition
        guidance: unquote(opts)[:guidance]
      }
    end
  end
```

---

### `lib/parapet/automation/executor.ex` (background worker, event-driven)

**Analog:** `lib/parapet/escalation/worker.ex`

**Oban worker pattern** (lines 1-13):
```elixir
defmodule Parapet.Escalation.Worker do
  @moduledoc """
  Oban worker for durable asynchronous dispatch of escalations.
  """
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id}}) do
    incident = Parapet.Evidence.repo().get(Parapet.Spine.Incident, incident_id)

    case incident do
      nil ->
        {:discard, "Incident #{incident_id} not found"}
# ...
```

**Executor action and logging pattern** (adapted from `Parapet.Operator` and Oban Worker patterns):
```elixir
# Instead of execute_policy, the executor will construct an ActionPayload
# and call `Parapet.Operator.execute_runbook_step/3` to leverage existing unified auditing.
payload = %Parapet.Operator.ActionPayload{
  actor: "system:automation:executor",
  reason: "Auto-executed by Parapet runbook step #{step_id}",
  correlation_id: incident.correlation_key,
  action_type: :execute_mitigation,
  idempotency_key: "auto_exec_#{incident.id}_#{step_id}"
}

Parapet.Operator.execute_runbook_step(incident, step_id, payload)
```

---

### `lib/parapet/spine/alert_processor.ex` (service, event-driven)

**Analog:** `lib/parapet/spine/alert_processor.ex`

**Transaction Pattern / Job Enqueueing** (lines 53-62):
```elixir
    multi =
      Ecto.Multi.new()
      |> put_incident(existing_incident, incident_changeset)
      |> maybe_insert_triage_snapshot(snapshot_required?, triage_snapshot)
      # Target addition:
      # |> maybe_enqueue_automation(runbook_data)
      |> Ecto.Multi.run(:broadcast, fn _repo, %{incident: incident} ->
        Parapet.Notifier.broadcast(incident)
        {:ok, incident}
      end)
```

**Checking for auto_execute**:
```elixir
# The router should scan `runbook_data.steps` for `auto_execute: true`
# and enqueue Oban jobs specifically for those steps using `Ecto.Multi.insert` similar
# to how `Parapet.Evidence.maybe_enqueue_escalation/1` does it.
```

## Shared Patterns

### Automation Identity Logging
**Source:** `lib/parapet/operator.ex`
**Apply to:** `Parapet.Automation.Executor`

The `ToolAudit` and `TimelineEntry` records are correctly generated securely via `Parapet.Operator` API endpoints as long as an `ActionPayload` struct with `actor: "system:automation:executor"` is passed. No direct database inserts should happen in the Executor for these logs.

```elixir
payload = %Parapet.Operator.ActionPayload{
  actor: "system:automation:executor",
  reason: "Auto-executed by Parapet runbook step #{step_id}",
  correlation_id: incident.correlation_key,
  action_type: :execute_mitigation,
  idempotency_key: "auto_exec_#{incident.id}_#{step_id}"
}
Parapet.Operator.execute_runbook_step(incident, step_id, payload)
```

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`
**Files scanned:** 4
**Pattern extraction date:** 2026-05-18