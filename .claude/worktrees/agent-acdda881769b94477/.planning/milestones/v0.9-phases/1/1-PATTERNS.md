# Phase 1: Performance, Scale & DX (Cardinality Protection) - Pattern Map

**Mapped:** `date +%Y-%m-%d`
**Files analyzed:** ~15 (doctor mix task, metrics definitions, SLOs, label policy)
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/parapet.doctor.ex` | mix task | batch/static-analysis | `lib/mix/tasks/parapet.doctor.ex` | exact |
| `lib/parapet/metrics/builder.ex` (New) | utility/macro | compile-time | `lib/parapet/runbook.ex` | role-match |
| `lib/parapet/internal/label_policy.ex` | utility | validation | `lib/parapet/internal/label_policy.ex` | exact |
| `lib/parapet/metrics/*.ex` | config/metrics | config | `lib/parapet/metrics/http.ex` | exact |
| `lib/parapet/slo/*.ex` | config/slo | config | `lib/parapet/slo/http.ex` | exact |

## Pattern Assignments

### `lib/mix/tasks/parapet.doctor.ex` (mix task, batch/static-analysis)

**Analog:** `lib/mix/tasks/parapet.doctor.ex`

**Task parsing pattern** (lines 20-30):
```elixir
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, switches: [ci: :boolean])
    is_ci = Keyword.get(opts, :ci, false)
    # Check if 'cardinality' was passed in unparsed args or just run everything
```

**AST static analysis pattern** (lines 142-160):
```elixir
      if Code.ensure_loaded?(Sourceror) do
        ast = Sourceror.parse_string!(source)

        {_, acc} =
          Macro.prewalk(ast, {[], []}, fn
            # Match telemetry metric definitions here
            {:counter, _, [name | opts]}, {scopes, violations} ->
               # Analyze options for tags length or unsafe values
            node, acc ->
              {node, acc}
          end)
```

**Error reporting pattern** (lines 191-209):
```elixir
  defp print_human(results) do
    Enum.each(results, fn {check, result} ->
      color =
        case result.status do
          :ok -> [:green]
          :warn -> [:yellow]
          :fatal -> [:red]
        end
        # Print with colors...
```

---

### `lib/parapet/metrics/builder.ex` (utility/macro, compile-time)

*New file to enforce label limits at compile time by wrapping Telemetry.Metrics.*

**Analog:** `lib/parapet/runbook.ex`

**Macro definition pattern** (lines 19-35):
```elixir
  defmacro step(id, opts) do
    quote do
      # Validate inputs at compile time using standard assertions before quoting
    end
  end
```

**`__using__` setup pattern** (lines 8-17):
```elixir
  defmacro __using__(_opts) do
    quote do
      import Parapet.Metrics.Builder
      # Disable conflicting standard imports if necessary
      import Telemetry.Metrics, except: [counter: 2, distribution: 2, sum: 2, last_value: 2]
    end
  end
```

---

### `lib/parapet/internal/label_policy.ex` (utility, validation)

**Analog:** `lib/parapet/internal/label_policy.ex`

**Core validation pattern** (lines 6-13):
```elixir
  def assert_safe!(labels) do
    # Add count check here (e.g., max 10 labels)
    Enum.each(labels, fn label ->
      label_str = to_string(label)
      if label_str =~ ~r/id$/ or label_str =~ ~r/^raw_/ or label_str =~ ~r/token/ or
           label_str =~ ~r/path/ do
        raise ArgumentError, "High cardinality label rejected by Parapet safety policy: #{label}"
      end
    end)
    :ok
  end
```

---

### Built-in Metrics and SLIs (`lib/parapet/metrics/*.ex`, `lib/parapet/slo/*.ex`)

**Analog:** `lib/parapet/metrics/http.ex`

**Metrics definition pattern** (lines 22-38):
```elixir
  def metrics do
    import Telemetry.Metrics # Will become: use Parapet.Metrics.Builder

    [
      counter("parapet.http.request.count",
        event_name: [:parapet, :http, :request],
        tags: [:route, :method, :status_class], # These must conform to limits
        description: "Total number of HTTP requests"
      )
    ]
  end
```

**SLO definition pattern** (lines 18-35 from `lib/parapet/slo/http.ex`):
```elixir
    # SLOs reference metrics; their PromQL must align with any reduced cardinality changes
    good_events = Keyword.get(opts, :good_events, "parapet_http_server_duration_milliseconds_count{status_code=~\"2..|3..\"}")
    slo = %Parapet.SLO{
      name: :http,
      objective: objective,
      good_events: good_events,
      total_events: total_events,
      runbook: runbook
    }
```

## Shared Patterns

### Validation
**Source:** `lib/parapet/internal/label_policy.ex`
**Apply to:** All metrics macros (`Parapet.Metrics.Builder`) and the static analysis task `mix parapet.doctor cardinality`. The central `LabelPolicy` should be the source of truth for limits and name patterns.

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/parapet/metrics/`, `lib/parapet/slo/`, `lib/parapet/`
**Files scanned:** ~15
**Pattern extraction date:** `date +%Y-%m-%d`
