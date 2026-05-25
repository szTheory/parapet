# Parapet + Scoria

Scoria is an AI/LLM tooling library with support for evals, MCP tool execution, and durable workflows. When you attach the Scoria integration, Parapet translates Scoria telemetry into Prometheus metrics and feeds the evidence spine with incidents and action items for AI config changes and stale workflows.

## Prerequisites

- `scoria` installed in your host app (optional dep — if it is absent, Scoria never emits the telemetry events the adapter listens for, so the attached handlers stay dormant and harmless; Parapet does not probe for the `scoria` library itself)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Scoria AI/LLM events feed Parapet in two ways:

**Prometheus metrics** (via `Parapet.Metrics.Scoria`):

- `scoria_evaluation_total` — eval completion counter, tagged by `guardrail`, `passed`, `model_name`
- `scoria_mcp_errors_total` — MCP tool error counter, tagged by `reason`, `tool_name`

**Evidence spine integration** (unique to Scoria):

- Config-deployed events (`[:scoria, :config, :deployed]`) create `Parapet.Evidence` incident records with runbook data capturing `scorer_version`, `baseline_version`, and `model`
- Stale workflow events create action items; resumed workflows resolve them automatically when the workflow is no longer paused
- SRE telemetry errors create high-severity incidents for immediate operator visibility

**Reporter wiring required:** The integration attaches telemetry handlers automatically, but the Prometheus metric definitions must be registered separately with your `Telemetry.Metrics` reporter. To get `scoria_evaluation_total` and `scoria_mcp_errors_total` into Prometheus, add:

```elixir
# In your Telemetry reporter setup (e.g., TelemetryMetricsPrometheus or similar)
metrics: Parapet.Metrics.Scoria.metrics() ++ your_other_metrics()
```

Without this step, the telemetry handlers fire and evidence records are written, but the counters never reach your scrape endpoint.

There is no pre-built SLO provider for Scoria. The evaluation and MCP error counters are raw ingredients for custom slices — see the [SLO authoring guide](docs/slo-authoring-guide.md) for how to build your own slices from these counters.

The `[:parapet, :scoria, …]` events follow the same additive-only stability rules as all other Parapet telemetry events — see the [telemetry contract](docs/telemetry.md) for details.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:scoria])
```

This attaches handlers for seven Scoria events across five handler IDs:

- `[:scoria, :sre, :telemetry]` — handler id `parapet-scoria-telemetry`
- `[:scoria, :config, :deployed]` — handler id `parapet-scoria-config-telemetry`
- `[:scoria, :mcp, :tool, :exception]` — handler id `parapet-scoria-mcp-telemetry`
- `[:scoria, :workflow, :stale]`, `[:scoria, :workflow, :expired]`, `[:scoria, :workflow, :resumed]` — handler id `parapet-scoria-workflow-telemetry`
- `[:scoria, :eval, :completed]` — handler id `parapet-scoria-eval-handler` (via `Parapet.Metrics.Scoria.setup/0`)

## Config keys

The Scoria integration has no Parapet-level config keys. It uses `Code.ensure_loaded?/1` at runtime to check for `Scoria.Workflow` when resolving workflow state — no static configuration is required.

## Troubleshooting

### Metrics are not appearing in Prometheus

The most common cause is missing reporter wiring. Confirm that `Parapet.Metrics.Scoria.metrics()` is included in your `Telemetry.Metrics` reporter configuration. The integration only attaches the telemetry handlers — the metric definitions must be registered separately with the reporter before scraping begins.

### Telemetry handler raises a conflict error on startup

The Scoria integration registers five separate handler IDs. A duplicate call to `Parapet.attach(adapters: [:scoria])` will raise a telemetry conflict because one or more of `parapet-scoria-telemetry`, `parapet-scoria-config-telemetry`, `parapet-scoria-mcp-telemetry`, `parapet-scoria-workflow-telemetry`, or `parapet-scoria-eval-handler` is already registered. Attach each adapter exactly once at application startup.

### High-cardinality metadata from Scoria is being dropped

This is intentional. Parapet strictly enforces low-cardinality labels by keeping only `[:model, :provider, :tool_name]` from incoming Scoria metadata. Fields such as `trace_id`, `request_id`, or other high-cardinality identifiers are stripped before the translated event is emitted. This protects your TSDB from cardinality explosion. If you need to correlate specific events, use the `Parapet.Evidence` incident and action item records — those capture the full metadata in Ecto rather than in Prometheus label space.
