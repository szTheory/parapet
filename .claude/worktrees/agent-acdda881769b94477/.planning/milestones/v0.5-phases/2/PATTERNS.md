# Phase 2: Deepened Journey Integrations - Pattern Map

**Mapped:** `2024-05-16`
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/integrations/sigra.ex` | integration | event-driven | `lib/parapet/integrations/scoria.ex` | role-match |
| `lib/parapet/integrations/accrue.ex` | integration | event-driven | `lib/parapet/integrations/scoria.ex` | role-match |
| `lib/parapet/metrics/sigra.ex` | config | event-driven | `lib/parapet/metrics/scoria.ex` | role-match |
| `lib/parapet/metrics/accrue.ex` | config | event-driven | `lib/parapet/metrics/scoria.ex` | role-match |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | `priv/templates/parapet.gen.ui/operator_components.ex.eex` | exact |

## Pattern Assignments

### `lib/parapet/integrations/sigra.ex` & `lib/parapet/integrations/accrue.ex` (integration, event-driven)

**Analog:** `lib/parapet/integrations/scoria.ex`

**Imports and Constants pattern** (lines 8-10):
```elixir
  require Logger

  @safe_labels [:model, :provider, :tool_name]
```

**Setup and handler registration pattern** (lines 14-41):
```elixir
  def setup do
    :telemetry.attach(
      "parapet-scoria-telemetry",
      [:scoria, :sre, :telemetry],
      &__MODULE__.handle_event/4,
      nil
    )
    
    # Delegate to explicit metrics setup
    Parapet.Metrics.Scoria.setup()
  end
```

**Error handling and wrapper pattern** (lines 46-54):
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

**Core telemetry translation pattern** (lines 56-66):
```elixir
  defp process_event([:scoria, :sre, :telemetry], measurements, metadata) do
    # Extract only low-cardinality labels
    safe_metadata = Map.take(metadata, @safe_labels)

    # Emit translated event
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      safe_metadata
    )
    :ok
  end
```

---

### `lib/parapet/metrics/sigra.ex` & `lib/parapet/metrics/accrue.ex` (config, event-driven)

**Analog:** `lib/parapet/metrics/scoria.ex`

**Telemetry attach safely pattern** (lines 10-21):
```elixir
  def setup do
    :telemetry.attach(
      "parapet-scoria-eval-handler",
      [:scoria, :eval, :completed],
      &__MODULE__.handle_event/4,
      nil
    )
    :ok
  rescue
    e in [ArgumentError] ->
      Logger.error("Failed to register Scoria metrics handler: #{Exception.message(e)}")
      {:error, e}
  end
```

**Prometheus definition pattern** (lines 35-46):
```elixir
  def metrics do
    import Telemetry.Metrics

    [
      counter("scoria_evaluation_total",
        event_name: [:parapet, :scoria, :eval, :completed],
        tags: [:guardrail, :passed, :model_name],
        description: "Total number of Scoria AI evaluations"
      )
    ]
  end
```

---

### `priv/templates/parapet.gen.ui/operator_components.ex.eex` (component, request-response)

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Explicit Surface Component Pattern** (lines 42-47):
*Use this pattern to add explicit sections for "Login/Signup Success Rates" (Sigra) and "Checkout Health / Webhook Latency" (Accrue) within the summary or detail views.*

```elixir
      <div class="bg-blue-50 p-4 rounded-md mb-6">
        <h4 class="text-sm font-medium text-blue-900 mb-2">Impact Summary</h4>
        <p class="text-sm text-blue-800">
          <%%= Map.get(@detail.derived, :impact_summary, "No impact summary recorded.") %>
        </p>
      </div>
```

## Shared Patterns

### Error Handling in Telemetry Handlers
**Source:** `lib/parapet/integrations/scoria.ex`
**Apply to:** All integration handlers
```elixir
  rescue
    e ->
      Logger.error(
        "Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}"
      )
      :ok
```

### Delegation to Metric Definitions
**Source:** `lib/parapet/integrations/scoria.ex`
**Apply to:** `sigra.ex` and `accrue.ex` `setup/0` functions.
```elixir
    # Attach Phase X metrics definitions
    Parapet.Metrics.IntegrationName.setup()
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `lib/parapet/integrations/**/*.ex`, `lib/parapet/metrics/**/*.ex`, `priv/templates/parapet.gen.ui/**/*.eex`
**Files scanned:** 14
**Pattern extraction date:** 2024-05-16
