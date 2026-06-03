# Phase 3: SLO DSL, Login Journey, and Deploy Markers - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 5
**Analogs found:** 2 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/integrations/sigra.ex` | provider | event-driven | `lib/parapet/metrics/oban.ex` | exact |
| `lib/mix/tasks/parapet.doctor.ex` | utility/CLI | batch | `lib/mix/tasks/verify.public_api.ex` | exact |
| `lib/parapet/deploy.ex` | module | event-driven | none | n/a |
| `lib/parapet/slo.ex` | config/DSL | transform | none | n/a |
| `lib/parapet/slo/generator.ex` | utility | file-IO | none | n/a |

## Pattern Assignments

### `lib/parapet/integrations/sigra.ex` (provider, event-driven)

**Analog:** `lib/parapet/metrics/oban.ex`

**Optional Compilation Pattern** (lines 1-5):
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    @moduledoc """
    Defines Prometheus distributions and counters for Oban jobs conditionally.
    """
```

**Event Attachment Pattern** (lines 11-23):
```elixir
    def setup do
      Parapet.attach(%{
        handler_id: "parapet-oban-job-stop",
        event_name: [:oban, :job, :stop],
        handler_module: __MODULE__,
        function_name: :handle_event
      })

      Parapet.attach(%{
        handler_id: "parapet-oban-job-exception",
        event_name: [:oban, :job, :exception],
        handler_module: __MODULE__,
        function_name: :handle_event
      })
```

**Telemetry Emission Pattern** (lines 65-69):
```elixir
      :telemetry.execute(
        [:parapet, :oban, :job],
        %{duration_ms: duration_ms},
        %{worker: worker, queue: queue, state: state}
      )
```

---

### `lib/mix/tasks/parapet.doctor.ex` (utility/CLI, batch)

**Analog:** `lib/mix/tasks/verify.public_api.ex`

**CLI Definition Pattern** (lines 1-8):
```elixir
defmodule Mix.Tasks.Verify.PublicApi do
  @moduledoc """
  Verifies that all public API modules have documentation and generate a manifest.
  """
  use Mix.Task

  @shortdoc "Verifies public API module documentation"
```

**Task Execution and Validation Pattern** (lines 11-15):
```elixir
  @impl Mix.Task
  def run(_args) do
    # Ensure application is compiled and loaded
    Mix.Task.run("compile")
    Application.load(:parapet)
```

**Error Exit Pattern** (lines 33-36):
```elixir
    if Enum.any?(manifest, fn m -> not m.has_docs end) do
      IO.puts(:stderr, "Error: One or more public API modules are missing documentation.")
      System.halt(1)
    end
```

---

## Shared Patterns

### Safe Telemetry Handlers
**Source:** `lib/parapet/internal/safe_handler.ex`
**Apply to:** All event handlers (e.g., `lib/parapet/integrations/sigra.ex`)
```elixir
        try do
          apply(handler_module, function_name, [event, measurements, metadata, conf])
        rescue
          e ->
            Logger.error(
              "Parapet telemetry handler exception in #{inspect(handler_module)}.#{function_name}/4 for event #{inspect(event)}: #{Exception.message(e)}\nStacktrace: #{inspect(__STACKTRACE__)}"
            )
        end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/deploy.ex` | module | event-driven | Unique API for emitting monotonically sequenced deploy marker telemetry events for Grafana annotations. |
| `lib/parapet/slo.ex` | config | transform | First introduction of the SLO DSL definition structure. |
| `lib/parapet/slo/generator.ex` | utility | file-IO | First instance of EEx templates for YAML file generation. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`, `lib/mix/tasks/**/*.ex`
**Files scanned:** 9
**Pattern extraction date:** 2026-05-09
