# Parapet + Rulestead

Rulestead is a feature-flag and ruleset management library. When you attach the Rulestead integration, Parapet translates Rulestead ruleset-published events into a flag-change counter you can observe in Prometheus.

## Prerequisites

- `rulestead` installed in your host app (optional dep — Parapet detects it via `Code.ensure_loaded?`)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Rulestead ruleset-published events become the `parapet_rulestead_flag_change_total` counter, tagged by `flag_name` and `ruleset`. Each time Rulestead publishes a ruleset, the integration re-emits `[:parapet, :rulestead, :flag_change]` and stores a `SystemEvent` record in the Parapet evidence spine.

**Reporter wiring required (OQ-3):** The integration wires the telemetry event handler, but it does not register the metric definition with your `Telemetry.Metrics` reporter. To get `parapet_rulestead_flag_change_total` into Prometheus, you must include `Parapet.Metrics.Rulestead.metrics()` in your host app's reporter config:

```elixir
# In your Telemetry reporter setup (e.g., TelemetryMetricsPrometheus or similar)
metrics: Parapet.Metrics.Rulestead.metrics() ++ your_other_metrics()
```

Without this step, the telemetry handler fires and the evidence record is written, but the counter never reaches your scrape endpoint.

There is no pre-built SLO provider for Rulestead flag changes. The counter is the raw ingredient for a custom slice you can author via the [SLO authoring guide](docs/slo-authoring-guide.md).

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:rulestead])
```

This attaches a telemetry handler for `[:rulestead, :admin, :ruleset, :published]`. When the handler fires, it writes a `SystemEvent` record and re-emits `[:parapet, :rulestead, :flag_change]`.

## Config keys

The Rulestead integration reads `Application.get_env(:parapet, :repo)` to determine which Ecto repo to use when writing `SystemEvent` records. This must be set as part of the standard Parapet install. If `:repo` is not configured, the integration silently skips the evidence write but still re-emits the telemetry event.

## Troubleshooting

### The parapet_rulestead_flag_change_total counter does not appear in Prometheus

The most common cause is missing reporter wiring. Confirm that `Parapet.Metrics.Rulestead.metrics()` is included in your `Telemetry.Metrics` reporter configuration. The integration only attaches the telemetry handler — the metric definition must be registered separately with the reporter before scraping begins.

### Flag-change events fire but no SystemEvent rows appear in the database

The integration reads `Application.get_env(:parapet, :repo)` at event time. If `:repo` is `nil` (not configured), the DB insert is skipped and only the telemetry re-emit occurs. Verify that `config :parapet, repo: MyApp.Repo` is set in your application config.

### Telemetry handler raises a conflict error on startup

A duplicate call to `Parapet.attach(adapters: [:rulestead])` will raise a telemetry conflict because the handler name `parapet-rulestead-telemetry` is already registered. Attach each adapter exactly once at application startup.
