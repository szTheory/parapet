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
