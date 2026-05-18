# Phase 1: OpenTelemetry Trace Exemplars - Architectural Decisions

Based on the SRE observability research, project engineering DNA, and Elixir community best practices, here is the cohesive, one-shot recommendation for implementing Phase 1. 

## 1. OTel Dependency: Optional `:opentelemetry_api`
**Decision:** Add `{:opentelemetry_api, "~> 1.3", optional: true}` to `mix.exs` and use explicit compiler checks (`Code.ensure_loaded?(:opentelemetry)`) rather than poking at undocumented process dictionary keys (`:erlang.get/1`).

**Rationale:**
* **Safety & Correctness:** The OTel process dictionary shape is internal implementation detail and subject to change. Using the official API guarantees compatibility.
* **Dependency Footprint:** The `_api` package is extremely lightweight (no runtime cost, just macros/stubs). Making it `optional: true` means zero footprint for users who don't care about tracing, but full type-safety and macro support for those who do.
* **Ergonomics:** It allows us to provide a clean `Parapet.Evidence.get_trace_context/0` helper that safely returns `%{trace_id: ..., span_id: ...}` if tracing is active, or `nil` if not.

## 2. Prometheus Exemplars: Parapet-Provided Exporter Helpers
**Decision:** Do not build a custom Prometheus exporter, but **do** provide opinionated `Telemetry.Metrics` definitions with exemplar extraction pre-wired for standard backends. 

**Rationale:**
* **Opinionated Paved Road:** The research dictates that Parapet's value is in providing the "boring correct pieces." Forcing the host app developer to manually figure out how to write `keep: &my_extractor/1` functions for exemplars is a failure of DX.
* **Implementation:** We will update `Parapet.Metrics.HTTP` (and others) to accept an option like `exemplars: true`. When true, the generated `Telemetry.Metrics.distribution` will include the necessary `keep` and `tags` callbacks to pull the `trace_id` out of the telemetry event metadata.
* **Interoperability:** This approach remains backend-agnostic but perfectly aligns with `telemetry_metrics_prometheus_core` and `peep` out of the box.

## 3. UI Trace Links: Static Config Template
**Decision:** Use a simple `config :parapet, trace_url_template: "..."` with `{trace_id}` placeholder interpolation.

**Rationale:**
* **Principle of Least Surprise:** 99% of trace backends (Tempo, Jaeger, Honeycomb, Datadog) support deep linking via a predictable URL structure. 
* **Ergonomics:** An MFA callback is over-engineering for string interpolation. A config string is instantly understandable.
* **Host Ownership:** Because the Operator UI is generated into the host app (`priv/templates/parapet.gen.ui/operator_detail_live.ex.eex`), the developer can trivially replace the template logic with their own custom Phoenix function if they have an exotic requirement.

## 4. Incident Schema: Explicit `trace_id` Field
**Decision:** Add a first-class `field :trace_id, :string` to the `Parapet.Spine.Incident` schema and generate a migration for it.

**Rationale:**
* **Evidence-First Design:** The research emphasizes that "Traces show causal paths." A trace is a primary piece of evidence for an SRE investigation, equal in importance to the `correlation_key`. 
* **Database Ergonomics:** Storing `trace_id` inside an unstructured `runbook_data` JSONB map prevents efficient indexing and makes reverse lookups (e.g., "Find the incident for this trace ID") slow and complex.
* **Parapet DNA:** Parapet owns the durable spine. Adding a migration to `priv/repo/migrations/` is the standard, idiomatic way to handle schema evolution in Ecto.