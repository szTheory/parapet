<user_constraints>
## User Constraints (from Prompt)

### Locked Decisions
- Implement OTel trace_id extraction from telemetry events and the process dictionary.
- Append trace_ids as Prometheus exemplars in metric output.
- Store trace_id on Incident schemas and surface dynamic trace links in the Operator UI.

### the agent's Discretion
- Approach to append exemplars in Prometheus metric output (custom formatting vs `:telemetry_metrics_prometheus_core` capability).
- Method for updating the Ecto schema and LiveView components securely and cleanly.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OTL-01.1 | OTel trace_id extraction from telemetry events | Elixir `:opentelemetry_api` exposes `OpenTelemetry.Tracer.current_span_ctx/0`. |
| OTL-01.2 | Append trace_ids as Prometheus exemplars | `telemetry_metrics_prometheus_core` doesn't natively support OpenMetrics exemplars. Custom formatting or side-car ETS table is required. |
| OTL-01.3 | Store trace_id on durable Incident records | Add `:trace_id` column to `Parapet.Spine.Incident` and update LiveViews with config-driven URL template. |
</phase_requirements>

# Phase 1: OpenTelemetry Trace Exemplars - Research

**Researched:** 2024-05-16
**Domain:** Elixir Observability, OpenTelemetry, Prometheus OpenMetrics format
**Confidence:** HIGH

## Summary

The goal of this phase is to seamlessly bridge Parapet's high-level SLO monitoring with deep-dive distributed traces. Operators should be able to click directly from an anomalous request metric or an Incident dashboard straight into their tracing backend (Jaeger, Honeycomb, Tempo). 

Our research confirms that while extracting the `trace_id` from OpenTelemetry in Elixir is straightforward via `:opentelemetry_api`, the standard Elixir Prometheus reporters (specifically `:telemetry_metrics_prometheus_core`) **do not natively support OpenMetrics exemplars**. Therefore, Parapet will need to provide a custom text formatter or a side-channel handler to safely append exemplars to the `/metrics` scrape output without causing cardinality explosions by mistakenly adding them as Prometheus labels.

**Primary recommendation:** Use `{:opentelemetry_api, "~> 1.3", optional: true}` to safely extract `trace_id`. Create a dedicated telemetry handler to capture recent trace IDs per metric, and use custom string formatting over the base Prometheus text output to append the exemplars. Update the `Parapet.Spine.Incident` schema explicitly with a `trace_id` string field.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Trace ID Extraction | API / Backend | — | Must be pulled from Erlang process dictionary via OTel API at the moment the telemetry event fires. |
| Exemplar Formatting | API / Backend | — | Must be formatted as OpenMetrics `# {trace_id="..."} value timestamp` during the Prometheus HTTP scrape. |
| Trace Linking | Frontend Server | — | `operator_detail_live.ex` interpolates the `trace_id` into a configurable backend URL. |
| Durable Storage | Database / Storage | — | `parapet_incidents` needs a schema migration to add `trace_id`. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:opentelemetry_api` | `~> 1.3` | Trace Context Extraction | Official OTel Erlang/Elixir API. Adding it as `optional: true` ensures users without tracing aren't penalized, but allows safe macro/API usage when present. |
| `:telemetry_metrics_prometheus_core` | `~> 1.2` | Base Metrics | Standard Elixir metrics aggregator. Parapet will wrap its output to inject exemplars. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Formatting | Wait for `PromEx` / `Peep` exemplar support | Waiting blocks the v0.6 milestone. Custom text manipulation of the scrape output is lightweight and completely under Parapet's control. |
| `:erlang.get/1` | `:opentelemetry_api` | Raw process dictionary access is brittle and violates OTel internal encapsulation. The API is safer. |

**Installation:**
```bash
# In mix.exs
{:opentelemetry_api, "~> 1.3", optional: true}
```

## Architecture Patterns

### Pattern 1: Safe OTel Trace Extraction
**What:** Safely checking for tracing without forcing a hard dependency.
**When to use:** Inside `Parapet.Plug.Metrics` or general telemetry event emitters.
**Example:**
```elixir
defp get_trace_id do
  if Code.ensure_loaded?(:opentelemetry) and function_exported?(OpenTelemetry.Tracer, :current_span_ctx, 0) do
    span_ctx = OpenTelemetry.Tracer.current_span_ctx()
    if span_ctx != :undefined do
      OpenTelemetry.Span.hex_trace_id(span_ctx)
    end
  end
rescue
  _ -> nil
end
```

### Pattern 2: OpenMetrics Custom Formatting (Exemplars)
**What:** Modifying standard Prometheus output to include exemplars.
**When to use:** When exposing `/metrics` in the host app.
**Example:**
Exemplars are strictly formatted in OpenMetrics. They must be placed at the end of a metric line, before the timestamp.
```text
http_request_duration_seconds_bucket{le="0.1",route="/api"} 1 # {trace_id="abc-123"} 0.05 1620000000
```
Parapet should provide a `Parapet.Metrics.PrometheusFormatter.scrape/0` that:
1. Calls the underlying `:telemetry_metrics_prometheus_core.scrape/0`.
2. Uses regex or string splitting to find bucket/counter lines.
3. Appends `# {trace_id="XYZ"}` based on a temporary in-memory ring buffer (ETS/Agent) that caught the latest `trace_id` for that specific series.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metric Aggregation | A full custom Prometheus Exporter | `:telemetry_metrics_prometheus_core` + Regex post-processing | Aggregation math (histograms, quantiles) is complex and bug-prone. Let the core library aggregate, and only hand-roll the string formatting to append the exemplar. |
| Trace URL Routing | A complex router MFA callback | Config String Template | `config :parapet, trace_url: "https://jaeger.local/trace/{trace_id}"` is vastly easier to configure than defining an Elixir function callback in config. |

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `parapet_incidents` Ecto table | Create database migration to add `trace_id` (string/varchar). |
| Live service config | None — verified by codebase review | None |
| OS-registered state | None — verified by codebase review | None |
| Secrets/env vars | None — verified by codebase review | None |
| Build artifacts | None — verified by codebase review | None |

## Common Pitfalls

### Pitfall 1: Cardinality Explosion via Tags
**What goes wrong:** Adding `trace_id` to `:telemetry` tags or Prometheus labels.
**Why it happens:** Developers assume "I want to see the trace ID, I'll just add it as a label." This creates a new time-series for every single request, instantly crashing the Prometheus server or causing OOM in the Elixir ETS table.
**How to avoid:** *Never* include `trace_id` in the `tags` list of `Telemetry.Metrics`. It must strictly be extracted into a separate exemplar store and appended only as an OpenMetrics comment (`# {trace_id="..."}`).

### Pitfall 2: `undefined` Span Context
**What goes wrong:** Calling `OpenTelemetry.Span.hex_trace_id(:undefined)` crashes the process.
**Why it happens:** If no trace is active (e.g., standard background job without tracing, or ignored route), `current_span_ctx()` returns the atom `:undefined` in Erlang, not `nil` or a struct.
**How to avoid:** Always explicitly pattern match or check `span_ctx != :undefined` before passing it to `hex_trace_id/1`.

## Code Examples

### Incident Schema Update
```elixir
# lib/parapet/spine/incident.ex
schema "parapet_incidents" do
  field(:title, :string)
  field(:description, :string)
  field(:state, :string, default: "open")
  field(:correlation_key, :string)
  field(:trace_id, :string) # NEW
  field(:runbook_data, :map)

  timestamps(type: :utc_datetime_usec)
end

def changeset(incident, attrs) do
  incident
  |> cast(attrs, [:title, :description, :state, :correlation_key, :trace_id, :runbook_data])
  # ...
end
```

### Operator UI Template Update
```elixir
# priv/templates/parapet.gen.ui/operator_detail_live.ex.eex
<%= if @incident.trace_id do %>
  <div class="mt-4">
    <strong>Trace:</strong>
    <a href={String.replace(Application.get_env(:parapet, :trace_url_template, "#"), "{trace_id}", @incident.trace_id)} target="_blank" class="text-blue-500 hover:underline">
      <%= @incident.trace_id %>
    </a>
  </div>
<% end %>
```

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OTL-01.1 | Extracts OTel trace_id safely | unit | `mix test test/parapet/plug/metrics_test.exs` | ✅ Wave 0 |
| OTL-01.2 | Appends exemplars to Prom output | unit | `mix test test/parapet/mcp/prometheus_client_test.exs` | ✅ Wave 0 |
| OTL-01.3 | Incident schema accepts trace_id | unit | `mix test test/parapet/spine/incident_test.exs` | ✅ Wave 0 |

## Sources

### Primary (HIGH confidence)
- Erlang `opentelemetry_api` GitHub Repository - Verified `otel_tracer:current_span_ctx()` and `otel_span:hex_trace_id/1` behavior and `:undefined` returns.
- OpenMetrics Specification - Verified exemplar syntax (`# {trace_id="..."}`).

### Secondary (MEDIUM confidence)
- Elixir Forum discussions - Confirmed `telemetry_metrics_prometheus_core` does not support exemplars out of the box, requiring custom text formatting for the scrape endpoint.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - `opentelemetry_api` is the definitive Erlang/Elixir library.
- Architecture: HIGH - Custom formatting is the only immediate path forward without rewriting an entire TSDB aggregator in Elixir.
- Pitfalls: HIGH - Cardinality explosion is a widely documented PromQL anti-pattern.

**Research date:** 2024-05-16
**Valid until:** 2024-08-16
