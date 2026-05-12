# Scoria v1.3 Memory Context for Parapet Integration

**Created:** 2026-05-12

This file serves to durably preserve the realities of the Scoria v1.3 Seismograph milestone for future Parapet integration work, particularly ensuring agents have this context after session clears.

## Core Truths

1. **SRE Telemetry, not Raw OTel:** Do not try to parse Scoria's raw OpenInference spans. Scoria is currently wiring up `Scoria.SRE.Telemetry` which explicitly formats data for SRE targets like Parapet. It separates low-cardinality labels (like `model`, `provider`, `tool_name`, `breaker_key`) from high-cardinality refs (like `trace_id`, `run_id`).
2. **Eval-Driven SLOs:** Scoria persists deterministic grounding/citation scores (`Scoria.Knowledge.score_grounding/2`). Use these established scores for Evaluation SLOs, rather than assuming a generalized LLM-as-a-judge queue exists yet.
3. **MCP Tool Failures:** Scoria's MCP gateway (`Scoria.MCP.Executor`) fails tools with explicit structured errors. Parapet needs to track these explicit modes: `timeout`, `execution_failed`, `breaker_open`, and `access_denied`. These are independent SLIs.
4. **HITL is Workflow Approvals:** Scoria does not have a generic queue for human reviews. HITL is represented as durable "approval pauses" (`waiting_for_approval` state) owned by workflows. Parapet's job is to monitor these for staleness/expiration and provide deep links to Scoria's native UI, *not* to build a new approval queue UX.

**Next Step for Execution:** Start with Phase 1 by implementing `Parapet.Scoria.SRETelemetryHandler` to consume these explicit `Scoria.SRE.Telemetry` events.