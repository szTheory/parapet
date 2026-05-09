# Seed: Scoria Integration Opportunities

**Planted:** 2026-05-09
**Target:** Future Milestone (v0.2 or v0.3)
**Context:** Scoria is the sibling library for AI App Quality (tracing, evals, MCP governance).

## Deep Integration Opportunities

1. **OpenInference to Prometheus Translation:**
   Scoria emits standard OpenInference OTel `:telemetry` spans. Parapet can act as the translation layer that converts these spans into Prometheus metrics.
   * *Value:* Operators get `scoria_llm_token_count_total`, `scoria_llm_cost_usd`, and `scoria_llm_time_to_first_token_ms` in Grafana out of the box without needing to write custom telemetry handlers.

2. **Eval-Driven SLOs:**
   Parapet's SLO DSL is currently centered on HTTP and Oban. Scoria introduces "Evaluation Flywheel" scores (deterministic and LLM-as-a-judge). 
   * *Value:* We can build `Parapet.SLO.ScoriaEval` which defines objectives based on evaluation pass rates (e.g., "99% of copilot responses must pass the Hallucination Guardrail eval over a 7d window").

3. **Prompt & Model Deploy Correlation:**
   Parapet tracks deploy markers (`Parapet.Deploy.mark/1`). AI teams often update prompts or switch models without a full app deployment.
   * *Value:* Scoria could emit a specific "AI Config Change" marker via Parapet. When an SLO starts burning error budget, the Grafana annotation immediately shows "Switched from gpt-4o to claude-3-haiku" as the root cause.

4. **MCP Tool Reliability SLIs:**
   Scoria acts as an MCP gateway and executes tools in isolated OTP processes. 
   * *Value:* Parapet can track the failure rate of specific MCP tools. If the `billing_lookup` tool fails 5% of the time due to timeouts, Parapet generates the alert before the AI agent gets stuck in a hallucination loop trying to retry it.

5. **HITL (Human-in-the-Loop) Queue Health:**
   Scoria halts risky tool executions for human approval. 
   * *Value:* Parapet can track this as an operational queue (similar to Oban). If the P95 wait time for a human to approve an action exceeds 10 minutes, Parapet pages the on-call operator to clear the queue.

## Next Actions
- When planning the next phase/milestone that expands the SLO DSL, review this file to see if we should introduce the OpenInference telemetry parser.
- Keep Parapet's label policy strictly compatible with standard OTel/OpenInference metadata shapes (avoiding high-cardinality in prompt texts or full tool JSON payloads).