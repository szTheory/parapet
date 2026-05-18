# Phase 3: Parapet MCP Server - Research

**Researched:** 2024-05-16
**Domain:** AI Integration & API Transport
**Confidence:** HIGH

## Summary

Phase 3 introduces a Model Context Protocol (MCP) server that exposes Parapet's SRE state to external AI agents. It gives agents read-only access to incidents, timelines, runbooks, and SLO burn rates for copilot triage.

The implementation will provide a custom Plug (`Parapet.Plug.MCP`) that speaks Server-Sent Events (SSE) and JSON-RPC. It avoids heavy third-party dependencies. For metrics access, the AI tools will fetch historical metrics and burn rates by proxying queries to a configured Prometheus HTTP API URL via `Req`.

**Primary recommendation:** Implement a custom SSE Plug that handles JSON-RPC payloads and uses `Req` to proxy time-series queries to a configured Prometheus URL.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
1. **MCP Transport:** We will implement a **Custom Plug for SSE (Server-Sent Events)**.
2. **Metrics Access:** We will require the host app to **configure a Prometheus HTTP API URL** for proxying.

### the agent's Discretion
- Code organization for the MCP server components and the specific JSON-RPC parsing structure.
- Implementation of the `Req` client to securely query Prometheus.

### Deferred Ideas (OUT OF SCOPE)
- Building internal time-series aggregation in Ecto.
- Using standard Stdio for MCP transport.
- Using a third-party Elixir MCP library.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MCP-01 | System implements an MCP (Model Context Protocol) server interface exposing read-only SRE data to external AI agents. | Use a custom `Parapet.Plug.MCP` utilizing `Plug.Conn` chunking for Server-Sent Events (SSE). |
| MCP-02 | AI agents can query active Parapet incidents, view attached runbooks, and inspect the recent timeline of events. | Execute Ecto queries against `Parapet.Spine.Incident` and dynamically resolve runbook modules as seen in `Parapet.Spine.AlertProcessor`. |
| MCP-03 | AI agents can retrieve current SLO burn rates and RED metrics to perform autonomous incident investigation triage without holding write-access to the system. | Use `Req` to execute HTTP GET requests against a `prometheus_url` defined in Parapet's application configuration. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| MCP SSE Transport | API / Backend | — | Plug handles the incoming HTTP request and upgrades to an SSE stream. |
| Incident/Runbook Querying | API / Backend | Database | `Parapet.MCP.Server` interacts with Ecto/PostgreSQL to read active incidents. |
| Metrics/Burn Rate Querying | API / Backend | External Service | `Parapet.MCP.Server` proxies PromQL queries to Prometheus. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Plug | ~> 1.14 | SSE transport and HTTP routing | Natively supported by Phoenix; standard for web APIs. |
| Jason | ~> 1.4 | JSON-RPC encoding/decoding | Standard JSON library in the Elixir ecosystem. |
| Req | ~> 0.5 | HTTP client for Prometheus proxy | Developer-friendly HTTP client already available optionally in Parapet. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom SSE Plug | External MCP Library | Ecosystem is nascent; adds heavy, unstable dependencies contrary to Parapet's DNA. |
| Proxying Prometheus | Ecto time-series | Bloats the database and scope; RDBMS is an anti-pattern for time-series aggregation. |
| SSE via Plug | Stdio | Stdio is for local CLI execution, not suitable for a containerized production Phoenix SaaS. |

## Architecture Patterns

### System Architecture Diagram

```
[AI Copilot (Host/Remote)] -> (HTTP POST/SSE) -> [Parapet.Plug.MCP]
                                                         |
                                                  [JSON-RPC Parser]
                                                         |
                                                [Parapet.MCP.Server]
                                                 /        |         \
                                           (Tools)   (Resources)  (Prompts)
                                              |           |
                                   ---------------------------------
                                   |                               |
                              [Ecto (Read)]                 [Req Client]
                                   |                               |
                       (Incidents, Runbooks, SLOs)            [Prometheus]
                                   |                               |
                          [PostgreSQL DB]                (Time-series Metrics)
```

### Recommended Project Structure
```
lib/parapet/
├── plug/
│   └── mcp.ex               # The SSE and JSON-RPC Plug
├── mcp/
│   ├── server.ex            # Core MCP tool execution and routing
│   └── prometheus_client.ex # Encapsulated `Req` client for Prometheus API
```

### Pattern 1: Plug-based Server-Sent Events
**What:** Using `Plug.Conn` to maintain an open HTTP connection and push SSE chunks to the client.
**When to use:** Exposing the MCP SSE endpoint.
**Example:**
```elixir
def call(conn, _opts) do
  conn =
    conn
    |> put_resp_header("content-type", "text/event-stream")
    |> put_resp_header("cache-control", "no-cache")
    |> send_chunked(200)

  # Push event
  {:ok, conn} = chunk(conn, "event: message\ndata: {\"jsonrpc\": \"2.0\", ...}\n\n")
  conn
end
```

### Pattern 2: Safe Runbook Module Loading
**What:** Safely resolving runbook atoms from strings when queried via MCP.
**When to use:** `read_runbook` tool execution.
**Example:**
```elixir
defp get_runbook_module(runbook) when is_binary(runbook) do
  try do
    String.to_existing_atom(runbook)
  rescue
    ArgumentError -> nil
  end
end
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Metrics Aggregation | Custom SQL queries / ETS parsing | Prometheus HTTP API | Prometheus is built for time-series and multi-window SLO burn rates. ETS provides only point-in-time metrics. |
| HTTP Transport Client | `:httpc` or bare sockets | `Req` | `Req` handles connection pooling, retries, and JSON decoding automatically. |

## Common Pitfalls

### Pitfall 1: Leaking Unbounded Data via MCP
**What goes wrong:** Exposing a tool that allows the AI to run arbitrary PromQL or pull full DB tables.
**Why it happens:** Attempting to make the AI powerful by giving it unlimited query access.
**How to avoid:** Hardcode specific parameterized PromQL queries in `Parapet.MCP.PrometheusClient` (e.g., `get_slo_burn_rate(name)` instead of `execute_query(promql)`). Limit Ecto queries to open incidents and specific time bounds.

### Pitfall 2: Stale Read-Only Constraints
**What goes wrong:** The AI agent attempts to run a mutation (e.g., resolve incident) via the MCP server.
**Why it happens:** MCP Server doesn't strictly define read-only tools.
**How to avoid:** Strictly define the MCP tools as `list_incidents`, `get_incident_timeline`, `read_runbook`, and `get_slo_burn_rates`. Do not implement any tools that alter system state.

### Pitfall 3: SSE Connection Timeouts
**What goes wrong:** The Phoenix server or load balancer closes the SSE connection prematurely.
**Why it happens:** Idle timeouts on long-lived connections.
**How to avoid:** Implement a periodic ping/keep-alive mechanism in `Parapet.Plug.MCP` if connections are held open for extended periods.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Prometheus API | `get_slo_burn_rates` | ✗ | — | Gracefully return "Prometheus not configured" in MCP tool response |

**Missing dependencies with fallback:**
- Prometheus API: The host application must explicitly configure `prometheus_url`. If absent, the MCP server should still run but the metrics-related tools should return a graceful error indicating the feature is disabled.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MCP-01 | Implements custom Plug routing for SSE | unit | `mix test test/parapet/plug/mcp_test.exs` | ❌ Wave 0 |
| MCP-02 | Exposes read-only queries for active incidents and timelines | unit | `mix test test/parapet/mcp/server_test.exs` | ❌ Wave 0 |
| MCP-03 | Implements `Req` based fetch for PromQL and handles missing config safely | unit | `mix test test/parapet/mcp/prometheus_client_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/parapet/plug/mcp_test.exs` — covers MCP-01
- [ ] `test/parapet/mcp/server_test.exs` — covers MCP-02
- [ ] `test/parapet/mcp/prometheus_client_test.exs` — covers MCP-03

## Sources

### Primary (HIGH confidence)
- `.planning/research/PHASE-3-MCP-DECISIONS.md` - Confirmed the requirement for Custom Plug SSE and Prometheus HTTP API proxying.
- `.planning/phases/3/PATTERNS.md` - Confirmed the pattern for Plug implementation and Safe Module Loading.
- `mix.exs` - Confirmed `Req` is an optional dependency already available in the ecosystem for HTTP requests, and `Jason` is present transitively.
