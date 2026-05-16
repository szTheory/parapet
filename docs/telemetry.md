# Telemetry Event Schema

The Parapet library emits telemetry events to provide deep observability into your Phoenix applications.

## Versioning Contract

The telemetry event schema version is tied to the package version. Renaming or removing measurement or metadata fields constitutes a semver-major breaking change. Adding new metadata fields or measurements may be done in minor versions.

## Events

### `[:parapet, :probe, :run, :stop]`
Emitted when a synthetic probe successfully completes its execution.

**Measurements:**
- `duration_ms` (integer) - The duration of the probe execution in milliseconds.

**Metadata:**
- `probe` (string) - The module name of the probe (e.g. `"MyApp.Probes.Checkout"`).
- `status` (string) - `"success"` or `"error"`.

### `[:parapet, :probe, :run, :exception]`
Emitted when a synthetic probe raises an exception during execution.

**Measurements:**
- `duration_ms` (integer) - The duration until the exception was raised.

**Metadata:**
- `probe` (string) - The module name of the probe.
- `status` (string) - Usually `"error"`.
- `kind`, `reason`, `stacktrace` - Standard Elixir exception information.
