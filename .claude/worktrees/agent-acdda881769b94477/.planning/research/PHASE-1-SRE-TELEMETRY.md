# Phase 1: SRE Telemetry Architecture

**Status:** Decided (Approach C: Signal via Alertmanager, Evidence via Wide Events)
**Context:** Parapet v0.4 (Scoria AI Integration) - Phase 1

Based on deep research into Elixir SRE best practices, the engineering DNA of sibling libraries, and the strict constraints defined in `PROJECT.md`, we have adopted a hybrid architecture for Scoria telemetry integration.

## The Decision

Alertmanager strictly governs Incident creation (Signal), while Parapet concurrently translates Scoria telemetry into high-cardinality structured logs for investigation (Evidence).

### 1. The Signal Path (Metrics & Incidents)
Parapet attaches to `Scoria.SRE.Telemetry` and instantly increments low-cardinality Prometheus metrics (e.g., `scoria_mcp_errors_total{reason="timeout", tool="fetch_docs"}`).
Prometheus evaluates Scoria SLOs. If the error budget burns too fast, Alertmanager groups the alerts and posts a webhook to Parapet. **Parapet creates the Ecto Incident** (reusing v0.3 webhook logic).

### 2. The Evidence Path (Wide Events & Context)
Inside the *same* telemetry handler, Parapet formats the Scoria event into a **Wide Event** (a structured JSON log via `LoggerJSON`). This log contains all high-cardinality data that cannot go into Prometheus: `trace_id`, `user_id`, `baseline_version`, `prompt_hash`, and specific error messages.

### 3. The Investigation Loop (Operator UX)
When an Incident is created, the LiveView Operator UI cross-references the Wide Events using the Incident's timestamp and Deploy SHA. The Incident says *"MCP Tool Failure Rate is High"*; the Wide Events provide the exact `trace_id`s and prompts that failed during this window.

## Rationale

- **The Ultimate Shock Absorber:** If an AI provider outage causes Scoria to emit 10,000 `execution_failed` events per minute, Prometheus simply increments an in-memory counter. Alertmanager handles rate-limiting and grouping.
- **Enforces v0.2 Constraint:** This perfectly respects the rule: *"System enforces a clear boundary preventing raw high-volume telemetry from entering Ecto"*.
- **SRE Idiomatic:** You should never page on a single failed job or timeout. Incidents should represent an Error Budget burn rate or aggregate user harm.
- **Ecosystem Ergonomics:** `:telemetry` is lightweight and synchronous. Emitting a structured log is fast. We avoid building a bespoke, error-prone Elixir stream-processing engine to deduplicate Ecto inserts.
- **AI Copilot Alignment:** Supplying an AI agent with an Alertmanager Incident (the *What*) and a filtered block of Wide Events (the *Why*) creates the perfect "Evidence Bundle" for automated root cause analysis.
