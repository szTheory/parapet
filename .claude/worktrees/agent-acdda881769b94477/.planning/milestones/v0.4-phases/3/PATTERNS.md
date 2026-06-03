# Phase 3: AI Deploy Correlation & MCP SLIs - Pattern Map

**Mapped:** 2024-05-14
**Files analyzed:** 5
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/integrations/scoria.ex` | integration | event-driven | itself (Phase 1) | exact |
| `lib/parapet/metrics/scoria.ex` | config | configuration | itself (Phase 2) | exact |
| `priv/templates/parapet.gen.scoria/rules.yml.eex` | config | declarative | `priv/templates/parapet.gen.prometheus/rules.yml.eex` | exact |
| `priv/templates/parapet.gen.scoria/scoria_dashboard.json.eex` | config | declarative | `priv/templates/parapet.gen.grafana/main_dashboard.json.eex` | exact |
| `lib/parapet/spine/incident.ex` | model | CRUD | itself | exact |

## Pattern Assignments

### SRE Telemetry Consumption (`lib/parapet/integrations/scoria.ex`, `lib/parapet/metrics/scoria.ex`)

**Analog:** Existing Phase 1 SRE telemetry processing in `lib/parapet/integrations/scoria.ex` and Phase 2 metrics in `lib/parapet/metrics/scoria.ex`.

**SRE Event Processing Pattern** (`lib/parapet/integrations/scoria.ex`, lines 39-55):
```elixir
  defp process_event([:scoria, :sre, :telemetry], measurements, metadata) do
    # Extract only low-cardinality labels
    safe_metadata = Map.take(metadata, @safe_labels)

    # Determine outcome based on :error presence
    has_error? = Map.has_key?(metadata, :error) and not is_nil(metadata.error)
    outcome = if has_error?, do: :failure, else: :success
    
    parapet_metadata = Map.put(safe_metadata, :outcome, outcome)

    # Emit translated event
    :telemetry.execute(
      [:parapet, :scoria, :metrics],
      measurements,
      parapet_metadata
    )
```

**Metrics Declaration Pattern** (`lib/parapet/metrics/scoria.ex`, lines 36-43):
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

### SLI / Prometheus Rules (`priv/templates/parapet.gen.scoria/rules.yml.eex`)

**Analog:** `priv/templates/parapet.gen.prometheus/rules.yml.eex`

**Rule Group Template Pattern** (`priv/templates/parapet.gen.prometheus/rules.yml.eex`, lines 1-14):
```yaml
groups:
<%= for slo <- slos do %>
  - name: parapet_slo_<%= slo.name %>
    rules:
<%= for window <- windows do %>
      - record: slo:error_ratio:rate<%= window %>
        expr: >
          1 - (
            sum(rate(<%= slo.good_events %>[<%= window %>]))
            /
            sum(rate(<%= slo.total_events %>[<%= window %>]))
          )
        labels:
          slo: <%= slo.name %>
<% end %>
```

### Grafana Dashboard Generation (`priv/templates/parapet.gen.scoria/scoria_dashboard.json.eex`)

**Analog:** `priv/templates/parapet.gen.grafana/main_dashboard.json.eex`

**EEx Injecting Prometheus Targets Pattern** (`priv/templates/parapet.gen.grafana/main_dashboard.json.eex`, lines 56-82):
```json
<%= for {slo, index} <- Enum.with_index(slos) do %>
    ,{
      "datasource": {
        "type": "prometheus",
        "uid": "${DS_PROMETHEUS}"
      },
      "gridPos": {
        "h": 8,
        "w": 16,
        "x": 0,
        "y": <%= index * 8 + 1 %>
      },
      "id": <%= index * 2 + 10 %>,
      "title": "<%= slo.name %> 5m Error Ratio",
      "type": "timeseries",
      "targets": [
        {
          "datasource": {
            "type": "prometheus",
            "uid": "${DS_PROMETHEUS}"
          },
          "editorMode": "code",
          "expr": "slo:error_ratio:rate5m{slo=\"<%= slo.name %>\"}",
          "legendFormat": "Error Ratio (5m)",
          "range": true,
          "refId": "A"
        }
      ],
```

**Annotation Tracking Deploy/Config Patterns** (`priv/templates/parapet.gen.grafana/main_dashboard.json.eex`, lines 13-31):
```json
      {
        "datasource": {
          "type": "prometheus",
          "uid": "${DS_PROMETHEUS}"
        },
        "enable": true,
        "expr": "parapet_deploy_info",
        "hide": false,
        "iconColor": "rgb(255, 0, 0)",
        "name": "Deploys",
        "step": "1m",
        "tagKeys": "version",
        "target": {
          "limit": 100,
          "matchAny": false,
          "tags": [],
          "type": "tags"
        },
        "titleFormat": "Deploy: {{version}}",
        "type": "dashboard"
      }
```

### Incident Model for DB Config Events (`lib/parapet/spine/incident.ex`)

**Analog:** `lib/parapet/spine/incident.ex`

**Incident Structure** (`lib/parapet/spine/incident.ex`, lines 10-18):
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
*Note: Config change markers will likely leverage these fields (e.g., `runbook_data` for specific config payloads) directly from the Parapet UI / Integrations since Grafana will query the Postgres data source directly instead of emitting to Prometheus.*
