# Parapet + Chimeway

Chimeway is a notification delivery library. When you attach the Chimeway integration, Parapet translates Chimeway delivery failure events into delivery metrics you can observe in Prometheus and track via pre-built SLO slices.

## Prerequisites

- `chimeway` installed in your host app (optional dep — if it is absent, Chimeway never emits the telemetry events the adapter listens for, so the attached handlers stay dormant and harmless; Parapet does not probe for the `chimeway` library itself)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Chimeway delivery events become Parapet delivery metrics:

- `parapet_delivery_provider_feedback` — counted per `outcome`, `failure_class`, `fault_plane` tags; emitted for provider-side failures
- `parapet_delivery_webhook_ingest` — counted per `delay_bucket` tag; emitted for callback-delayed events where a delay is detected

All events carry `integration: :chimeway`, `provider`, `channel: :notification`, and `outcome: :failed` tags.

The `Parapet.SLO.ChimewayDelivery` provider uses these metrics for three slices: `chimeway_provider_acceptance`, `chimeway_callback_confirmation`, and `chimeway_callback_freshness`. Register it with:

```elixir
config :parapet, providers: [Parapet.SLO.ChimewayDelivery]
```

Then run `mix parapet.gen.prometheus` to generate the alerting rules. See [Parapet SLO Reference](docs/slo-reference.md) for the full slice catalog.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:chimeway])
```

This attaches a telemetry handler for `[:chimeway, :event, :failed]` (handler id `parapet-chimeway-delivery-events`). Parapet routes each event to either `[:parapet, :delivery, :provider_feedback]` or `[:parapet, :delivery, :webhook_ingest]` based on whether a callback delay is detected.

## Config keys

The Chimeway integration has no Parapet-level config keys. It reads standard Chimeway telemetry events and re-emits them as Parapet delivery events without additional configuration.

## Troubleshooting

### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:chimeway])` was called before the first Chimeway event fired, and (2) your `Telemetry.Metrics` reporter includes metrics from the relevant `Parapet.Metrics.*` module. If the reporter is not wired, counters are defined but never scraped.

### Telemetry handler raises a conflict error on startup

A second call to `Parapet.attach(adapters: [:chimeway])` raises a telemetry conflict because the handler name `parapet-chimeway-delivery-events` is already registered. Attach each adapter exactly once at application startup.

### Events appear under provider_feedback instead of webhook_ingest (or vice versa)

Parapet routes Chimeway events based on `callback_delay?/1`. Events where a callback delay is detected (the error is `:callback_timeout` or `"callback_timeout"` and a `delay_ms` integer is present) are emitted as `[:parapet, :delivery, :webhook_ingest]`; all other failures are emitted as `[:parapet, :delivery, :provider_feedback]`. This routing is intentional — confirm your SLO slices are querying the correct event family.
