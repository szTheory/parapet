# Parapet + Mailglass

Mailglass is an email delivery library. When you attach the Mailglass integration, Parapet translates Mailglass send, reconcile, and webhook events into delivery metrics across three event families you can observe in Prometheus and track via pre-built SLO slices.

## Prerequisites

- `mailglass` installed in your host app (optional dep — if it is absent, Mailglass never emits the telemetry events the adapter listens for, so the attached handlers stay dormant and harmless; Parapet does not probe for the `mailglass` library itself)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Mailglass email events become Parapet delivery metrics across three event families:

- `parapet_delivery_outbound` — send-stop events, tagged by `outcome`, `fault_plane`
- `parapet_delivery_provider_feedback` — reconcile-stop events, tagged by `outcome`, `delay_bucket`
- `parapet_delivery_webhook_ingest` — webhook exception events, tagged by `failure_class`, `fault_plane`

All events carry `integration: :mailglass`, `provider`, and `channel: :email` tags. Optional ref tags included when present: `message_id`, `delivery_id`, `provider_message_id`.

The `Parapet.SLO.MailglassDelivery` provider uses these metrics for four slices: `mailglass_submit_acceptance`, `mailglass_confirmed_delivery`, `mailglass_webhook_freshness`, and `mailglass_suppression_drift`. Register it with:

```elixir
config :parapet, providers: [Parapet.SLO.MailglassDelivery]
```

Then run `mix parapet.gen.prometheus` to generate the alerting rules. See [Parapet SLO Reference](docs/slo-reference.md) for the full slice catalog.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:mailglass])
```

This attaches handlers (via `:telemetry.attach_many/4`) for `[:mailglass, :outbound, :send, :stop]`, `[:mailglass, :reconcile, :stop]`, and `[:mailglass, :webhook, :ingest, :exception]` (handler id `parapet-mailglass-delivery`).

## Config keys

The Mailglass integration has no Parapet-level config keys. It reads standard Mailglass telemetry events and re-emits them as Parapet delivery events without additional configuration.

## Troubleshooting

### Metrics are not appearing in Prometheus

Confirm two things: (1) `Parapet.attach(adapters: [:mailglass])` was called before the first Mailglass event fired, and (2) your `Telemetry.Metrics` reporter includes metrics from the relevant `Parapet.Metrics.*` module. If the reporter is not wired, counters are defined but never scraped.

### Telemetry handler raises a conflict error on startup

A second call to `Parapet.attach(adapters: [:mailglass])` raises a telemetry conflict because the handler name `parapet-mailglass-delivery` is already registered. Attach each adapter exactly once at application startup.

### The webhook_ingest events include a latency_ms field that is not in other families

Webhook exception events carry a `latency_ms` field in Mailglass metadata representing the end-to-end delivery latency observed at webhook receipt. Parapet maps this to a `delay_bucket` tag and also preserves it as a `delay_ms` measurement key on the emitted event. Use the `delay_bucket` tag for SLO slices and the `delay_ms` measurement for histogram-based alerting.
