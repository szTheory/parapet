# Deferred Items for Phase 3

- **Pre-existing Warning**: `lib/parapet/metrics/prometheus_formatter.ex:11:54: Parapet.Metrics.PrometheusFormatter.scrape/0` raises `warning: :telemetry_metrics_prometheus_core.scrape/0 is undefined`. This was causing `mix compile --warnings-as-errors` to fail, but it is unrelated to the current task.