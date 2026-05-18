# Phase 2: Rulestead Flag Correlation - Pattern Map

**Mapped:** 2024-05-30
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/system_event.ex` | model | CRUD | `lib/parapet/spine/timeline_entry.ex` | exact |
| `lib/parapet/system_event/pruner.ex` | service | batch | `lib/parapet/metrics/exemplar_store.ex` | partial (GenServer) |
| `lib/parapet/integrations/rulestead.ex` | adapter | event-driven | `lib/parapet/integrations/scoria.ex` | role-match |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | render | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact (internal) |

## Pattern Assignments

### `lib/parapet/system_event.ex` (model, CRUD)

**Analog:** `lib/parapet/spine/timeline_entry.ex`

**Schema and Changeset pattern** (lines 11-25):
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_timeline_entries" do
    field(:type, :string)
    field(:payload, :map)

    belongs_to(:incident, Incident, type: :binary_id)

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(timeline_entry, attrs) do
    timeline_entry
    |> cast(attrs, [:type, :payload, :incident_id])
    |> validate_required([:type, :incident_id])
  end
```

---

### `lib/parapet/system_event/pruner.ex` (service, batch)

**Analog:** `lib/parapet/metrics/exemplar_store.ex`

**GenServer structure pattern** (lines 11-14):
```elixir
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
```

**Init callback pattern** (lines 33-36):
```elixir
  @impl true
  def init(_opts) do
    # Scheduled cleanup setup will go here, e.g. Process.send_after(self(), :prune, interval)
    {:ok, %{}}
  end
```

---

### `lib/parapet/integrations/rulestead.ex` (adapter, event-driven)

**Analog:** `lib/parapet/integrations/scoria.ex`

*(Note: The integration file already exists but needs updating to handle `[:rulestead, :admin, :ruleset, :published]` events and insert `SystemEvent`s based on `RESEARCH.md`)*

**Telemetry attach pattern** (lines 13-19 from `scoria.ex`):
```elixir
    :telemetry.attach(
      "parapet-scoria-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )
```

**Telemetry handler and rescue pattern** (lines 42-51 from `scoria.ex`):
```elixir
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )

      :ok
  end
```

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (component, render)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex` (itself, specifically `runbook_card` and `incident_timeline`)

**"Suspect Changes" Hero Card pattern** (based on `runbook_card` lines 141-152):
```elixir
  attr :runbook_data, :map, required: true
  attr :incident_id, :string, required: true
  def runbook_card(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-md p-4 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-1">
        <%= @runbook_data["title"] || @runbook_data[:title] || "Runbook" %>
      </h3>
      <p class="text-sm text-gray-600 mb-4">
        <%= @runbook_data["description"] || @runbook_data[:description] || "No description provided." %>
      </p>
```

**"Inline Timeline Marker" pattern** (based on `incident_timeline` lines 112-121):
```elixir
            <div class="relative pb-8">
              <span class="absolute top-4 left-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
              <div class="relative flex space-x-3">
                <div>
                  <span class="h-8 w-8 rounded-full bg-gray-400 flex items-center justify-center ring-8 ring-white">
                  </span>
                </div>
                <div class="flex min-w-0 flex-1 justify-between space-x-4 pt-1.5">
```

## Shared Patterns

### Error Isolation in Telemetry Handlers
**Source:** `lib/parapet/integrations/scoria.ex`
**Apply to:** All adapter telemetry callbacks
```elixir
  rescue
    e ->
      Logger.error(...)
      :ok
```

## No Analog Found

All files had viable analogs.

## Metadata

**Analog search scope:** `lib/parapet/`, `priv/templates/parapet.gen.ui/`
**Files scanned:** ~60
**Pattern extraction date:** 2024-05-30
