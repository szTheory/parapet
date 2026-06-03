# Phase 3: MCP Server Decisions for AI Copilot Triage

## Executive Summary

As part of Phase 3, we are introducing a Model Context Protocol (MCP) Server to Parapet. This server will give AI assistants (like an in-app SRE Copilot) read-only access to operational context, SLO burn rates, incident evidence, and runbooks. 

After evaluating the architectural tradeoffs with a focus on developer ergonomics (DX), the "solo founder" persona, and Parapet's opinionated, low-dependency DNA, we have reached the following two decisions:

1. **MCP Transport:** We will implement a **Custom Plug for SSE (Server-Sent Events)** (Option A).
2. **Metrics Access:** We will require the host app to **configure a Prometheus HTTP API URL** for proxying (Option A).

---

## Decision 1: MCP Server Transport

The MCP specification allows for various transports (Stdio, SSE over HTTP, WebSocket). We need to choose the right transport for an Elixir/Phoenix library running in a SaaS production environment.

### Options Evaluated

*   **Option A: Implement a custom Plug for SSE.** 
    *   **Pros:** Zero external dependencies. Keeps the library footprint small. Highly idiomatic to the Elixir/Phoenix/Plug ecosystem. HTTP/SSE is the standard transport for web-based SaaS integrations, meaning an in-app web UI or a remote AI agent can securely connect to it over standard web ports.
    *   **Cons:** Requires building the MCP JSON-RPC routing and SSE lifecycle management from scratch.
*   **Option B: Evaluate and wrap an existing open-source Elixir MCP library.**
    *   **Pros:** Could theoretically save implementation time.
    *   **Cons:** The MCP ecosystem in Elixir is still nascent. Pulling in a heavy, potentially unstable third-party dependency for a core feature violates Parapet's mandate to be a clean, low-friction, host-owned reliability substrate.
*   **Option C: Support standard Stdio.**
    *   **Pros:** Easiest to build; works out-of-the-box with local tools like Claude Desktop.
    *   **Cons:** Completely misses the mark for a production Phoenix SaaS. Stdio is for local CLI execution. We cannot realistically pipe an in-app web Copilot to the BEAM process's standard I/O in a containerized production environment (like Fly.io or Kubernetes).

### Recommendation: Option A (Custom Plug for SSE)

**Why it fits:** 
Parapet is designed for Phoenix web applications. The most natural, friction-free way to expose an MCP server in Phoenix is via a `Plug`. By shipping a custom `Parapet.MCP.Plug` that speaks SSE, developers can mount the MCP server directly in their router, protect it with their existing authentication plugs (e.g., Sigra), and expose it to their own authorized admin dashboards or remote trusted agents. 

We avoid dependency bloat, ensure we fully control the security and audit logging of tool calls, and provide the exact web-first transport needed for a modern SaaS.

---

## Decision 2: Metrics Access for AI

To effectively triage incidents, the AI needs to read RED metrics (Rate, Errors, Duration) and multi-window SLO burn rates. 

### Options Evaluated

*   **Option A: Require the host app to configure a Prometheus HTTP API URL.**
    *   **Pros:** AI gets access to true historical time-series data, exact burn rate queries, and multi-window SLO trends. Offloads the heavy aggregation math to the system built for it (Prometheus). Aligns with Parapet's existing role as a generator of Prometheus rules (as defined in our deep research).
    *   **Cons:** Adds a minor configuration requirement (the user must provide the Prometheus URL and potentially an API key to Parapet's config).
*   **Option B: Scrape local ETS tables (e.g., from `telemetry_metrics_prometheus_core`).**
    *   **Pros:** Zero setup. Always available natively on the BEAM.
    *   **Cons:** Provides only point-in-time metrics. The AI cannot ask "What was the error rate spike 45 minutes ago when the deploy happened?" — making root-cause analysis impossible. Fails the fundamental requirement for deep operational context.
*   **Option C: Build basic internal time-series aggregation in Ecto.**
    *   **Pros:** Removes the external Prometheus dependency. Durable.
    *   **Cons:** Massive scope bloat. Storing and querying high-volume time-series data in a relational DB (PostgreSQL/Ecto) is a known anti-pattern that leads to DB saturation. Parapet is a reliability layer, not a time-series database.

### Recommendation: Option A (Configure Prometheus HTTP API URL)

**Why it fits:**
Parapet's product thesis is that it composes existing raw primitives into an SRE control loop. Parapet already generates Prometheus recording and alerting rules. Therefore, Prometheus is the authoritative source of truth for SLO burn rates. 

By proxying AI queries to the Prometheus HTTP API, the AI can perform deep, historically accurate analysis (e.g., comparing pre-deploy and post-deploy latency distributions). The slight DX friction of adding `prometheus_url: System.get_env("PROMETHEUS_URL")` to the Parapet configuration is vastly outweighed by the quality of the SRE analysis it enables. We can gracefully degrade the MCP server's metrics tools if the URL is not configured.

---

## DX & Ergonomics Impact

To adhere to the principle of least surprise and ensure a "drop-in" feel, the integration will look something like this for the solo founder:

**Configuration (`runtime.exs`):**
```elixir
config :my_app, MyApp.Parapet,
  prometheus_url: System.get_env("PROMETHEUS_URL"),
  prometheus_auth_header: System.get_env("PROMETHEUS_AUTH") # optional
```

**Router (`router.ex`):**
```elixir
pipeline :admin_auth do
  plug MyAppWeb.Plugs.RequireAdmin
end

scope "/admin/mcp" do
  pipe_through [:browser, :admin_auth]
  
  # Exposed via SSE, secured by the host app's standard auth
  forward "/", Parapet.MCP.Plug, target: MyApp.Parapet
end
```

### Security & Auditing
Because we own the Plug implementation, we can seamlessly inject Parapet's `ToolCall` audit logs. Every query the AI makes against Prometheus via the MCP server will be logged, satisfying our strict "audited always" and "read-only by default" AI posture.

## Conclusion

Building a custom SSE Plug and proxying metrics queries to a configured Prometheus instance is the definitive path forward. It respects the BEAM/Phoenix ecosystem, leverages the right tool for time-series data without reinventing the wheel, and provides the safest, most composable surface for AI integration in a production SaaS.