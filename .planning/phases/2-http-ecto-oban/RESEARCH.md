<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HTTP-01 | Emits `parapet.http.request` event | Use `Plug.Conn.register_before_send/2` to capture duration and status after the router. |
| HTTP-02 | `:route` label uses matched route | Extract `conn.private[:phoenix_route]` in the `before_send` callback. |
| HTTP-03 | `:status_class` label uses `"2xx"` etc | Calculate `div(conn.status, 100)` inside the `before_send` hook. |
| HTTP-04 | Register Prom counters/histograms | Use `Telemetry.Metrics` `counter/2` and `distribution/2` in `Parapet.Metrics.HTTP`. |
| HTTP-05 | Unknown routes bucketed to `"_unknown"` | Fallback `conn.private[:phoenix_route] || "_unknown"`. |
| HTTP-06 | Plug requires no router changes | Plug is injected into Phoenix `Endpoint`, running before Router. |
| ECTO-01 | Emits `parapet.ecto.query` telemetry | Attach `[:my_app, :repo, :query]` handler, convert `:native` time to `ms`. |
| ECTO-02 | Histograms for queue vs query time | Map `measurements.queue_time` and `measurements.query_time` appropriately. |
| ECTO-03 | `:source` label uses table or `"_raw"` | Fallback `metadata.source || "_raw"` in the Ecto telemetry handler. |
| OBAN-01 | Emits `parapet.oban.job` telemetry | Attach to `[:oban, :job, :stop]` and `[:oban, :job, :exception]`, map `meta.state`. |
| OBAN-02 | Alerting rules use `rate()` (SLO logic) | Deferred to Phase 3, but metric signatures must be properly aligned here. |
| OBAN-03 | Register Oban metrics | Use `Telemetry.Metrics` counters and distributions in `Parapet.Metrics.Oban`. |
| OBAN-04 | Optional compile/load for `:oban` | Wrap module in `if Code.ensure_loaded?(Oban) do ... end`. |
| ERR-02 | Metric registration duplicate handling | Wrap `Telemetry.Metrics` registration in `try/rescue` to catch `ArgumentError`. |
</phase_requirements>

# Phase 2: HTTP, Ecto, and Oban Metrics - Research

**Researched:** 2026-05-09
**Domain:** Elixir Telemetry, Phoenix Plug, Oban, Ecto
**Confidence:** HIGH

## Summary

This phase implements the metrics collection surface for Parapet's core integrations: HTTP requests (via Phoenix Plug), database queries (via Ecto), and background jobs (via Oban). The core strategy relies on capturing native telemetry emitted by Phoenix, Ecto, and Oban, optionally sanitizing and normalizing the measurements (e.g., native time to milliseconds), and re-emitting them under the unified `parapet.*` telemetry namespace. 

For HTTP metrics, a custom `Parapet.Plug.Metrics` will be placed in the Phoenix Endpoint, leveraging `Plug.Conn.register_before_send/2` to capture the final `status` and `phoenix_route` without mutating the application's router logic. For Oban, conditional compilation (`if Code.ensure_loaded?(Oban)`) ensures the library remains safe if Oban is omitted. Metric registration will be guarded with a `try/rescue` block to ensure that duplicate registrations (e.g., on application restart or duplicate config) never crash the host application.

**Primary recommendation:** Build `Parapet.Plug.Metrics` using `register_before_send/2`, use `if Code.ensure_loaded?(Oban)` to conditionally compile optional dependencies, and wrap metric registration in `try/rescue` catching `ArgumentError`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP Metrics Extraction | API / Backend | — | Plug runs in the Phoenix web process and extracts HTTP state right before the response is sent. |
| Ecto Metrics Extraction | API / Backend | Database | Telemetry handler for Ecto queries runs in the backend app to process Ecto driver measurements. |
| Oban Metrics Extraction | API / Backend | — | Oban runs background workers in the backend layer; handler captures job state synchronously. |
| Metric Registration Safety | API / Backend | — | Boot-time metric definition occurs in the application supervision tree and must not crash the node. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | ~> 1.7 | HTTP Request Routing | Standard Elixir web framework, emits endpoint and router telemetry. |
| `plug` | ~> 1.15 | HTTP Middleware | Provides `register_before_send/2` to inspect connections post-routing. |
| `telemetry_metrics` | ~> 1.0 | Metric Definitions | Standard interface for defining counters and distributions. |
| `ecto` | ~> 3.10 | Database querying | Core data mapper; emits `[:repo, :query]` native events. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `oban` | ~> 2.17 | Job Processing | Optional dependency for background jobs. Emits start/stop/exception events. |

**Installation:**
```bash
mix deps.get
```

**Version verification:** 
```bash
mix deps
```

## Architecture Patterns

### System Architecture Diagram

```text
       [Phoenix Endpoint]                      [Ecto.Repo]                       [Oban.Worker]
               |                                    |                                  |
               v                                    v                                  v
+-----------------------------+       +-----------------------------+    +-----------------------------+
| Parapet.Plug.Metrics        |       | Ecto Query Execution        |    | Oban Job Execution          |
| - Registers before_send hook|       | - Emits [:repo, :query]     |    | - Emits [:oban, :job, :stop]|
+-----------------------------+       +-----------------------------+    +-----------------------------+
               |                                    |                                  |
               v                                    v                                  v
+-----------------------------+       +-----------------------------+    +-----------------------------+
| conn.private[:phoenix_route]|       | Parapet.Metrics.Ecto        |    | Parapet.Metrics.Oban        |
| div(conn.status, 100)       |       | - Attaches handler          |    | - Guarded by ensure_loaded? |
| - Emits [:parapet, :http..] |       | - Maps metadata.source      |    | - Maps meta.state           |
+-----------------------------+       +-----------------------------+    +-----------------------------+
               |                                    |                                  |
               +-----------------+------------------+----------------------------------+
                                 |
                                 v
                  +-----------------------------+
                  | Telemetry.Metrics interface |
                  | (Guarded with try/rescue)   |
                  +-----------------------------+
```

### Recommended Project Structure
```text
lib/
├── parapet/
│   ├── plug/
│   │   └── metrics.ex       # HTTP-01 to HTTP-06: Endpoint plug
│   └── metrics/
│       ├── http.ex          # Defines Telemetry.Metrics for HTTP
│       ├── ecto.ex          # ECTO-01 to ECTO-03: Ecto handler and metrics
│       └── oban.ex          # OBAN-01 to OBAN-04: Oban handler (conditionally compiled)
```

### Pattern 1: HTTP Extraction via Plug `before_send`
**What:** Extracting the matched route and status without modifying application code or relying solely on external telemetry routing which may not have context.
**When to use:** Collecting HTTP metrics directly from the Phoenix Endpoint.
**Example:**
```elixir
defmodule Parapet.Plug.Metrics do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time()

    register_before_send(conn, fn conn ->
      duration_native = System.monotonic_time() - start_time
      duration_ms = System.convert_time_unit(duration_native, :native, :millisecond)
      
      route = conn.private[:phoenix_route] || "_unknown"
      status_class = "#{div(conn.status, 100)}xx"

      :telemetry.execute(
        [:parapet, :http, :request],
        %{duration_ms: duration_ms, status_code: conn.status},
        %{route: route, method: conn.method, status_class: status_class}
      )
      
      conn
    end)
  end
end
```

### Pattern 2: Conditional Optional Dependencies
**What:** Guarding optional metric modules to prevent `CompileError` and `UndefinedFunctionError`.
**When to use:** For `Oban` and other optional system components (PKG-02, OBAN-04).
**Example:**
```elixir
if Code.ensure_loaded?(Oban) do
  defmodule Parapet.Metrics.Oban do
    @moduledoc false
    # Oban-specific telemetry attachment and metrics definition
  end
end
```

### Anti-Patterns to Avoid
- **Anti-pattern:** Using `conn.request_path` for HTTP metrics. This causes high-cardinality explosions. Use `conn.private[:phoenix_route]` instead.
- **Anti-pattern:** Emitting HTTP metrics *before* the request finishes. Status codes and routes are only final during `before_send`.
- **Anti-pattern:** Failing application boot if a metric is registered twice. `Telemetry.Metrics` will raise `ArgumentError` if names clash. Wrap in `try/rescue`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route Matching | Custom path regex logic | `conn.private[:phoenix_route]` | Phoenix already computes the exact matched route internally. |
| Time Conversions | Manual division | `System.convert_time_unit/3` | Erlang native time varies by system; built-in handles it correctly. |

## Common Pitfalls

### Pitfall 1: 404 NoRouteError Causes Missing Route Metric
**What goes wrong:** Unmatched routes throw `Phoenix.Router.NoRouteError`, leaving `conn.private[:phoenix_route]` nil.
**Why it happens:** The router pipeline terminates early in Phoenix.
**How to avoid:** Ensure the `before_send` block falls back gracefully: `conn.private[:phoenix_route] || "_unknown"`.

### Pitfall 2: Raw SQL Queries Crashing Label Policies
**What goes wrong:** Ecto emits `[:repo, :query]` but `metadata.source` is `nil` for raw SQL.
**Why it happens:** Ecto schemas provide a string source; raw `Ecto.Adapters.SQL.query` does not.
**How to avoid:** Use a fallback in the Ecto metrics handler: `source = metadata[:source] || "_raw"`.

### Pitfall 3: Application Crashes on Re-registration
**What goes wrong:** Hot-code reloading or calling application start multiple times raises `ArgumentError` because the metric name already exists.
**Why it happens:** Metrics registries demand unique names.
**How to avoid:** Wrap the startup metric registration in a `try/rescue e in [ArgumentError] -> ...`.

## Code Examples

### Ecto Telemetry Handler Pattern
```elixir
def handle_event([_my_app, :repo, :query], measurements, metadata, _config) do
  source = metadata[:source] || "_raw"
  
  query_time_ms = System.convert_time_unit(measurements.query_time || 0, :native, :millisecond)
  queue_time_ms = System.convert_time_unit(measurements.queue_time || 0, :native, :millisecond)
  decode_time_ms = System.convert_time_unit(measurements.decode_time || 0, :native, :millisecond)
  total_time_ms = System.convert_time_unit(measurements.total_time || 0, :native, :millisecond)

  :telemetry.execute(
    [:parapet, :ecto, :query],
    %{
      total_time_ms: total_time_ms,
      query_time_ms: query_time_ms,
      queue_time_ms: queue_time_ms,
      decode_time_ms: decode_time_ms
    },
    %{repo: metadata.repo, source: source, result: metadata.result || :ok}
  )
end
```

### Oban Telemetry Handler Pattern
```elixir
def attach do
  events = [
    [:oban, :job, :stop],
    [:oban, :job, :exception]
  ]
  Parapet.Internal.SafeHandler.attach(
    "parapet-oban-handler",
    events,
    __MODULE__,
    :handle_event
  )
end

def handle_event(_event, measurements, meta, _config) do
  duration_ms = System.convert_time_unit(measurements.duration, :native, :millisecond)
  queue_time_ms = System.convert_time_unit(measurements.queue_time || 0, :native, :millisecond)
  
  :telemetry.execute(
    [:parapet, :oban, :job],
    %{duration_ms: duration_ms, queue_time_ms: queue_time_ms},
    %{worker: meta.job.worker, queue: meta.job.queue, state: meta.state}
  )
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom Elixir error reporting | Native `Telemetry` integration | ~2019 (Elixir ~1.10) | Standardized event schemas across Phoenix/Ecto/Oban. |
| Oban `:failure` events | Oban `[:oban, :job, :exception]` | Oban v2.0 | Breaking telemetry change; must use the modern `exception` event. |

## Open Questions (RESOLVED)

1. **Oban state metadata edge cases**
   - What we know: Oban's `[:oban, :job, :stop]` and `[:oban, :job, :exception]` emit `meta.state`.
   - What's unclear: Does a cancelled/discarded job trigger an exception event or a distinct event in the latest Oban?
   - Resolution: Oban emits the `[:oban, :job, :stop]` event for successes, and `[:oban, :job, :exception]` for failures, cancels, and discards. The `meta.state` field in all cases holds the precise state (`:success`, `:failure`, `:cancelled`, `:discarded`), fulfilling OBAN-01.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond Elixir packages)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` and `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HTTP-01 | HTTP Plug emits duration and status | unit | `mix test test/parapet/plug/metrics_test.exs` | ❌ Wave 0 |
| HTTP-02 | Route extraction uses `phoenix_route` | unit | `mix test test/parapet/plug/metrics_test.exs` | ❌ Wave 0 |
| ECTO-01 | Ecto handler converts measurements | unit | `mix test test/parapet/metrics/ecto_test.exs` | ❌ Wave 0 |
| OBAN-01 | Oban handler parses job state | unit | `mix test test/parapet/metrics/oban_test.exs` | ❌ Wave 0 |
| ERR-02 | Duplicate metrics return `{:error, _}` | unit | `mix test test/parapet/metrics/http_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/plug/metrics_test.exs`
- [ ] `test/parapet/metrics/ecto_test.exs`
- [ ] `test/parapet/metrics/oban_test.exs`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `conn.private[:phoenix_route]` prevents dynamic cardinality attacks. |
| V7 Error Handling | yes | Metric registration exception wrapping ensures resilient startup. |

### Known Threat Patterns for Elixir/Telemetry

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Telemetry Handler Crash Cascades | Denial of Service | Isolate metric functions using a uniform `try/rescue` handler wrapper. |
| Prometheus OOM (Label Cardinality) | Denial of Service | Use `conn.private[:phoenix_route]` directly and fallback to `_unknown`. Never parse `conn.request_path`. |

## Sources

### Primary (HIGH confidence)
- [Context7 library ID: /websites/hexdocs_pm_phoenix] - Plug extraction and `phoenix_route` lifecycle.
- [Context7 library ID: /oban-bg/oban] - Oban telemetry events (`[:oban, :job, :stop]`, `[:oban, :job, :exception]`) and `meta.state`.
- [Context7 library ID: /websites/hexdocs_pm_telemetry_metrics] - `Telemetry.Metrics` specifications.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phoenix, Ecto, Oban telemetry patterns are extremely well documented and standardized.
- Architecture: HIGH - The `register_before_send` pattern is the only safe way to read `phoenix_route` post-routing.
- Pitfalls: HIGH - Missing route fallbacks and raw query source nil values are standard Ecto/Phoenix gotchas.

**Research date:** 2026-05-09
**Valid until:** 2026-12-31