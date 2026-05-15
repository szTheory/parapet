# Requirements: Parapet v0.4 (Scoria AI Integration)

## Categories

- [AI-TELEMETRY] Scoria Telemetry & Translation
- [AI-SLO] Eval-Driven SLOs
- [AI-DEPLOY] Deploy Correlation & MCP SLIs
- [AI-HITL] Human-in-the-Loop (HITL) Queue Management

## Requirements

### Scoria Telemetry & Translation (AI-TELEMETRY)
- AI-TELEMETRY-01: System acts as a translation layer converting Scoria OpenInference OTel spans into Prometheus metrics.
- AI-TELEMETRY-02: System provides `scoria_llm_token_count_total`, `scoria_llm_cost_usd`, and `scoria_llm_time_to_first_token_ms` in Grafana out-of-the-box.
- AI-TELEMETRY-03: System enforces a strict label policy that filters or redacts high-cardinality OTel metadata (e.g., prompt text, JSON payloads) before it enters Prometheus.

### Eval-Driven SLOs (AI-SLO)
- AI-SLO-01: System expands `Parapet.SLO` to include `Parapet.SLO.ScoriaEval` for defining objectives based on Scoria evaluation pass rates.
- AI-SLO-02: System tracks and alerts on Eval-Driven SLOs (e.g., hallucination guardrail pass rates over a rolling window).

### Deploy Correlation & MCP SLIs (AI-DEPLOY)
- AI-DEPLOY-01: System allows Scoria to emit "AI Config Change" markers (e.g., model switches, prompt updates).
- AI-DEPLOY-02: System visualizes AI Config Changes in Grafana to correlate with SLO error budgets.
- AI-DEPLOY-03: System tracks the failure rate of specific Scoria MCP tools as SLIs to enable alerting.

### Human-in-the-Loop (HITL) Queue Management (AI-HITL)
- AI-HITL-01: System tracks the Scoria Human-in-the-Loop (HITL) operational queue health similarly to Oban queues.
- AI-HITL-02: System can trigger alerts if the P95 wait time for human approval exceeds defined thresholds.
- AI-HITL-03: System extends the LiveView Operator UI to monitor and manage the HITL queue natively.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AI-TELEMETRY-01 | Phase 1 | Complete |
| AI-TELEMETRY-02 | Phase 1 | Complete |
| AI-TELEMETRY-03 | Phase 1 | Complete |
| AI-SLO-01 | Phase 2 | Complete |
| AI-SLO-02 | Phase 2 | Complete |
| AI-DEPLOY-01 | Phase 3 | Complete |
| AI-DEPLOY-02 | Phase 3 | Complete |
| AI-DEPLOY-03 | Phase 3 | Complete |
| AI-HITL-01 | Phase 4 | Complete |
| AI-HITL-02 | Phase 4 | Complete |
| AI-HITL-03 | Phase 4 | Complete |