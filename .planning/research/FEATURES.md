# Feature Landscape

**Domain:** SRE / Observability / Incident Management
**Researched:** 2026-05-11

## Table Stakes

Features users expect in an incident management and operator UI package. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Ecto-Backed Incident Models | Incidents require state (open, investigating, resolved) and cannot live in ephemeral metrics storage. | Medium | Must distinguish between high-volume telemetry and low-volume state. |
| Timeline & Evidence Tracking | When an alert fires, there must be a durable log of what happened and who mitigated it. | Medium | A timeline entry per action (alert fired, note added, flag disabled). |
| LiveView Operator SRE Dashboard | Operators need a secure UI to view open incidents, read runbooks, and perform actions safely. | High | Should live alongside or embed within LiveDashboard, but requires durable data access. |

## Differentiators

Features that set Parapet apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sibling Ecosystem Adapters | Out-of-the-box SLO templates for Mailglass (email deliverability), Chimeway (notifications), and Rulestead (feature flags). | Medium | Converts Parapet from generic tool to an opinionated SaaS SRE platform. |
| One-Click Safe Mitigations | e.g., Toggling a Rulestead feature flag directly from the Parapet Incident UI to stop an active bleed. | High | Requires robust permission mapping and audit logging. |
| AI / MCP Tool Call Auditing | When an AI (or human) uses a tool (e.g., querying logs, proposing rollbacks), the action is durably audited in Ecto. | Medium | Crucial for security and trust when adopting LLM operators. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Custom Time Series Storage | Writing raw telemetry to Ecto will saturate DB pools and crash production. | Continue relying on Prometheus/Grafana for high-volume ephemeral telemetry. |
| In-App Charting Engine | Rebuilding Grafana in LiveView is an immense effort with low ROI and high performance overhead. | Embed Grafana links or only show critical high-level status (RED metrics, SLO burn state) as text/simple gauges in the UI. |
| Hard Sibling Coupling | Forcing a dependency on Rulestead or Mailglass would bloat Parapet and violate the "compile out cleanly" DNA constraint. | Use adapter patterns and dynamic compilation (`Code.ensure_loaded?`) or optional protocol behaviors. |

## Feature Dependencies

```
Ecto Incident Models → Timeline Tracking
LiveView Operator SRE Dashboard → Ecto Incident Models
Sibling Ecosystem Adapters → Parapet Event Contract
AI / MCP Tool Call Auditing → Ecto Incident Models
```

## MVP Recommendation (v0.2)

Prioritize:
1. Ecto Models for Incidents and Timeline events.
2. A LiveView SRE Dashboard surface for tracking and mutating those incidents.
3. Rulestead and Mailglass optional integration layers as the proof-of-concept for sibling integrations.

Defer: 
- Building a full "on-call paging/routing" scheduler (rely on PagerDuty or OpsGenie for paging; Parapet provides the SRE *UI* and *evidence*).

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/parapet-integration-opportunities.md`
