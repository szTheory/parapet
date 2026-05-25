# Parapet SLO Reference

Parapet now has two SLO paths:

1. Legacy `%Parapet.SLO{}` definitions for existing custom slices.
2. Provider-owned Phase 5 slice specs for built-in async and delivery reliability.

The blessed path for built-ins is explicit provider registration plus host-owned generated Prometheus files.

## Phase 5 Provider Registration

Register built-in providers through application config:

```elixir
config :parapet,
  providers: [
    Parapet.SLO.MailglassDelivery,
    Parapet.SLO.ChimewayDelivery,
    Parapet.SLO.RindleAsync
  ]
```

`Parapet.attach(adapters: [...])` only enables telemetry adapters. It does not auto-register SLO providers or silently generate alerts.

## Built-In Provider Modules

- `Parapet.SLO.MailglassDelivery`
  - `mailglass_submit_acceptance`
  - `mailglass_confirmed_delivery`
  - `mailglass_webhook_freshness`
  - `mailglass_suppression_drift`
- `Parapet.SLO.ChimewayDelivery`
  - `chimeway_provider_acceptance`
  - `chimeway_callback_confirmation`
  - `chimeway_callback_freshness`
- `Parapet.SLO.RindleAsync`
  - `rindle_terminal_success`
  - `rindle_queue_freshness`
  - `rindle_callback_freshness`
  - `rindle_long_running_stage`
  - `rindle_funnel_regression`

These providers return bounded `Parapet.SLO.SliceSpec` structs. The generator owns the PromQL shape so built-ins stay low-cardinality and symptom-first.

## Starter Packs

Starter packs are opinionated, one-line SLO bundles for common application shapes. They are provider modules like any other — register them in `config :parapet, providers: [...]` and run `mix parapet.gen.prometheus`. Each slice is pinned to a real emitted Prometheus series, ships a documented default objective in human terms, and is overridable.

- `Parapet.SLO.StarterPack.WebSaaS` — first-SLO pack for Phoenix SaaS teams (three slices):
  - `web_saas_http_availability` — source `parapet_http_request_count`, 99.5% objective, `:ticket` alert class
  - `web_saas_login_journey` — source `parapet_journey_login_count`, 99.9% objective, `:page` alert class
  - `web_saas_oban_job_success` — source `parapet_oban_jobs_total`, 99.0% objective, `:ticket` alert class
- `Parapet.SLO.StarterPack.DeliverySaaS` — extends WebSaaS for delivery-sending teams. Composes the three WebSaaS slices above with the `Parapet.SLO.MailglassDelivery` and `Parapet.SLO.ChimewayDelivery` catalogs. Delivery slices register **only when the corresponding host library is loaded** (guarded by `Code.ensure_loaded?(Mailglass)` / `Code.ensure_loaded?(Chimeway)`), so the pack compiles out cleanly to just the three WebSaaS slices when delivery providers are absent. See the [Provider-as-bundle pattern](docs/slo-authoring-guide.md#provider-as-bundle-pattern) in the SLO authoring guide for how to build your own bundle provider.

All starter-pack slices use the default `min_total_rate: 0.01` denominator guard. See the [SLO authoring guide](docs/slo-authoring-guide.md) for how to read, anchor on, and override these defaults.

## Generated Artifacts

Run:

```bash
mix parapet.gen.prometheus
```

This task reads active providers only and writes:

- `priv/parapet/prometheus/recording_rules.yml`
- `priv/parapet/prometheus/alerts.yml`
- `priv/parapet/prometheus/rules.yml`

`rules.yml` is the compatibility aggregate. The split `recording_rules.yml` and `alerts.yml` files are the preferred host-owned path.

## Legacy Compatibility

`Parapet.SLO.define/2` and legacy `%Parapet.SLO{}` values still work, but they are compatibility surfaces. New async and delivery slices should be implemented as provider modules instead of mutating the `:slos` application env at runtime.

## Runbooks And Severity

Runbooks remain mandatory. Every generated alert carries a runbook URL and a bounded severity:

- `page` for terminal or clearly user-harming symptoms
- `ticket` for sustained but less urgent degradation
- `warning` for early or lower-confidence regressions

Phase 5 also keeps retry noise and freshness failures separate. Queue backlog, callback delay, suppression drift, and terminal discard are different operator symptoms and generate different slices.
