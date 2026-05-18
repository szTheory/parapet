# Phase 1: OpenTelemetry Trace Exemplars - Validation

**Phase Goal:** Operators can click on an anomalous metric in Grafana or an Incident in the UI and jump directly to the offending trace.

## Goal-Backward Verification

To prove this goal is achieved, the following must be true (from the operator's perspective):

1. **Grafana Metric to Trace:**
   - **Truth:** The operator sees exemplars (trace IDs) embedded directly in the metric graphs in Grafana.
   - **Artifact Required:** A customized `PrometheusFormatter` that appends `# {trace_id="..."}` to the standard OpenMetrics output.
   - **Wiring / Key Link:** Grafana consumes the Prometheus scrape endpoint provided by Parapet, which uses this formatter. The `ExemplarStore` successfully holds the latest trace ID for a given metric/tag combo and the formatter successfully merges this into the scrape output.

2. **Telemetry Ingestion:**
   - **Truth:** When the application handles requests or jobs with a trace context, that trace context is linked to the metrics.
   - **Artifact Required:** `ExemplarTelemetry` wiring and `ExemplarStore`.
   - **Wiring / Key Link:** `[:parapet, :http, :request]` and other relevant telemetry events are intercepted. Their metadata (containing `trace_id`) is stored in `ExemplarStore` by metric series so it's ready when the scrape occurs.

3. **Incident UI to Trace:**
   - **Truth:** The operator views an incident in the UI and sees a "View Trace" button or direct link.
   - **Artifact Required:** The Incident schema/struct includes a `trace_id` field, and the SRE dashboard uses this field to construct the link.
   - **Wiring / Key Link:** The Scoria telemetry translation layer must extract `trace_id` from the incoming events and persist it when creating a durable Incident record in Ecto.

## Acceptance Criteria
- [ ] Automated test verifying `ExemplarStore` correctly bounds memory (replaces old trace IDs for the same tag combo).
- [ ] Automated test verifying `PrometheusFormatter` injects the OpenMetrics exemplar syntax correctly without invalidating the Prometheus payload.
- [ ] Automated test verifying that when a `[:parapet, :http, :request]` event fires, the trace ID is successfully recorded.
- [ ] Incident creation test verifies `trace_id` is durably stored in the database.
