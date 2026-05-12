# Feature Landscape

**Domain:** SRE / Observability / Incident Management
**Researched:** 2026-05-12

## Table Stakes

Features users expect in an incident management and operator UI package. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Ecto-Backed Incident Models | Incidents require state (open, investigating, resolved) and cannot live in ephemeral metrics storage. | Medium | Must distinguish between high-volume telemetry and low-volume state. |
| Timeline & Evidence Tracking | When an alert fires, there must be a durable log of what happened and who mitigated it. | Medium | A timeline entry per action (alert fired, note added, flag disabled). |
| LiveView Operator SRE Dashboard | Operators need a secure UI to view open incidents, read runbooks, and perform actions safely. | High | Should live alongside or embed within LiveDashboard, but requires durable data access. |
| AI Telemetry Parsing | As AI features become standard, tracking LLM costs and latency is table stakes for reliability. | Medium | Translate Scoria/OpenInference OTel into Prometheus metrics. |

## Differentiators

Features that set Parapet apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Sibling Ecosystem Adapters | Out-of-the-box SLO templates for Mailglass, Chimeway, Rulestead, and Scoria. | Medium | Converts Parapet from generic tool to an opinionated SaaS SRE platform. |
| One-Click Safe Mitigations | e.g., Toggling a Rulestead feature flag directly from the Parapet Incident UI to stop an active bleed. | High | Requires robust permission mapping and audit logging. |
| AI / MCP Tool Call Auditing | When an AI (or human) uses a tool, the action is durably audited in Ecto. | Medium | Crucial for security and trust when adopting LLM operators. |
| Eval-Driven SLOs | Define SLOs based on AI output quality (e.g., hallucination pass rate) rather than just HTTP success. | Medium | `Parapet.SLO.ScoriaEval` tracks evaluation scores from Scoria. |
| HITL Queue Management | Dedicated operator UI for approving or rejecting risky AI MCP tool executions. | High | Integrates Scoria's human-in-the-loop halts into Parapet's SRE dashboard. |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Custom Time Series Storage | Writing raw telemetry to Ecto will saturate DB pools and crash production. | Continue relying on Prometheus/Grafana for high-volume ephemeral telemetry. |
| In-App Charting Engine | Rebuilding Grafana in LiveView is an immense effort with low ROI and high performance overhead. | Embed Grafana links or only show critical high-level status (RED metrics, SLO burn state) as text/simple gauges in the UI. |
| Hard Sibling Coupling | Forcing a dependency on Rulestead, Mailglass, or Scoria would bloat Parapet and violate the "compile out cleanly" DNA constraint. | Use adapter patterns and dynamic compilation (`Code.ensure_loaded?`) or optional protocol behaviors. |

## Feature Dependencies

```
Ecto Incident Models → Timeline Tracking
LiveView Operator SRE Dashboard → Ecto Incident Models
Sibling Ecosystem Adapters → Parapet Event Contract
AI / MCP Tool Call Auditing → Ecto Incident Models
Eval-Driven SLOs → Scoria Telemetry Adapter
HITL Queue Management → LiveView Operator SRE Dashboard
```

## MVP Recommendation (v0.4 Scoria Integration)

Prioritize:
1. OpenInference to Prometheus metrics translation layer.
2. Eval-Driven SLO DSL extensions.
3. HITL Queue visualization in the Operator LiveView UI.

Defer: 
- Deep AI Agent autonomous incident mitigation (keep Parapet as the human-oriented control plane for now).

## Sources

- `prompts/sre-observability-elixir-lib-deep-reseach.md`
- `prompts/parapet-integration-opportunities.md`
- `.planning/todos/deferred/scoria-ai-integration-seeds.md`
