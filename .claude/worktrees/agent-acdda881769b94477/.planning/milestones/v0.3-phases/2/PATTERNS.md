# Phase 2: Runbooks & Automated Mitigations - Pattern Map

**Mapped:** 2024-05-11
**Files analyzed:** 5
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/runbook.ex` | config | configuration | `lib/parapet/slo.ex` | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |
| `lib/parapet/operator.ex` | service | CRUD | `lib/parapet/operator.ex` | exact |
| `lib/parapet/spine/incident.ex` | model | CRUD | `lib/parapet/spine/incident.ex` | exact |

## Pattern Assignments

### `lib/parapet/runbook.ex` (config, configuration)

**Analog:** `lib/parapet/slo.ex`

**Core Pattern (DSL Definition)** (lines 20-43):
```elixir
  def define(name, opts) do
    objective = Keyword.get(opts, :objective)
    # ... extraction
    
    missing =
      []
      |> append_if_missing(objective, :objective)
      # ... validation

    if missing != [] do
      raise ArgumentError, "missing required fields for SLO #{name}: #{inspect(missing)}"
    end

    slo = %__MODULE__{
      name: name,
      # ... assignment
    }

    store(slo)
    slo
  end
```

**State Storage Pattern** (lines 53-58):
```elixir
  defp store(slo) do
    slos = all()
    # remove existing with same name and append new
    slos = Enum.reject(slos, &(&1.name == slo.name)) ++ [slo]
    Application.put_env(:parapet, :slos, slos)
  end
```

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (component, request-response)

**Analog:** Existing `action_rail` component in `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Core Pattern (Rendering actions & mitigations)** (lines 104-118):
```html
      <div class="bg-white border border-gray-200 rounded-md p-4">
        <h4 class="text-sm font-medium text-gray-900 mb-2">Mitigate</h4>
        <p class="text-xs text-gray-500 mb-3">Apply known mitigations.</p>
        <button class="w-full bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 px-4 rounded text-sm transition-colors mb-2">
          Rollback Deployment
        </button>
        <button class="w-full bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2 px-4 rounded text-sm transition-colors">
          Failover DB
        </button>
      </div>
```

---

### `lib/parapet/operator.ex` (service, CRUD)

**Analog:** `lib/parapet/operator.ex` audited actions

**Core Pattern (Audited Actions)** (lines 58-75):
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

**Core Pattern (Audit Payload Building)** (lines 125-135):
```elixir
  defp build_audit(tool_name, %ActionPayload{} = payload) do
    %{
      tool_name: tool_name,
      success: true,
      input: %{
        "actor" => payload.actor,
        "reason" => payload.reason,
        "correlation_id" => payload.correlation_id,
        "idempotency_key" => payload.idempotency_key,
        "action_type" => Atom.to_string(payload.action_type)
      }
    }
  end
```

---

### `lib/parapet/spine/incident.ex` (model, CRUD)

**Analog:** `lib/parapet/spine/incident.ex`

**Core Pattern (Ecto Schema)** (lines 9-22):
```elixir
  schema "parapet_incidents" do
    field :title, :string
    field :description, :string
    field :state, :string, default: "open"
    field :correlation_key, :string
    # Will need to add new fields here for runbook integration

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :state, :correlation_key]) # Add new fields
    |> validate_required([:title])
    |> validate_inclusion(:state, ["open", "investigating", "resolved"])
  end
```

---

## Shared Patterns

### Durable Command Execution
**Source:** `lib/parapet/evidence.ex`
**Apply to:** New operator actions (like `execute_mitigation` in `lib/parapet/operator.ex`)

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
      |> Ecto.Multi.insert(:tool_audit, fn %{timeline_entry: entry} ->
        %ToolAudit{}
        |> ToolAudit.changeset(Map.put(audit_attrs, :timeline_entry_id, entry.id))
      end)

    repo().transaction(multi)
  end
```

## Metadata

**Analog search scope:** `lib/parapet/`, `priv/templates/parapet.gen.ui/`
**Files scanned:** 5
**Pattern extraction date:** 2024-05-11