# Parapet + Sigra

Sigra is a Phoenix authentication library. When you attach the Sigra integration, Parapet translates Sigra login and signup telemetry into journey metrics and feeds the WebSaaS login-journey SLO slice with real signal.

## Prerequisites

- `sigra` installed in your host app (optional dep — Parapet detects it via `Code.ensure_loaded?`)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Sigra login and signup events become Parapet journey metrics:

- `parapet_journey_login_count` — counted per `outcome` tag (`success` or `failure`)
- `parapet_journey_signup_count` — counted per `outcome` and `provider` tags

The `web_saas_login_journey` slice in `Parapet.SLO.StarterPack.WebSaaS` relies on `parapet_journey_login_count` as its error-ratio source. Without Sigra (or another emitter of `[:parapet, :journey, :login]`), that slice has no data. The `min_total_rate` guard prevents false-positive alerts during low-traffic windows, but no data is not the same as green.

If you have not yet registered the WebSaaS provider, see [Getting started](docs/getting-started.md) for the full cold-start sequence and [SLO reference](docs/slo-reference.md) for the provider catalog.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:sigra])
```

This attaches telemetry handlers for `[:sigra, :auth, :login, :stop]`, `[:sigra, :auth, :login, :exception]`, `[:sigra, :auth, :signup, :stop]`, and `[:sigra, :auth, :signup, :exception]`.

## Config keys

The Sigra integration has no Parapet-level config keys. It reads standard Sigra telemetry events and re-emits them as Parapet journey events without additional configuration.

## Troubleshooting

### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:sigra])` was called before the first Sigra event fired, and (2) your `Telemetry.Metrics` reporter includes the metrics from `Parapet.Metrics.Sigra.metrics()`. If the reporter is not wired, the counters are defined but never scraped.

### The login-journey slice shows no data, not a healthy rate

The `web_saas_login_journey` slice needs `parapet_journey_login_count` to compute an error ratio. If no login events have fired since the last restart, the recording rule returns no series. This is distinct from a zero error rate — add a synthetic probe via `Parapet.Metrics.Probe` if you want a floor signal during low-traffic periods.

### Telemetry handler raises a conflict error on startup

If a previous call to `Parapet.attach(adapters: [:sigra])` already attached the handler with the same name (`parapet-sigra-auth`), a second call raises a telemetry conflict. Attach each adapter exactly once, typically at application startup rather than inside a request handler.
