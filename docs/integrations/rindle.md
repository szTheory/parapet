# Parapet + Rindle

Rindle is a media processing library. When you attach the Rindle integration, Parapet translates all seven Rindle async lifecycle events into three async metric families you can observe in Prometheus and track via pre-built SLO slices.

## Prerequisites

- `rindle` installed in your host app (optional dep — if it is absent, Rindle never emits the telemetry events the adapter listens for, so the attached handlers stay dormant and harmless; Parapet does not probe for the `rindle` library itself)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

Rindle media-processing events become Parapet async metrics across three event families:

- `parapet_async_stage` — from `started`, `processed`, `failed`, and `discarded` events; tagged by `pipeline_stage`, `outcome`, `retry_state`, `fault_plane`
- `parapet_async_backlog` — from `backlog` events; tagged by `outcome`, `delay_bucket`, `fault_plane`
- `parapet_async_callback` — from `callback_delayed` and `reconciliation_delayed` events; tagged by `pipeline_stage`, `outcome`, `delay_bucket`, `fault_plane`

All events carry `integration: :rindle`, `provider`, and `queue` tags. Optional refs included when present: `job_id`, `webhook_id`.

The `Parapet.SLO.RindleAsync` provider uses these metrics for five slices: `rindle_terminal_success`, `rindle_queue_freshness`, `rindle_callback_freshness`, `rindle_long_running_stage`, and `rindle_funnel_regression`. Register it with:

```elixir
config :parapet, providers: [Parapet.SLO.RindleAsync]
```

Then run `mix parapet.gen.prometheus` to generate the alerting rules. See [Parapet SLO Reference](docs/slo-reference.md) for the full slice catalog.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:rindle])
```

This attaches handlers for all seven Rindle events (handler id `parapet-rindle-async`):
`[:rindle, :media, :started]`, `[:rindle, :media, :processed]`, `[:rindle, :media, :failed]`,
`[:rindle, :media, :discarded]`, `[:rindle, :media, :backlog]`,
`[:rindle, :media, :callback_delayed]`, and `[:rindle, :media, :reconciliation_delayed]`.

## Config keys

The Rindle integration has no Parapet-level config keys. It reads standard Rindle telemetry events and re-emits them as Parapet async events without additional configuration.

## Troubleshooting

### Telemetry handler raises a conflict error on startup

A second call to `Parapet.attach(adapters: [:rindle])` raises a telemetry conflict because the handler name `parapet-rindle-async` is already registered. Attach each adapter exactly once at application startup.

### The pipeline_stage tag shows unexpected values

Parapet normalizes `pipeline_stage` from string to atom at event time: strings are lowercased, trimmed, and non-alphanumeric characters are replaced with underscores before `String.to_atom/1` is called. If your Rindle metadata passes stage as a string like `"Media Processing"`, Parapet normalizes it to `:media_processing`. If you need a specific atom key in SLO slices, ensure Rindle metadata passes stage as the expected atom directly, or align your slice filter to the normalized form.

### The retry_state tag shows :first_attempt when a retry is expected

Parapet infers `retry_state` from the `attempt` or `attempt_number` integer keys in Rindle metadata when no explicit `retry_state` key is present. If the metadata does not include either key, or the value is `1` (first attempt), Parapet sets `retry_state: :first_attempt`. For events at attempt `> 1`, the tag becomes `:retrying`. If your Rindle metadata uses a different key for the attempt counter, Parapet will not pick it up automatically — set `retry_state` explicitly in your Rindle job metadata to guarantee the correct label.
