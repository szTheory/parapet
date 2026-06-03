# Phase 3: Ecosystem Integrations - Pattern Map

**Mapped:** 2023-10-27 (or current)
**Files analyzed:** 8
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/integrations/rulestead.ex` | adapter | event-driven / mutative | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet/integrations/mailglass.ex` | adapter | event-driven | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet/integrations/chimeway.ex` | adapter | event-driven | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet/integrations/accrue.ex` | adapter | event-driven | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet/integrations/rindle.ex` | adapter | event-driven | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet/integrations/threadline.ex` | adapter | event-driven / transform | `lib/parapet/integrations/sigra.ex` | exact |
| `lib/parapet.ex` | config | config | N/A (Existing) | modify |
| `lib/parapet/operator.ex` | context | request-response | N/A (Existing) | modify |

## Pattern Assignments

### Integration Adapters (`lib/parapet/integrations/*.ex`)

**Analog:** `lib/parapet/integrations/sigra.ex`

**Conditional Compilation Pattern** (lines 1-2, 47):
All Phase 3 integrations **must** be wrapped in `Code.ensure_loaded?/1` to satisfy ECO-04 (compile out cleanly constraint).
```elixir
if Code.ensure_loaded?(SiblingModule) do
  defmodule Parapet.Integrations.SiblingModule do
    # ...
  end
end
```

**Setup/Activation Pattern** (lines 10-23):
Adapters expose a `setup/0` or `setup/1` that attaches telemetry handlers.
```elixir
    @doc """
    Attaches telemetry handlers for the sibling library.
    """
    def setup(opts \\ []) do
      :telemetry.attach(
        "parapet-sibling-event",
        [:sibling, :event, :action],
        &__MODULE__.handle_event/4,
        opts
      )
    end
```

**Safe Event Handling Pattern** (lines 25-33):
Must catch exceptions to prevent crashing host application logic.
```elixir
    def handle_event(event, measurements, metadata, config) do
      process_event(event, measurements, metadata, config)
    rescue
      e ->
        Logger.error("Parapet telemetry handler exception in #{__MODULE__}.handle_event/4 for event #{inspect(event)}: #{Exception.message(e)}")
    end
```

---

### Adapter Activation (`lib/parapet.ex`)

**Goal:** Modify `Parapet.attach/1` to support an `adapters` key as specified in Phase 3 Context.

**Pattern Setup:**
The current `Parapet.attach/1` (lines 18-42 in `lib/parapet.ex`) accepts a single map. It must be updated or supplemented to accept a keyword list that iterates over the provided adapters.
```elixir
# Future state based on Phase 3 Context
def attach(adapters: adapters) do
  Enum.each(adapters, fn 
    {adapter_mod, opts} -> 
      if Code.ensure_loaded?(adapter_mod), do: adapter_mod.setup(opts)
    adapter_mod -> 
      if Code.ensure_loaded?(adapter_mod), do: adapter_mod.setup()
  end)
end
```

---

### UI Extensibility Seam (`lib/parapet/operator.ex` & `lib/parapet.ex`)

**Goal:** Expose capabilities for the generated Phoenix UI (`parapet.gen.ui`).

**Pattern Registration (Research Based):**
Integrations with mutative UI features (like `Rulestead`) need to register their capabilities. Because Elixir uses processes for state, this might require an ETS table or an Agent started by Parapet's application tree, or simply state held in `Parapet.Operator`.
```elixir
# In lib/parapet/integrations/rulestead.ex (inside setup/1)
Parapet.Operator.register_mitigation_action(
  id: :rulestead_toggle,
  label: "Toggle Feature Flag",
  module: Parapet.Integrations.Rulestead.UI,
  function: :render_toggle
)
```

**Pattern Querying:**
```elixir
# In lib/parapet/operator.ex
@doc """
Returns registered UI capabilities dynamically.
"""
def capabilities(:mitigation) do
  # Retrieve registered mitigation capabilities from an Agent or ETS table
end
```

---

### Durable Evidence Spine Interoperability (ECO-05)

**Goal:** Understand Ecto schema relationships for `Threadline` integration.

**Pattern Relationship** (lines 7-10 in `lib/parapet/spine/incident.ex`):
```elixir
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "parapet_incidents" do
    # ...
```
Any `Threadline` interoperability will involve querying `Parapet.Spine.ToolAudit` and `Parapet.Spine.TimelineEntry` and ensuring identifiers map correctly between the two systems. Adapters can read the schemas safely, provided they don't introduce high-volume telemetry directly into Ecto (satisfying SPINE-04).

## Shared Patterns

### Safely Calling Sibling Code
**Source:** Phase 3 Context / Research
**Apply to:** Mutative integrations (`Rulestead`)
When invoking mutations (e.g., toggling a flag), the adapter module can safely call `Rulestead.set_flag/3` because the adapter module itself is guarded by `if Code.ensure_loaded?(Rulestead)`. The UI dynamic seam prevents missing module crashes at runtime. This avoids the need for reflection or `apply/3` when calling out to ecosystem peers.