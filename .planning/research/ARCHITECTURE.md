# Architecture Patterns

**Domain:** SRE / Observability / Incident Management
**Researched:** 2026-05-12

## Recommended Architecture

Parapet implements a **bifurcated data architecture**, separating high-volume telemetry from low-volume operator state.

1. **Telemetry Pipeline (Ephemeral):** `telemetry` events -> `Parapet.Metrics` -> Prometheus/Grafana.
2. **Evidence Spine (Durable):** Webhook/Alert fired -> `Parapet.Ecto.Incident` state machine -> LiveView Operator UI.

### Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `Parapet.Ecto.Incident` | Manages the state machine of an incident (open, investigating, resolved). | Ecto Repo |
| `Parapet.Ecto.TimelineEntry` | Records specific events (alert fired, note added, flag disabled) linked to an Incident. | `Parapet.Ecto.Incident` |
| `Parapet.Ecto.ToolAudit` | Logs AI or human MCP tool calls (e.g., query logs, runbook accessed) for security auditing. | `Parapet.Ecto.Incident` |
| `Parapet.Live` | A Phoenix LiveView router macro providing SRE pages to operators. | `Parapet.Ecto.*`, Host App Auth |
| `Parapet.Integrations.*` | Optional adapters intercepting telemetry from sibling libs (e.g. `Mailglass`, `Rulestead`, `Scoria`) and translating to Parapet SLIs. | Sibling Libraries, `Parapet.Metrics` |

## Patterns to Follow

### Pattern 1: The Sibling Adapter Pattern
**What:** Integrations with sibling libraries (`chimeway`, `mailglass`, `rulestead`, `scoria`) are implemented as optional adapter modules that compile conditionally.
**When:** You need to monitor a sibling library's reliability footprint.
**Example:**
```elixir
defmodule Parapet.Integrations.Mailglass do
  @moduledoc "Translates Mailglass deliverability events into Parapet SLIs."
  
  # Only compiles and attaches if Mailglass is present
  if Code.ensure_loaded?(Mailglass) do
    def attach_handlers do
      :telemetry.attach("parapet-mailglass-monitor", [:mailglass, :delivery, :failed], &handle_delivery_failure/4, nil)
    end
    
    defp handle_delivery_failure(_event, _measurements, meta, _config) do
      # Emit Parapet-standard SLI burn event
      Parapet.Event.emit(:delivery_sl_violation, provider: meta.provider, type: :transactional)
    end
  end
end
```

### Pattern 2: OpenInference to Prometheus Translation
**What:** Scoria emits rich OpenInference OTel spans. Parapet intercepts these and increments low-cardinality Prometheus counters.
**When:** Integrating AI agents into SRE monitoring.
**Example:**
```elixir
# Parapet listens to [:scoria, :span, :stop]
def handle_scoria_span(_event, measurements, meta, _config) do
  # Discard high-cardinality prompt text
  clean_meta = %{model: meta.model_name, tool: meta.tool_name}
  :telemetry.execute([:parapet, :metrics, :llm_token], %{count: measurements.total_tokens}, clean_meta)
end
```

### Pattern 3: Durable Mitigation Auditing
**What:** Every application mutation taken in response to an incident must be durably logged as a `TimelineEntry` and a `ToolAudit`.
**When:** The operator (or AI) disables a feature flag, rollbacks a deploy, or adjusts queue concurrency.
**Example:**
```elixir
# Instead of directly changing Rulestead state:
Parapet.Mitigation.disable_flag(incident_id, actor, :new_checkout_flow)

# Parapet internally handles:
# 1. Auditing the intent.
# 2. Executing the Rulestead change.
# 3. Adding the "Flag Disabled" entry to the Incident Timeline.
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Ecto as a Time-Series Database
**What:** Storing every HTTP request or Oban job start/stop event as a row in an Ecto table.
**Why bad:** High-volume telemetry will rapidly saturate the Ecto connection pool, cause massive database bloat, and degrade main application performance.
**Instead:** Route telemetry to Prometheus/Grafana. Only use Ecto for alerts that explicitly trigger an *Incident*, and the subsequent human/AI *Timeline* actions.

### Anti-Pattern 2: Replacing Grafana in LiveView
**What:** Trying to draw highly interactive, multi-dimensional time-series metrics dashboards in Phoenix LiveView using Chart.js or similar.
**Why bad:** Grafana is purpose-built for this and has a massive ecosystem. Rebuilding it is an infinite time sink with low return.
**Instead:** Embed Grafana links, or provide very simple, static indicators in LiveView (e.g., a green/red "SLO Status" text readout) while reserving LiveView for *actions* and *forms* (like runbooks and mitigation toggles).

## Scalability Considerations

| Concern | At 100 users | At 10K users | At 1M users |
|---------|--------------|--------------|-------------|
| Incident Row Growth | Negligible. | Negligible. Incidents scale with system faults, not users. | Still low. Consider archiving resolved incidents > 1 year old. |
| Timeline Entry Growth | Low. | Low. | Moderate. Archive alongside Incidents. |
| Tool Audit Growth | Low. | Moderate (if heavy AI usage). | High. May require a separate read-replica or data-lake export for compliance. |

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/parapet-engineering-dna-from-sibling-libs.md`
- `.planning/todos/deferred/scoria-ai-integration-seeds.md`
