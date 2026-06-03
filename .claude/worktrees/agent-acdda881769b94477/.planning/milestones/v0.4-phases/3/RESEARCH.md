# Phase 3: AI Deploy Correlation & MCP SLIs - Research

**Researched:** 2026-05-13
**Domain:** AI Telemetry, SRE Observability, Grafana
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **2026-05-13**: AI Config Change markers will be written as Ecto `Parapet.Spine.Incident` records (type: `config_change`). This enables direct querying from Elixir for embedded AI copilot features without requiring round-trips to external observability backends, aligning with Parapet's "exact truth" design. Grafana will visualize these via its Postgres data source.
- **2026-05-13**: MCP tool failure modes (e.g., `timeout`, `execution_failed`) will be extracted from SRE telemetry, mapped to bounded atoms to prevent cardinality explosion, and emitted as Prometheus labels on a dedicated error metric (e.g., `scoria_mcp_errors_total{reason="timeout"}`). This protects the Ecto database from high-volume telemetry while enabling efficient SLO math.

### the agent's Discretion
*(None specified in CONTEXT.md)*

### Deferred Ideas (OUT OF SCOPE)
*(None specified in CONTEXT.md)*
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-DEPLOY-01 | System surfaces AI Config Changes (`scorer_version`, `baseline_version`, `model`) natively from SRE telemetry. | Recommend using an explicit `[:scoria, :config, :deployed]` event. Extracts config state into `Parapet.Spine.Incident` via `Parapet.Evidence.create_incident/1`. |
| AI-DEPLOY-02 | System visualizes AI Config Changes in Grafana to correlate with SLO error budgets. | Add Postgres annotations to `main_dashboard.json.eex` querying `parapet_incidents` where `runbook_data->>'type' = 'config_change'`. |
| AI-DEPLOY-03 | System tracks explicit failure modes (`timeout`, `execution_failed`, `breaker_open`, `access_denied`) for Scoria MCP tools as SLIs. | Map `metadata.error` in `Parapet.Integrations.Scoria` to bounded atoms, emit `[:parapet, :scoria, :mcp, :error]`, and define a `scoria_mcp_errors_total` Prometheus counter. |
</phase_requirements>

## Summary

The goal of this phase is to integrate Scoria AI deployment config changes and MCP tool reliability tracking into Parapet's SRE framework.

Parapet needs to intercept config changes to create `Parapet.Spine.Incident` markers (with type `config_change`). By listening to a dedicated Scoria configuration event, Parapet can durably log these in Ecto without tracking state across high-volume request spans. These markers will then be displayed as annotations on the Grafana dashboard utilizing Grafana's Postgres data source querying the JSONB `runbook_data` payload.

Additionally, to track MCP SLIs safely, Parapet will listen for MCP tool execution failures from Scoria. To avoid Prometheus cardinality explosion (e.g., from raw error messages), Parapet will map the errors to a bounded set of failure modes (`timeout`, `execution_failed`, `breaker_open`, `access_denied`) and expose them via `scoria_mcp_errors_total{reason="..."}` metrics.

**Primary recommendation:** Rely on an explicit `[:scoria, :config, :deployed]` telemetry event rather than polling/diffing `[:scoria, :request, :stop]` to prevent complexity, and implement bounded error mapping for MCP tool failures in `Parapet.Integrations.Scoria`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| AI Config Marker Storage | Database / Storage | API / Backend | Persistent durability using `Parapet.Spine.Incident` with JSONB `runbook_data` for exact truth representation. |
| Deploy Annotations | Client / Grafana | Database / Storage | Grafana natively queries Postgres data sources for dashboard annotations, directly pulling Ecto incidents. |
| MCP Error Metric Emitting | API / Backend | Telemetry / PromEx | Elixir telemetry handlers filter unbounded error strings into bounded atoms for safe Prometheus export. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `telemetry_metrics` | ~> 1.0 | Metric Definitions | Built-in Parapet standard for Prometheus exports. |
| `grafana` (templates) | - | Dashboard annotations | Using Grafana native Postgres data sources for querying config change incidents. |

## Architecture Patterns

### Recommended Telemetry Integration Pattern
Parapet should define explicit translation boundaries for AI deployments and MCP metrics within `Parapet.Integrations.Scoria`:

1. **Config Changes**: Listen for a dedicated event (e.g., `[:scoria, :config, :deployed]`). When received, persist it to `parapet_incidents` via `Parapet.Evidence.create_incident/1` storing `%{type: "config_change", scorer_version: "...", baseline_version: "...", model: "..."}` inside `runbook_data`.
2. **MCP Tool Failures**: Intercept MCP tool errors (e.g., `[:scoria, :mcp, :tool, :exception]`), parse the error, map to bounded reasons (`timeout`, `execution_failed`, `breaker_open`, `access_denied`), and execute `[:parapet, :scoria, :mcp, :error]`.
3. **Grafana Dashboards**: Update `main_dashboard.json.eex` annotations list to query Ecto's `parapet_incidents` table.

### Example: Ecto Annotation Query in Grafana
```json
{
  "datasource": {
    "type": "postgres",
    "uid": "${DS_POSTGRES}"
  },
  "enable": true,
  "hide": false,
  "iconColor": "rgb(255, 0, 255)",
  "name": "AI Config Changes",
  "rawQuery": "SELECT inserted_at AS \"time\", title AS \"text\", runbook_data->>'model' AS \"tags\" FROM parapet_incidents WHERE runbook_data->>'type' = 'config_change'"
}
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AI Deploy Diffing | Polling `[:scoria, :request, :stop]` metadata to detect config shifts | Explicit `[:scoria, :config, :deployed]` events | Diffing every request payload is CPU-intensive and requires state caching. An explicit deploy event is robust. |
| Prometheus MCP Errors | Raw `metadata.error` strings as metric tags | Bounded atoms (`:timeout`, `:execution_failed`) | Raw errors include dynamic IDs or stacktraces causing cardinality explosion which takes down Prometheus. |

## Runtime State Inventory

> Omitted as this is not a rename/refactor phase.

## Common Pitfalls

### Pitfall 1: High Cardinality Poisoning on MCP Errors
**What goes wrong:** Recording the raw error message (e.g. `Connection to DB timed out at 10.0.x.x:5432`) as a label in Prometheus.
**Why it happens:** Passing unbounded metadata to `telemetry_metrics` tags.
**How to avoid:** Map the error struct or tuple strictly to one of `[:timeout, :execution_failed, :breaker_open, :access_denied]`. Fallback to `:execution_failed` for unknown exceptions.

### Pitfall 2: Overloading Ecto with Config Deploy Events
**What goes wrong:** Creating an Ecto `Incident` on every single LLM request if config versions are transmitted via `[:scoria, :request, :stop]`.
**Why it happens:** Using the wrong SRE event for durable persistence.
**How to avoid:** Ensure Scoria emits a one-off `[:scoria, :config, :deployed]` event, or implement an ETS cache to debounce duplicates if extracting from requests is absolutely necessary.

## Code Examples

### Bounding MCP Errors in Parapet.Integrations.Scoria
```elixir
def handle_event([:scoria, :mcp, :tool, :exception], measurements, metadata, _config) do
  reason = map_mcp_failure(metadata.error)
  
  :telemetry.execute(
    [:parapet, :scoria, :mcp, :error],
    measurements,
    %{reason: reason, tool_name: metadata[:tool_name]}
  )
end

defp map_mcp_failure(%{reason: :timeout}), do: "timeout"
defp map_mcp_failure(%{reason: :breaker_open}), do: "breaker_open"
defp map_mcp_failure(%{reason: :access_denied}), do: "access_denied"
defp map_mcp_failure(_), do: "execution_failed"
```

### Emitting Metrics in Parapet.Metrics.Scoria
```elixir
counter("scoria_mcp_errors_total",
  event_name: [:parapet, :scoria, :mcp, :error],
  tags: [:reason, :tool_name],
  description: "Total number of Scoria MCP tool failures"
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Silent AI Configs | Correlating Config Changes in Grafana | v0.4 | Operators can immediately view if an AI regression was caused by a prompt or model rollout. |
| Unbounded Error Logs | Categorized SLI failure modes | v0.4 | Promotes resilient error budgeting for MCP Tools. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | [ASSUMED] Scoria will emit a specific config/deployment event rather than embedding it in requests. | Phase Requirements | If wrong, we'll need to add ETS-based debouncing to deduplicate per-request config states. |
| A2 | [ASSUMED] A Grafana Postgres data source (`${DS_POSTGRES}`) is or will be configured by users running the dashboard. | Architecture Patterns | If wrong, the AI config annotations will fail to load in Grafana. |
| A3 | [ASSUMED] The current `Parapet.Spine.Incident` table has no explicit `:type` column, requiring the use of `runbook_data` JSONB field for storage and filtering. | Architecture Patterns | If a `:type` column is added, the Postgres query will need adjusting. |

## Open Questions

1. **Grafana Postgres Data Source Setup**
   - What we know: The Grafana dashboard template currently heavily relies on `${DS_PROMETHEUS}`.
   - What's unclear: Does `parapet.gen.grafana` configure or prompt for the Postgres data source variable (`${DS_POSTGRES}`), or do we need to add that to the templating schema?
   - Recommendation: Add a `DS_POSTGRES` variable block to the templating list in `main_dashboard.json.eex` during Phase 3.
   - RESOLVED: Plan 03-02 implements the addition of DS_POSTGRES directly to the template.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Postgres | Ecto / Grafana annotations | ✓ | — | — |
| Prometheus | Metrics | ✓ | — | — |
| Grafana | Dashboard | ✓ | — | — |

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
| AI-DEPLOY-01 | Converts `[:scoria, :config, :deployed]` to Ecto Incident | unit | `mix test test/parapet/integrations/scoria_test.exs` | ✅ |
| AI-DEPLOY-02 | Grafana templates include Postgres annotation query | unit | `mix test test/mix/tasks/parapet.gen.grafana_test.exs` | ❌ |
| AI-DEPLOY-03 | Safely bounds MCP failure reasons | unit | `mix test test/parapet/integrations/scoria_test.exs` | ✅ |
| AI-DEPLOY-03 | Defines `scoria_mcp_errors_total` metric | unit | `mix test test/parapet/metrics/scoria_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- None — existing test infrastructure covers all phase requirements.

## Sources

### Primary (HIGH confidence)
- Codebase inspection: `Parapet.Spine.Incident` schema verified as missing a native `:type` column, confirming the necessity of JSONB storage via `:runbook_data`.
- Codebase inspection: `Parapet.Integrations.Scoria` verified for attaching handler and mapping errors.
- Codebase inspection: Grafana templates verified (`priv/templates/parapet.gen.grafana/main_dashboard.json.eex`) for annotation list insertion.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Directly based on existing project standards (telemetry_metrics, Prometheus, Grafana, Ecto).
- Architecture: HIGH - Incident schemas and telemetry handlers are natively present and clear to extend.
- Pitfalls: HIGH - Cardinality warnings derive from direct experience and project `PITFALLS.md`.

**Research date:** 2026-05-13
**Valid until:** 2026-06-13
