# Technology Stack

**Project:** Parapet v0.4
**Researched:** 2026-05-12

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Elixir | 1.16+ | Core Language | Strict constraint for ecosystem-native library. |
| Phoenix LiveView | Latest Stable | Operator UI | Provides reactive, real-time action-oriented SRE interfaces without needing JS frameworks. Complementary to Grafana. |
| Ecto | Latest Stable | Incident Database Spine | Relational data modeling for incidents, mitigation timelines, and AI tool audits. Ideal for low-volume, high-value relational state. |

### Supporting Libraries & Sibling Integrations
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Scoria | Optional | AI App Quality / MCP | When integrating LLMs and needing OpenInference telemetry, Eval-driven SLOs, or HITL queues. |
| Rulestead | Optional | Feature Flag/Deploy Correlation | When correlating reliability regressions with config state, and allowing the Operator UI to toggle flags during mitigations. |
| Chimeway | Optional | Notification Delivery SLIs | When modeling delivery latency and failure SLIs as critical user harm. |
| Mailglass | Optional | Transactional Email SLIs | For modeling password-reset and magic-link deliverability as first-class business SLOs. |
| Threadline | Optional | Durable Audit/Evidence | When Parapet's incident timeline needs to export or link with broader system-wide durable action history. |
| Accrue | Optional | Billing Pathway SLIs | When measuring checkout, subscription, or webhook journey health. |
| Rindle | Optional | Async Media Processing SLIs | When monitoring external provider webhook and media job pipeline health. |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Operator UI | Phoenix LiveView | Grafana Dashboards only | Grafana is excellent for visualization but lacks native app-state mutation (e.g., toggling a Rulestead feature flag or approving an AI mitigation step). LiveView serves as the "action" layer. |
| Incident Storage | App Database (Ecto) | Prometheus/Loki | Prometheus and Loki are ephemeral and time-series based. Incidents are state machines (open -> investigating -> resolved) requiring relational updates, locking, and audit trails. |
| Sibling Linking | Optional Adapters | Hard Dependencies | Hard coupling violates the "compile out cleanly" constraint. Sibling integrations must rely on defined telemetry events or optional compilation boundaries. |
| AI Telemetry | PromQL Translation | Native OTel Storage | Parapet focuses on the metrics layer for alerting. Passing raw OpenInference OTel to a tracing backend (like Honeycomb/Datadog) is the host app's job; Parapet translates it to Prometheus for SRE primitives. |

## Sources

- Parapet DNA Docs (`prompts/parapet-engineering-dna-from-sibling-libs.md`)
- SRE Deep Research (`prompts/sre-observability-elixir-lib-deep-reseach.md`)
- Parapet Integration Opportunities (`prompts/parapet-integration-opportunities.md`)
- AI Integration Seeds (`.planning/todos/deferred/scoria-ai-integration-seeds.md`)
