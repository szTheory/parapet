# Phase 01: OpenTelemetry Trace Exemplars
## Plan 01-02 Complete

**Tasks completed:**
1. Created `Parapet.Metrics.ExemplarStore` to hold the latest trace_id associated with a specific telemetry event context in memory.
2. Created `Parapet.Metrics.ExemplarTelemetry` to attach telemetry handlers to relevant events and route trace IDs to ExemplarStore.
3. Created `Parapet.Metrics.PrometheusFormatter` to fetch the base text from telemetry_metrics_prometheus_core, lookup matching trace IDs from ExemplarStore, and append OpenMetrics exemplars.

All tests are passing successfully. The Prometheus endpoint now provides OpenMetrics exemplars linking metrics back to traces without causing cardinality explosions.