# Phase 3: Notifications & Escalation - Pattern Map

**Mapped:** 2024-05-18
**Files analyzed:** 4
**Analogs found:** 2 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/notifier.ex` | behaviour | event-driven | `lib/parapet/plug/webhook.ex` (Plug behaviour) | role-match |
| `lib/parapet/notifiers/slack.ex` | adapter | external API | N/A | none |
| `lib/parapet/notifiers/teams.ex` | adapter | external API | N/A | none |
| `lib/parapet/spine/alert_processor.ex` | service | request-response | `lib/parapet/spine/alert_processor.ex` | exact |

## Pattern Assignments

### `lib/parapet/notifier.ex` (behaviour, event-driven)

**Analog:** Built-in Elixir `@behaviour` / `@callback` pattern (project usage seen in standard library plugs like `lib/parapet/plug/webhook.ex`)

**Core pattern**:
```elixir
defmodule Parapet.Notifier do
  @moduledoc """
  Defines the behaviour for broadcasting incident state changes to external systems.
  """
  
  @callback notify(incident :: Parapet.Spine.Incident.t(), action :: atom(), payload :: map()) :: :ok | {:error, term()}
end
```

### `lib/parapet/spine/alert_processor.ex` (service, request-response)

**Analog:** `lib/parapet/spine/alert_processor.ex`

**Core Ecto.Multi Timeline Entry pattern** (lines 87-101):
```elixir
        timeline_entry_changeset = TimelineEntry.changeset(%TimelineEntry{}, %{
          type: "auto_resolved",
          payload: alert,
          incident_id: incident.id
        })
        
        multi =
          Ecto.Multi.new()
          |> Ecto.Multi.update(:incident, incident_changeset)
          |> Ecto.Multi.insert(:timeline_entry, timeline_entry_changeset)
          
        repo.transaction(multi)
```

**Observation:** The timeline recording logic for notifications should follow this `Ecto.Multi` approach or manually insert after the fact to log `notification_dispatched`.

---

## Shared Patterns

### Durable Audit Trails (Timeline Entries)
**Source:** `lib/parapet/spine/timeline_entry.ex`
**Apply to:** Recording notification dispatches
```elixir
TimelineEntry.changeset(%TimelineEntry{}, %{
  type: "notification_dispatched",
  payload: %{
    adapter: "slack",
    status: "success",
    channel: "#incidents",
    ts: "123456789.0"
  },
  incident_id: incident.id
})
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/notifiers/slack.ex` | adapter | external API | The codebase currently lacks outgoing HTTP adapters. The planner should introduce a standard HTTP client library like `Req` or use Erlang's `:httpc` for external API requests to Slack. |
| `lib/parapet/notifiers/teams.ex` | adapter | external API | Same as above. No existing HTTP outbound integration pattern. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`
**Files scanned:** 39
**Pattern extraction date:** 2024-05-18