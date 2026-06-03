# Validation for Phase 5: Built-In Async & Delivery SLOs

## Goals

Guarantee that Phase 5 turns the Phase 4 normalized async/delivery contract into explicit, low-cardinality metric families, provider-backed built-in slice catalogs, and host-owned Prometheus artifacts without introducing hidden activation or noisy alert semantics.

## Requirements Validated

- **DELV-02**: System expands `Mailglass` integration to emit low-cardinality SLIs for outbound submit success, webhook ingest health, suppression drift, and delivery failure classes.
- **DELV-03**: System expands `Chimeway` integration to emit low-cardinality SLIs for provider acceptance, callback-confirmed delivery or failure, and callback delay where the sibling telemetry contract supports it.
- **ASYNC-01**: System expands `Rindle` integration to emit low-cardinality SLIs for queue backlog, queue age, long-running work, discard visibility, and async funnel regressions.
- **ASYNC-02**: System distinguishes retryable async failures from exhausted or discarded work so generated alerts page on user-harming failure instead of normal retry noise.
- **ASYNC-03**: System detects webhook or reconciliation delay separately from internal queue backlog so operators can identify the failing plane without inspecting raw logs first.

## Validation Protocol

### 1. Shared Metrics Foundation Validation

- **Action**: Exercise the shared `Parapet.Metrics.AsyncDelivery` catalog and provider-facing metric tests for Mailglass, Chimeway, and Rindle.
- **Expected Outcome**:
  - shared metric families bind only to the six Phase 4 event families
  - counters use `_total` and delay or duration metrics use `_seconds`
  - backlog and callback freshness remain separate at the metrics layer
  - labels stay bounded to the Phase 4 allowlists

### 2. Provider Catalog Validation

- **Action**: Load the built-in provider modules and inspect their slice catalogs plus registration behavior.
- **Expected Outcome**:
  - `Parapet.SLO.MailglassDelivery`, `Parapet.SLO.ChimewayDelivery`, and `Parapet.SLO.RindleAsync` exist and match the locked Phase 5 catalog
  - `provider_accepted` stays distinct from `delivered`
  - `retryable_failed` stays distinct from `discarded`
  - webhook or callback freshness stays distinct from backlog
  - SLO activation remains explicit through `config :parapet, providers: [...]`

### 3. Generator and Artifact Validation

- **Action**: Run the Prometheus generator tests and validate the generated YAML with `promtool`.
- **Expected Outcome**:
  - `mix parapet.gen.prometheus` reads active providers only
  - generated artifacts stay host-owned and inspectable
  - recording rules and alerts render from the same bounded slice-spec source
  - page, ticket, and diagnostic outputs reflect terminality-aware semantics with noise damping

### 4. Alert Semantics Validation

- **Action**: Review generated alert families for terminality, fault-plane separation, grouping labels, and damping controls.
- **Expected Outcome**:
  - pages target user-harming or terminal states only
  - retry noise does not page by default
  - suppression drift and long-running stage slices remain diagnostic or ticket-grade
  - generated alerts use bounded grouping labels and `for` or similar damping controls

### 5. Compatibility and Documentation Validation

- **Action**: Verify legacy `%Parapet.SLO{}` compatibility still works where intentionally preserved, then review the SLO reference docs.
- **Expected Outcome**:
  - provider-first generation does not silently break legacy resolution paths outside the explicit generator seam
  - docs describe explicit provider registration, active-provider-only generation, and the split artifact layout accurately
  - compilation still succeeds with warnings treated as errors

## Automated Validation Suite

- `mix test test/parapet/metrics/async_delivery_test.exs test/parapet/metrics/mailglass_test.exs test/parapet/metrics/chimeway_test.exs test/parapet/metrics/rindle_test.exs`
- `mix test test/parapet/slo/resolvable_test.exs test/parapet/slo/mailglass_delivery_test.exs test/parapet/slo/chimeway_delivery_test.exs test/parapet/slo/rindle_async_test.exs test/parapet/slo_test.exs`
- `mix test test/parapet/slo/generator_test.exs test/mix/tasks/parapet.gen.prometheus_test.exs`
- `mix compile --warnings-as-errors`
- `promtool check rules priv/parapet/prometheus/recording_rules.yml`
- `promtool check rules priv/parapet/prometheus/alerts.yml`
