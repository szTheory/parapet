# Research Summary: Parapet

**Domain:** SRE / Observability / Incident Management (Elixir SaaS)
**Researched:** 2026-05-12
**Overall confidence:** HIGH

## Executive Summary

Parapet has evolved from its foundational "ephemeral" telemetry layer (v0.1) and "durable" operator evidence spine (v0.2/v0.3) to now address the emerging requirement of AI App Quality governance (v0.4). As SaaS applications increasingly adopt LLMs and MCP (Model Context Protocol) agents, SRE must adapt to track AI quality, cost, and safety.

The core research insight for v0.4 is that **Parapet can serve as the SRE control plane for AI operations** via integration with its sibling library, `Scoria`. By converting Scoria's OpenInference OTel spans into low-cardinality Prometheus metrics, Parapet enables operators to track token costs and generation latencies out-of-the-box. Furthermore, Parapet's SLO DSL can be expanded to support "Eval-Driven SLOs" (e.g., maintaining a 99% hallucination guardrail pass rate), while the LiveView Operator UI becomes the natural home for Human-in-the-Loop (HITL) approval queues for risky MCP tool calls.

## Key Findings

**Stack:** Phoenix LiveView, Ecto, Prometheus, and Scoria (OpenInference OTel integration).
**Architecture:** Translation layer between high-cardinality OpenInference telemetry and low-cardinality Prometheus metrics.
**Critical pitfall:** High-cardinality poisoning. Allowing raw prompt texts or full MCP JSON payloads to leak into Prometheus labels will crash the metrics server.

## Implications for Roadmap (v0.4 AI Integration)

Based on research, suggested phase structure for v0.4:

1. **Phase 1: AI Telemetry Translation** - Parse OpenInference OTel spans from Scoria into safe Prometheus metrics (`token_count`, `cost`, `latency`).
2. **Phase 2: Eval-Driven SLOs** - Expand `Parapet.SLO` to natively support Scoria evaluation pass rates.
3. **Phase 3: AI Deploy Correlation & Tool SLIs** - Emit markers for prompt/model changes and track MCP tool failure rates.
4. **Phase 4: HITL Queue Management** - Extend the LiveView Operator UI to monitor and manage human-approval queues for AI actions.

*(Note: Prior milestones addressed the Durable Evidence Spine, In-App Operator UI, and basic Sibling Ecosystem Integrations).*

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Phoenix, LiveView, Ecto, and Prometheus are standard. OpenInference is the industry standard for AI observability. |
| Features | HIGH | Expanding the SLO DSL and correlating AI deploys are natural extensions of Parapet's core feature set. |
| Architecture | HIGH | The boundary between OTel spans and PromQL metrics is well-understood. |
| Pitfalls | HIGH | The danger of high-cardinality labels in Prometheus is a known critical footgun. |

## Gaps to Address

- **OTel Metadata Filtering:** Need to define the exact redaction rules for Scoria's OTel spans before translating them to Parapet metrics.
