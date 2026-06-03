# Phase 1: OpenTelemetry Trace Exemplars - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 5
**Analogs found:** 4 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/plug/metrics.ex` | middleware | request-response | Self | exact |
| `lib/parapet/metrics/http.ex` | config | telemetry | Self | exact |
| `lib/parapet/metrics/oban.ex` | config | event-driven | Self | exact |
| `lib/parapet/spine/incident.ex` | model | CRUD | Self | exact |
| `priv/templates/parapet.gen.ui/operator_components.ex.eex` | component | request-response | Self | exact |

## Pattern Assignments

### Telemetry Processing & Forwarding

**Analog:** `lib/parapet/plug/metrics.ex` and `lib/parapet/metrics/oban.ex`

**Pattern: Safe execution with strict label policy** (`lib/parapet/plug/metrics.ex`, lines 25-32):
```elixir
# Validate labels through Parapet.Internal.LabelPolicy
LabelPolicy.assert_safe!([:route, :method, :status_class])

:telemetry.execute(
  [:parapet, :http, :request],
  %{duration_ms: duration_ms, status_code: conn.status},
  %{route: route, method: conn.method, status_class: status_class}
)
```

**Pattern: Metadata extraction & translation** (`lib/parapet/metrics/oban.ex`, lines 62-71):
```elixir
worker = to_string(Map.get(metadata, :worker, "unknown"))
queue = to_string(Map.get(metadata, :queue, "unknown"))
state = to_string(Map.get(metadata, :state, "unknown"))

:telemetry.execute(
  [:parapet, :oban, :job],
  %{duration_ms: duration_ms},
  %{worker: worker, queue: queue, state: state}
)
```
*Note: Any trace_id extraction from event metadata or `Process.get()` should mirror this flow, keeping it out of the `tags` metadata to prevent cardinality issues.*

### Prometheus Metric Exporting

**Analog:** `lib/parapet/metrics/http.ex`

**Pattern: Telemetry.Metrics configuration** (`lib/parapet/metrics/http.ex`, lines 31-39):
```elixir
distribution("parapet.http.request.duration_ms",
  event_name: [:parapet, :http, :request],
  measurement: :duration_ms,
  tags: [:route, :method, :status_class],
  description: "Duration of HTTP requests in milliseconds",
  reporter_options: [
    buckets: [10, 50, 100, 250, 500, 1000, 2500, 5000]
  ]
)
```
*Note: These definitions will need to be dynamically appended with `keep` or `tags` to expose the trace exemplar in PromEx/Telemetry.Metrics outputs.*

### Incident Schema

**Analog:** `lib/parapet/spine/incident.ex`

**Pattern: Ecto Schema definition** (`lib/parapet/spine/incident.ex`, lines 10-18):
```elixir
schema "parapet_incidents" do
  field(:title, :string)
  field(:description, :string)
  field(:state, :string, default: "open")
  field(:correlation_key, :string)
  field(:runbook_data, :map)

  timestamps(type: :utc_datetime_usec)
end
```
*Note: A `field(:trace_id, :string)` must be appended to the schema inline with this pattern, alongside its equivalent migration.*

### Operator UI Trace Deep Linking

**Analog:** `priv/templates/parapet.gen.ui/operator_components.ex.eex`

**Pattern: External Links Rendering** (`priv/templates/parapet.gen.ui/operator_components.ex.eex`, lines 56-64):
```elixir
<div class="flex flex-col gap-2">
  <%%= for link <- @detail.external_links do %>
    <a href={link} class="text-sm text-blue-600 hover:underline flex items-center gap-1" target="_blank">
      <span><%%= link %></span> &nearr;
    </a>
  <%% end %>
  <%%= if Enum.empty?(@detail.external_links) do %>
    <span class="text-sm text-gray-500">No external links attached.</span>
  <%% end %>
</div>
```
*Note: A UI helper will utilize `config :parapet, trace_url_template` to format the generated `trace_id` and add it alongside these `external_links`.*

## Shared Patterns

### Label Safety Enforcement
**Source:** `lib/parapet/internal/label_policy.ex`
**Apply to:** All metrics definitions and `.execute` calls.
```elixir
if label_str =~ ~r/id$/ or label_str =~ ~r/^raw_/ or label_str =~ ~r/token/ or
     label_str =~ ~r/path/ do
  raise ArgumentError, "High cardinality label rejected by Parapet safety policy: #{label}"
end
```
*Crucial rule: `trace_id` must NEVER bypass `LabelPolicy`. It should be passed distinctly as metadata meant for exemplars, not labels.*

## No Analog Found

Files with no close match in the codebase:

| File / Pattern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| OpenTelemetry Fetch | utility | sync | A global search confirmed no prior use of `:opentelemetry_api`, `:otel`, or `Process.get()` for traces in the codebase yet. |

## Metadata

**Analog search scope:** `lib/parapet/**/*.ex`, `priv/templates/parapet.gen.ui/**/*.ex`
**Files scanned:** 55
**Pattern extraction date:** 2024-05-24
