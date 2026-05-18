# Phase 1: Synthetic Probes - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 3 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/probe.ex` | behavior/macro | event-driven | `lib/parapet/runbook.ex` | exact |
| `lib/parapet/probe/native_scheduler.ex` | adapter | event-driven | None | N/A |
| `lib/parapet/probe/oban_scheduler.ex` | adapter | event-driven | `lib/parapet/notifier/oban_worker.ex` | role-match |
| `lib/parapet/metrics/probe.ex` | component | metrics | `lib/parapet/metrics/oban.ex` | exact |

## Pattern Assignments

### `lib/parapet/probe.ex` (behavior/macro, event-driven)

**Analog:** `lib/parapet/runbook.ex`

**Macro definition pattern** (lines 8-17):
```elixir
  defmacro __using__(_opts) do
    quote do
      import Parapet.Runbook
      Module.register_attribute(__MODULE__, :steps, accumulate: true)
      @before_compile Parapet.Runbook

      def execute_mitigation(_step, _incident), do: {:error, :not_implemented}
      defoverridable execute_mitigation: 2
    end
  end
```

---

### `lib/parapet/probe/oban_scheduler.ex` (adapter, event-driven)

**Analog:** `lib/parapet/notifier/oban_worker.ex`

**Oban worker pattern** (lines 1-8):
```elixir
defmodule Parapet.Notifier.ObanWorker do
  @moduledoc """
  Oban worker for durable asynchronous dispatch of notifications.
  """
  use Oban.Worker, queue: :default

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"incident_id" => incident_id, "adapter" => adapter_str}}) do
```

---

### `lib/parapet/metrics/probe.ex` (component, metrics)

**Analog:** `lib/parapet/metrics/oban.ex`

**Optional Dependency and Setup pattern** (lines 1-19):
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    @moduledoc """
    Defines Prometheus distributions and counters for Oban jobs conditionally.
    """
    require Logger

    alias Parapet.Internal.LabelPolicy

    @doc """
    Sets up the Oban metrics by attaching telemetry handlers.
    """
    def setup do
      Parapet.attach(%{
        handler_id: "parapet-oban-job-stop",
        event_name: [:oban, :job, :stop],
        handler_module: __MODULE__,
        function_name: :handle_event
      })
```

**Metrics definition pattern** (lines 33-43):
```elixir
    def metrics do
      import Telemetry.Metrics

      LabelPolicy.assert_safe!([:worker, :queue, :state])

      [
        counter("parapet.oban.jobs.total",
          event_name: [:parapet, :oban, :job],
          tags: [:worker, :queue, :state],
          description: "Total number of Oban jobs processed"
        ),
```

**Telemetry execution pattern** (lines 56-72):
```elixir
    @doc false
    def handle_event(_event, measurements, metadata, _config) do
      duration = Map.get(measurements, :duration)

      duration_ms =
        if duration, do: System.convert_time_unit(duration, :native, :millisecond), else: 0

      worker = to_string(Map.get(metadata, :worker, "unknown"))
      queue = to_string(Map.get(metadata, :queue, "unknown"))
      state = to_string(Map.get(metadata, :state, "unknown"))

      :telemetry.execute(
        [:parapet, :oban, :job],
        %{duration_ms: duration_ms},
        %{worker: worker, queue: queue, state: state}
      )
    end
```

---

## Shared Patterns

### Safe Telemetry Attachment
**Source:** `lib/parapet/internal/safe_handler.ex` (via `Parapet.attach`)
**Apply to:** `Parapet.Metrics.Probe`
```elixir
Parapet.attach(%{
  handler_id: "parapet-probe-run",
  event_name: [:parapet, :probe, :run],
  handler_module: __MODULE__,
  function_name: :handle_event
})
```

### Telemetry Label Safety Validation
**Source:** `lib/parapet/internal/label_policy.ex`
**Apply to:** `Parapet.Metrics.Probe.metrics/0`
```elixir
LabelPolicy.assert_safe!([:probe_name, :status])
```

## No Analog Found

Files with no close match in the codebase:

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/probe/native_scheduler.ex` | adapter | event-driven | No explicit `GenServer` implementations exist in the project to copy from. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`
**Files scanned:** 42
**Pattern extraction date:** 2024-05-24
