# Phase 2: HTTP, Ecto, and Oban Metrics - Pattern Map

**Mapped:** 2026-05-09
**Files analyzed:** 4
**Analogs found:** 1 / 4 (Phase 1 was mostly foundational setup)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/parapet/plug/metrics.ex` | middleware | request-response | No exact analog yet | none |
| `lib/parapet/metrics/http.ex` | component/config | event-driven | `lib/parapet.ex` / `lib/parapet/internal/safe_handler.ex` | role-match |
| `lib/parapet/metrics/oban.ex` | component/config | event-driven | `lib/parapet/metrics/http.ex` (to be created) | none |
| `lib/parapet/metrics/ecto.ex` | component/config | event-driven | `lib/parapet/metrics/http.ex` (to be created) | none |

## Pattern Assignments

### `lib/parapet/metrics/http.ex` (component, event-driven)

**Analog:** `lib/parapet.ex` & `lib/parapet/internal/safe_handler.ex`

**Telemetry Attachment Pattern** (from `lib/parapet.ex` lines 16-40):
```elixir
# Always use Parapet.attach/1 rather than :telemetry.attach/4 directly
# to ensure the handler is wrapped in a try/rescue block (ERR-01, TELE-04).
case Parapet.attach(%{
       handler_id: "parapet-http-handler",
       event_name: [:phoenix, :endpoint, :stop],
       handler_module: __MODULE__,
       function_name: :handle_event
     }) do
  {:ok, _} -> :ok
  {:error, _} = error -> error
end
```

**Label Policy Validation** (from `lib/parapet/internal/label_policy.ex` lines 4-13):
```elixir
# Metric labels must be passed through the LabelPolicy to explicitly reject
# high cardinality fields like `raw_path` or `id`.
# This supports HTTP-02 and HTTP-05 constraints.
Parapet.Internal.LabelPolicy.assert_safe!([route, method, status_class])
```

### `lib/parapet/metrics/oban.ex` and `lib/parapet/metrics/ecto.ex` (component, event-driven)

**Optional Dependency Handling (OBAN-04, PKG-02):**
To ensure `Parapet.Metrics.Oban` is not compiled into the application when Oban is missing (which prevents `UndefinedFunctionError` or `CompileError`), the entire module body or its functionality must be guarded:

```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    @moduledoc "Registers metrics for Oban job execution."
    # ... implementation ...
  end
end
```

## Shared Patterns

### Error Handling for Metric Registration (ERR-02)
Metrics registration errors, such as duplicate metric names, must not raise exceptions that crash the application at startup. They should be caught and returned as `{:error, reason}` tuples or logged explicitly without preventing the host app from booting.

**Apply to:** All `Parapet.Metrics.*` setup functions.
```elixir
# Example defensive pattern
try do
  # Register Prometheus metrics or attach telemetry
  # ...
  :ok
rescue
  e in [ArgumentError] ->
    Logger.error("Failed to register metrics: #{Exception.message(e)}")
    {:error, e}
end
```

### Metric Cardinals & Bounding (HTTP-02, HTTP-03, HTTP-05)
Raw data from events must be sanitized to specific bounded classes before being used as labels.
- `route`: Use the matched route string or `"_unknown"`, never `conn.request_path`.
- `status_class`: Convert integer status (e.g., `201`) to string bucket (`"2xx"`).

### Telemetry Handler Signature (ERR-01)
All metric collection handles must match the standard 4-arity telemetry signature and must be referenced cleanly via `Parapet.attach/1`:
```elixir
def handle_event(_event_name, measurements, metadata, _config) do
  # extract duration and labels
  # execute metric update
end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md and Phoenix/Plug standards instead):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/parapet/plug/metrics.ex` | middleware | request-response | Phase 1 was strictly for the Telemetry backend; no Plugs exist yet. Planner must implement standard `init/1` and `call/2` Plug pattern. |

## Metadata

**Analog search scope:** `lib/**/*.ex`, `test/**/*.exs`
**Files scanned:** 12
**Pattern extraction date:** 2026-05-09
