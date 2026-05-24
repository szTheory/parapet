# Parapet + Accrue

Accrue is a billing and subscription library. When you attach the Accrue integration, Parapet translates Accrue checkout and webhook telemetry into billing journey metrics you can use as the foundation for a custom SLO.

## Prerequisites

- `accrue` installed in your host app (optional dep — Parapet detects it via `Code.ensure_loaded?`)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Accrue billing events become Parapet journey metrics:

- `parapet_journey_billing_checkout_count` — counted per `outcome` and `plan` tags
- `parapet_journey_billing_webhook_duration` — distribution per `outcome` and `event_type` tags

There is no pre-built SLO provider for Accrue billing journeys. These metrics are the foundation for a custom slice you author yourself. See [SLO authoring guide](docs/slo-authoring-guide.md) for the journey-slicing decision tree and the exact `SliceSpec` shape.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:accrue])
```

This attaches telemetry handlers for `[:accrue, :billing, :processed]`, `[:accrue, :billing, :failed]`, `[:accrue, :billing, :checkout, :stop]`, `[:accrue, :billing, :checkout, :exception]`, `[:accrue, :billing, :webhook, :stop]`, and `[:accrue, :billing, :webhook, :exception]`.

## Config keys

The Accrue integration has no Parapet-level config keys. It reads standard Accrue telemetry events and re-emits them as Parapet journey events without additional configuration.

## Troubleshooting

### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:accrue])` was called before the first Accrue event fired, and (2) your `Telemetry.Metrics` reporter includes the metrics from `Parapet.Metrics.Accrue.metrics()`. Without the reporter wiring, the counters and distributions are defined but never scraped.

### Checkout events arrive but no billing metrics appear

The checkout handler listens on `[:accrue, :billing, :checkout, :stop]` and `[:accrue, :billing, :checkout, :exception]`. If Accrue emits events under a different name or version, the handler is silently skipped. Check `Accrue` telemetry docs to confirm the event name matches.

### I want a burn-rate alert on the checkout success rate

Accrue metrics are the raw ingredient, not a pre-wired alert. You need to define a `Parapet.SLO.Provider` module with a `SliceSpec` that references `parapet_journey_billing_checkout_count` as its source metric, then register it in `config :parapet, providers: [...]`. The [SLO authoring guide](docs/slo-authoring-guide.md) walks through the full process.
