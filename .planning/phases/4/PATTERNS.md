# Phase 4: Scoria AI Integration - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/spine/action_item.ex` | model | CRUD | `lib/parapet/spine/incident.ex` | exact |
| `lib/parapet/integrations/scoria.ex` | integration | event-driven | `lib/parapet/integrations/scoria.ex` | self |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | self |

## Pattern Assignments

### `lib/parapet/spine/action_item.ex` (model, CRUD)

**Analog:** `lib/parapet/spine/incident.ex`

**Imports pattern** (lines 4-5):
```elixir
  use Ecto.Schema
  import Ecto.Changeset
```

**Core Ecto Schema pattern** (lines 7-17):
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_incidents" do
    field(:title, :string)
    field(:description, :string)
    field(:state, :string, default: "open")
    field(:correlation_key, :string)
    field(:runbook_data, :map)

    timestamps(type: :utc_datetime_usec)
  end
```

**Changeset Validation pattern** (lines 20-25):
```elixir
  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [:title, :description, :state, :correlation_key, :runbook_data])
    |> validate_required([:title])
    |> validate_inclusion(:state, ["open", "investigating", "resolved"])
  end
```

---

### `lib/parapet/integrations/scoria.ex` (integration, event-driven)

**Analog:** `lib/parapet/integrations/scoria.ex`

**Telemetry Attachment pattern** (lines 14-20):
```elixir
  def setup do
    # Attach Phase 1 SRE telemetry
    :telemetry.attach(
      "parapet-scoria-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )
```

**Core Telemetry processing pattern** (lines 47-51, 62-72):
```elixir
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error(...)
      :ok
  end

  defp process_event([:scoria, :sre, :telemetry], measurements, metadata) do
    # Emit translated event
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      parapet_metadata
    )

    # Route errors to Parapet.Evidence.create_incident/1
    if has_error? do
      Parapet.Evidence.create_incident(%{...})
    end
    :ok
  end
```

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Deep Link UI / Runbook Card Pattern** (lines 125-136):
```elixir
  attr :runbook_data, :map, required: true
  attr :incident_id, :string, required: true
  def runbook_card(assigns) do
    ~H"""
    <div class="bg-white border border-gray-200 rounded-md p-4 mb-6">
      <h3 class="text-lg font-semibold text-gray-900 mb-1">
        <%%= @runbook_data["title"] || @runbook_data[:title] || "Runbook" %>
      </h3>
      <p class="text-sm text-gray-600 mb-4">
        <%%= @runbook_data["description"] || @runbook_data[:description] || "No description provided." %>
      </p>
    """
  end
```

**Action Rail pattern** (lines 160-170):
```elixir
  attr :detail, :map, required: true
  def action_rail(assigns) do
    ~H"""
    <div class="flex flex-col gap-4">
      <%%= if @detail.incident.state == "open" do %>
        <div class="bg-white border border-gray-200 rounded-md p-4">
          <h4 class="text-sm font-medium text-gray-900 mb-2">Acknowledge</h4>
          <p class="text-xs text-gray-500 mb-3">Take ownership of this incident.</p>
          <button phx-click="acknowledge" phx-value-id={@detail.incident.id} class="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded text-sm transition-colors">
            Acknowledge Incident
          </button>
        </div>
      <%% end %>
```

---

## Shared Patterns

### Centralized Error Processing
**Source:** `lib/parapet/integrations/scoria.ex`
**Apply to:** All telemetry processing functions
```elixir
  def handle_event(event, measurements, metadata, _config) do
    process_event(event, measurements, metadata)
  rescue
    e ->
      Logger.error("Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}")
      :ok
  end
```

### Idempotent Ecto Insertion
**Source:** `lib/parapet/evidence.ex`
**Apply to:** Ecto context operations for ActionItems
```elixir
  def create_incident(attrs \\ %{}) do
    %Incident{}
    |> Incident.changeset(attrs)
    |> repo().insert()
  end
```

## Config Pattern

### Deep Link Resolver Configuration
**Source:** Standard Phoenix / Elixir Configuration
**Apply to:** `config/config.exs` or `lib/parapet/internal/application.ex` (analog for setting MFA resolvers).
The `ui_url_resolver` will need to safely load the configured `{Module, :function, args}` and apply it.

## Metadata

**Analog search scope:** `lib/parapet/spine/*.ex`, `lib/parapet/integrations/*.ex`, `priv/templates/parapet.gen.ui/*.eex`
**Files scanned:** 10
**Pattern extraction date:** 2024-05-24
