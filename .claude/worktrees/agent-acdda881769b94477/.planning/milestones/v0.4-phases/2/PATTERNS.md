# Phase 2: Eval-Driven SLOs - Pattern Map

**Mapped:** 2026-05-13
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/slo/scoria_eval.ex` | component | transform/struct-building | `lib/parapet/slo/http.ex` | role-match |
| `lib/parapet/slo/provider.ex` | behaviour | contract/interface | `lib/parapet/notifier.ex` | role-match |
| `lib/parapet/slo.ex` | core struct | struct-building | itself | exact |
| `lib/parapet/metrics/scoria.ex` | metrics | event-driven | `lib/parapet/metrics/http.ex` | exact |

## Pattern Assignments

### `lib/parapet/slo/scoria_eval.ex` (component, transform/struct-building)

**Analog:** `lib/parapet/slo/http.ex` & `lib/parapet/slo.ex` (for struct definition)

**Struct Definition Pattern** (from `lib/parapet/slo.ex`, lines 6-17):
```elixir
  @enforce_keys [:name, :objective, :good_events, :total_events, :runbook]
  defstruct [:name, :objective, :good_events, :total_events, :runbook]

  @type t :: %__MODULE__{
          name: atom(),
          objective: float(),
          good_events: String.t(),
          total_events: String.t(),
          runbook: String.t()
        }
```

*Note: For ScoriaEval, we will enforce keys like `[:name, :objective, :guardrail, :runbook]` and implement a `to_slo/1` translation function as identified in RESEARCH.md.*

### `lib/parapet/slo/provider.ex` (behaviour, contract/interface)

**Analog:** `lib/parapet/notifier.ex`

**Behaviour Definition Pattern** (from `lib/parapet/notifier.ex`, lines 1-5):
```elixir
defmodule Parapet.Notifier do
  @moduledoc """
  Behaviour for incident notification adapters.
  """
  @callback deliver(incident :: struct(), opts :: keyword()) :: {:ok, term()} | {:error, term()}
```

*Note: The provider will implement `@callback slos() :: [Parapet.SLO.t()]` to provide the data-first registry of SLOs.*

### `lib/parapet/slo.ex` (core struct, struct-building)

**Analog:** itself (refactoring)

**Deprecation Pattern** (existing `define/2` pattern, lines 20-35):
```elixir
  def define(name, opts) do
    # This will be updated to print a deprecation warning and map to the new registry pattern.
    objective = Keyword.get(opts, :objective)
    # ...
```

### `lib/parapet/metrics/scoria.ex` (metrics, event-driven)

**Analog:** `lib/parapet/metrics/http.ex`

**Metrics Setup Pattern** (from `lib/parapet/metrics/http.ex`, lines 1-17):
```elixir
defmodule Parapet.Metrics.HTTP do
  @moduledoc """
  Defines Prometheus counters and distributions for HTTP requests.
  """
  require Logger

  @doc """
  Sets up the metrics by attaching telemetry handlers or registering with Telemetry.Metrics.
  Returns `:ok` or `{:error, reason}` on duplicate registration.
  """
  def setup do
    # In the future, this is where Telemetry.Metrics reporters might be started or registered.
    # For now, we simulate registration success while capturing errors.
    :ok
  rescue
    e in [ArgumentError] ->
      Logger.error("Failed to register metrics: #{Exception.message(e)}")
      {:error, e}
  end
```

**Metrics Definition Pattern** (from `lib/parapet/metrics/http.ex`, lines 19-33):
```elixir
  @doc """
  Returns a list of Telemetry.Metrics definitions for HTTP events.
  """
  def metrics do
    import Telemetry.Metrics

    [
      counter("parapet.http.request.count",
        event_name: [:parapet, :http, :request],
        tags: [:route, :method, :status_class],
        description: "Total number of HTTP requests"
      ),
      # ...
    ]
  end
```

*Note: `Parapet.Metrics.Scoria` will attach to `[:scoria, :eval, :completed]` and export strict low-cardinality metrics (like `tags: [:guardrail, :passed, :model_name]`).*

## Shared Patterns

### Struct Validation
**Source:** `lib/parapet/slo.ex`
**Apply to:** `Parapet.SLO.ScoriaEval`
```elixir
    missing =
      []
      |> append_if_missing(objective, :objective)
      |> append_if_missing(good_events, :good_events)

    if missing != [] do
      raise ArgumentError, "missing required fields for SLO #{name}: #{inspect(missing)}"
    end
```

## No Analog Found

All files found suitable analogs.

## Metadata

**Analog search scope:** `lib/parapet/slo/**/*.ex`, `lib/parapet/metrics/**/*.ex`, `lib/parapet/**/*.ex`
**Files scanned:** 37
**Pattern extraction date:** 2026-05-13