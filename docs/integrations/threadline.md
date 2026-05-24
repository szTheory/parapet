# Parapet + Threadline

Threadline is an audit-trail library. The Threadline integration provides audit-evidence interoperability between Threadline and Parapet — it does not emit Prometheus metrics and it does not back any SLO provider.

## Prerequisites

- `threadline` installed in your host app (optional dep — outbound forwarding is guarded by `Code.ensure_loaded?(Threadline)`; inbound ingestion always fires)
- Parapet installed and configured (`mix parapet.install`)

## What it unlocks

The Threadline integration bridges audit evidence in both directions:

**Inbound (always active):** When Threadline fires a `[:threadline, :audit, :event]` telemetry event, Parapet logs it as a `Parapet.Evidence` audit record via `Parapet.Evidence.log_tool_audit/1`. This path is always active once `Parapet.attach(adapters: [:threadline])` is called, regardless of whether the `Threadline` module is loaded.

**Outbound (conditional):** When Parapet creates an audit record and emits `[:parapet, :audit, :created]`, the integration forwards it to `Threadline.log_audit/1` — but only if `Code.ensure_loaded?(Threadline)` returns true. If the host app does not have the Threadline library loaded, the outbound path is skipped silently and the Parapet audit record is still written.

There are no Prometheus metrics and no SLO providers associated with this integration.

## Activation

Add the adapter when you start your supervision tree, typically in `application.ex`:

```elixir
Parapet.attach(adapters: [:threadline])
```

This attaches two telemetry handlers: one for `[:threadline, :audit, :event]` (inbound) and one for `[:parapet, :audit, :created]` (outbound, gated by `Code.ensure_loaded?(Threadline)`).

## Config keys

The Threadline integration has no Parapet-level config keys. Audit event handling is driven entirely by the telemetry payloads and the presence of the `Threadline` module.

## Troubleshooting

### Threadline audit events are arriving but not appearing as Parapet evidence records

Confirm that `Parapet.attach(adapters: [:threadline])` was called before the first `[:threadline, :audit, :event]` telemetry event fired. The inbound handler only catches events that occur after attachment. If the handler was not attached at application startup, events emitted during boot will be missed.

### Parapet audit records are not forwarding to Threadline

The outbound handler is guarded by `Code.ensure_loaded?(Threadline)`. If the `Threadline` module is not available in your app's dependency graph, forwarding is silently skipped. Verify that `threadline` is listed in your `mix.exs` deps and that the module compiles successfully with `mix compile`.

### Telemetry handler raises a conflict error on startup

A duplicate call to `Parapet.attach(adapters: [:threadline])` will raise a telemetry conflict because the handler names `parapet-threadline-audit` and `parapet-audit-to-threadline` are already registered. Attach each adapter exactly once at application startup.
