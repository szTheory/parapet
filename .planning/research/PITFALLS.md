# Domain Pitfalls

**Domain:** SRE / Observability / Incident Management
**Researched:** 2026-05-11

## Critical Pitfalls

Mistakes that cause rewrites or major issues.

### Pitfall 1: Database Saturation from Telemetry
**What goes wrong:** The application database connection pool is exhausted, causing the host application to crash and become completely unavailable to users.
**Why it happens:** The "Durable Evidence Spine" is misunderstood as a place to store all telemetry. The system attempts to insert a row for every HTTP request or Oban job, treating Ecto/Postgres like a time-series database.
**Consequences:** A reliability tool becomes the cause of a SEV-1 outage.
**Prevention:** Strictly enforce the boundary between telemetry (Prometheus/Grafana) and evidence (Ecto). Ecto is only used for human/AI actions, postmortems, and explicit alert states, which are intrinsically low-volume.
**Detection:** High Ecto `queue_time` metrics during normal operations, rapidly expanding table sizes in the `parapet_incidents` or related tables.

### Pitfall 2: Rebuilding Grafana in LiveView
**What goes wrong:** Enormous engineering effort is spent building complex, interactive charts in Phoenix LiveView.
**Why it happens:** A desire to have a "single pane of glass" leads to feature creep, ignoring the fact that Grafana is already installed and handles charting perfectly.
**Consequences:** The SRE Operator UI becomes slow, buggy, and drains maintainer velocity away from actual incident mitigation features.
**Prevention:** The LiveView UI should focus strictly on *actions* (toggling flags, viewing runbooks, approving AI tools) and *state* (listing open incidents). Metrics should be simple text readouts or links out to Grafana.
**Detection:** Pull requests adding JavaScript charting libraries or complex time-series queries to the Ecto repo.

## Moderate Pitfalls

### Pitfall 1: Hard Coupling to Sibling Libraries
**What goes wrong:** Parapet fails to compile or crashes if a user does not have `rulestead` or `mailglass` installed.
**Prevention:** All sibling integrations must use dynamic module checks (`Code.ensure_loaded?`) or optional protocol behaviors. The core library must remain fully functional without any siblings.

### Pitfall 2: AI Tool Call Poisoning
**What goes wrong:** An LLM agent is given an MCP tool that allows it to modify production state (e.g., `run_sql`, `disable_feature_flag`) without human approval or an audit trail.
**Prevention:** Implement a strict `Parapet.Ecto.ToolAudit` schema. All production-mutating tools must be gated behind a human approval step in the LiveView Operator UI, and every read/write action must be durably logged.

## Minor Pitfalls

### Pitfall 1: LiveDashboard Auth Leaks
**What goes wrong:** The SRE Operator UI is exposed to the public internet because it is mounted incorrectly.
**Prevention:** Provide clear documentation and generator warnings (`mix parapet.doctor`) ensuring that the LiveView surface is wrapped in an authentication plug in production.

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Phase 1: DB Spine | Writing too much telemetry | Limit inserts to explicit alert fires and mitigation actions. |
| Phase 2: LiveView UI | Rebuilding Grafana | Focus purely on forms, text statuses, and action buttons. |
| Phase 3: Integrations | Breaking the `compile out cleanly` rule | Rely heavily on `Code.ensure_loaded?` and test without optional deps. |

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/parapet-engineering-dna-from-sibling-libs.md`
