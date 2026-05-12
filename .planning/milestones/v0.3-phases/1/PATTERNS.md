# Phase 1: Alert Routing & Reception - Pattern Map

**Mapped:** $(date -u +"%Y-%m-%d")
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/alertmanager/webhook_plug.ex` | plug | request-response | `lib/parapet/plug/metrics.ex` | exact |
| `lib/parapet/alertmanager/receiver.ex` | service | event-driven | `lib/parapet/operator.ex` | role-match |
| `lib/parapet/spine/incident.ex` | model | CRUD | `lib/parapet/spine/timeline_entry.ex` | role-match |
| `test/parapet/alertmanager/webhook_plug_test.exs` | test | request-response | `test/parapet/plug/metrics_test.exs` | exact |
| `test/parapet/alertmanager/receiver_test.exs` | test | event-driven | `test/parapet/operator_test.exs` | role-match |

## Pattern Assignments

### `lib/parapet/alertmanager/webhook_plug.ex` (plug, request-response)

**Analog:** `lib/parapet/plug/metrics.ex`

**Imports pattern** (lines 4-8):
```elixir
  @behaviour Plug

  import Plug.Conn

  alias Parapet.Internal.LabelPolicy
```

**Core Plug pattern** (lines 10-13):
```elixir
  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
```

**Request-Response pattern** (lines 33-34):
```elixir
      conn
    end)
```
*Note: Since it's a webhook receiver, we'll read `conn.body_params` or parse the request and return a standard `200 OK` using `Plug.Conn.send_resp/3` rather than `register_before_send`.*

---

### `lib/parapet/alertmanager/receiver.ex` (service, event-driven)

**Analog:** `lib/parapet/operator.ex` and `lib/parapet/evidence.ex`

**Service boundary pattern** (lines 1-8 of `lib/parapet/operator.ex`):
```elixir
defmodule Parapet.Operator do
  @moduledoc """
  Phoenix-free public boundary for the in-app Operator UI.
  ...
  """
  import Ecto.Query
  alias Parapet.Spine.Incident
  alias Parapet.Evidence
```

**Transactional/Event logic pattern** (lines 42-63 of `lib/parapet/operator.ex`):
```elixir
  def mark_investigating(%Incident{} = incident, %ActionPayload{} = payload) do
    if valid_payload?(payload) do
      incident_changeset = Ecto.Changeset.change(incident, %{state: "investigating"})
      
      timeline_attrs = %{
        type: "status_change",
        payload: %{"new_state" => "investigating"}
      }
      
      audit_attrs = build_audit("operator_mark_investigating", payload)
      
      Evidence.run_operator_command(
        incident_changeset: incident_changeset,
        timeline_attrs: timeline_attrs,
        audit_attrs: audit_attrs
      )
    else
      {:error, :invalid_payload}
    end
  end
```
*Note: For the receiver, the pattern will be parsing the payload, identifying the correlation hash/ID, querying `Parapet.Evidence.repo().get_by(Incident, ...)` and emitting a Multi transaction to `Evidence.run_operator_command` or similar to handle state updates based on "firing" or "resolved".*

---

### `lib/parapet/spine/incident.ex` (model, CRUD)

**Analog:** `lib/parapet/spine/timeline_entry.ex` (for extending payload mapping)

**Field schema mapping pattern** (lines 11-16 of `lib/parapet/spine/timeline_entry.ex`):
```elixir
  schema "parapet_timeline_entries" do
    field :type, :string
    field :payload, :map

    belongs_to :incident, Incident, type: :binary_id

    timestamps(type: :utc_datetime_usec)
  end
```
*Note: In `incident.ex`, we need to add a `correlation_hash` or `labels` (map) field to store the identity of the Alertmanager alert, tracking duplicate occurrences correctly. Currently, `incident.ex` contains `:title, :description, :state`.*

**Validation pattern** (lines 19-24 of `lib/parapet/spine/timeline_entry.ex`):
```elixir
  @doc false
  def changeset(timeline_entry, attrs) do
    timeline_entry
    |> cast(attrs, [:type, :payload, :incident_id])
    |> validate_required([:type, :incident_id])
  end
```

---

### `test/parapet/alertmanager/webhook_plug_test.exs` (test, request-response)

**Analog:** `test/parapet/plug/metrics_test.exs`

**Imports and Setup pattern** (lines 1-7):
```elixir
defmodule Parapet.Plug.MetricsTest do
  use ExUnit.Case, async: false
  import Plug.Test
  import Plug.Conn

  alias Parapet.Plug.Metrics
```

**Routing/Plug mock execution pattern** (lines 19-24):
```elixir
    _conn =
      conn(:get, "/users/1")
      |> put_private(:phoenix_route, "/users/:id")
      |> Metrics.call(Metrics.init([]))
      |> send_resp(200, "ok")
```

## Shared Patterns

### Error Handling
**Source:** `lib/parapet/operator.ex`
**Apply to:** Receiver Service
```elixir
    else
      {:error, :invalid_payload}
    end
```

### Transactional Audit/Timeline Boundary
**Source:** `lib/parapet/evidence.ex`
**Apply to:** Receiver logic mutating Incident states.
```elixir
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update(:incident, incident_changeset)
      |> Ecto.Multi.insert(:timeline_entry, fn %{incident: incident} -> ...
```

## Metadata

**Analog search scope:** `lib/parapet/plug/`, `lib/parapet/operator.ex`, `lib/parapet/spine/`, `test/parapet/`
**Files scanned:** 5
**Pattern extraction date:** $(date -u +"%Y-%m-%d")
