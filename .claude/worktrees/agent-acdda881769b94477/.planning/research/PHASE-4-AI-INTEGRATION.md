# AI Integration Ecosystem (Scoria)

**Domain:** SRE / Observability / AI App Quality
**Researched:** 2026-05-12
**Overall confidence:** HIGH

## Executive Summary

As AI features (LLMs, MCP agents, auto-mitigation) become standard in SaaS applications, SRE needs to adapt. The Elixir ecosystem uses `Scoria` as a sibling library for AI App Quality (tracing, evals, MCP governance). Parapet's v0.4 milestone focuses on bridging Scoria's AI telemetry and control plane with Parapet's SRE evidence spine and Prometheus metrics.

Parapet can serve as the translation and governance layer for Scoria. By converting OpenInference OTel spans into Prometheus metrics, defining Eval-Driven SLOs, tracking AI MCP Tool Reliability, and managing HITL (Human-in-the-Loop) Queues, Parapet turns AI operations into standard, observable SRE primitives.

## Key Integration Opportunities

### 1. Scoria SRE Telemetry Integration
**Context:** Scoria provides a dedicated `Scoria.SRE.Telemetry` layer specifically designed for consumers like Parapet, distinct from its raw OpenInference tracing.
**Parapet's Role:** Consume the Scoria SRE telemetry contract (latency, cost, quality, budget_burn, breaker_state, tool_reliability) and translate it into Parapet Prometheus metrics and Ecto Incidents.
**Value:** Operators get ready-made SRE metrics out-of-the-box, without needing to manually parse high-cardinality OTel spans.

### 2. Eval-Driven SLOs
**Context:** Scoria currently persists deterministic grounding and citation scores (`Scoria.Knowledge.score_grounding/2`), alongside durable datasets.
**Parapet's Role:** Build `Parapet.SLO.ScoriaEval` to define objectives based on these persisted evaluation scores, surfacing them via the SRE telemetry `quality` events.
**Value:** Track SLOs like "99% of copilot responses must pass the Hallucination Guardrail eval over a 7d window", alerting if AI quality drops.

### 3. Prompt & Model Deploy Correlation
**Context:** AI teams update prompts or switch models independently of full app deployments. Scoria's SRE telemetry carries `scorer_version`, `baseline_version`, `model`, and `provider` labels.
**Parapet's Role:** Surface these metadata changes as "AI Config Change" markers via Parapet.
**Value:** When an SLO starts burning error budget, Grafana annotations explicitly show "Switched from gpt-4o to claude-3-haiku" as the root cause.

### 4. MCP Tool Reliability SLIs
**Context:** Scoria acts as an MCP gateway, executing tools in isolated OTP processes with distinct failure modes: `timeout`, `execution_failed`, `breaker_open`, and `access_denied`.
**Parapet's Role:** Track the failure rate of specific MCP tools (e.g., `billing_lookup`) mapped to these explicit failure modes.
**Value:** Generate specific alerts for failing MCP tools *before* the AI agent gets stuck in a hallucination retry loop due to timeouts.

### 5. Workflow Approval Pauses (HITL)
**Context:** Scoria manages Human-in-the-Loop (HITL) as workflow-owned durable approval pauses (`waiting_for_approval`), not as a generic queue subsystem.
**Parapet's Role:** Monitor these approval pauses and provide deep links into Scoria's durable evidence UI.
**Value:** Page the on-call operator if approval requests are going stale or expiring, ensuring workflows don't hang indefinitely without oversight.

## Roadmap Implications

Suggested phase structure for v0.4 (Scoria Integration):

1. **Phase 1: SRE Telemetry Translation** - Wire up consumption of `Scoria.SRE.Telemetry` into Parapet.
2. **Phase 2: Eval-Driven SLOs** - Expand `Parapet.SLO` to natively support Scoria evaluation pass rates based on grounding scores.
3. **Phase 3: AI Deploy Correlation & MCP SLIs** - Track explicit tool failure modes (`timeout`, `breaker_open`) and AI config markers.
4. **Phase 4: Workflow Approval Monitoring** - Monitor durable approval pauses and provide deep links from Parapet alerts to Scoria UI.

## Critical Pitfalls
- **High Cardinality in OpenInference:** Prompt text or full tool JSON payloads must never be used as Prometheus labels. Parapet's label policy must strictly filter or redact high-cardinality OTel metadata.
