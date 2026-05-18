# Milestones

## v0.1 Trustworthy Spine

**Date:** 2026-05-10
**Stats:**
- Phases: 1-4
- Plans: 15
- Total LOC: 1992 (Elixir)

### Accomplishments
1. Established the foundational `Parapet` telemetry contract, supervisor, and install generator.
2. Built core metrics instrumentation for HTTP, Ecto, and Oban safely via robust API.
3. Created an SLO DSL converting standard Elixir definitions to fully functional Prometheus recording/alerting rules.
4. Delivered a seamless day-1 DX with `mix parapet.doctor` and Grafana dashboard generation.

### Known Gaps
None. All 60/60 requirements defined for v0.1 were satisfied and comprehensively tested.

## v0.2 Durable Spine and Operator UI

**Date:** 2026-05-11
**Stats:**
- Phases: 1-3
- Plans: 11
- Total LOC: 3164 (Elixir/EEx)

### Accomplishments
1. Implemented `Parapet.Evidence` context with `Incident`, `TimelineEntry`, and `ToolAudit` Ecto schemas for durable SRE tracking.
2. Created `mix parapet.gen.spine` generator to scaffold evidence migrations into host applications safely separated from high-volume telemetry.
3. Defined the Operator API with transactional audited commands and a `WorkbenchContract` for safe UI derivations.
4. Created `mix parapet.gen.ui` to generate an isolated, secure, and visually responsive Phoenix LiveView Operator Workbench inside the host app.
5. Automated structural UI tests to guarantee responsive mobile and desktop layout fidelity without relying on human QA.
6. Implemented optional integration adapters for `Mailglass`, `Chimeway`, `Accrue`, `Rindle`, `Threadline`, and `Rulestead` leveraging a new capability registry.

### Known Gaps
None. All v0.2 requirements defined and satisfied.

## v0.3 Runbooks & Alert Routing

**Date:** 2026-05-12
**Stats:**
- Phases: 1-4
- Plans: 12
- Total LOC: 6667 (Elixir/EEx)

### Accomplishments
1. Implemented a webhook receiver endpoint for Prometheus Alertmanager, automatically routing "firing" and "resolved" alerts to the durable Ecto Incident lifecycle with intelligent deduplication and correlation.
2. Created a structured `Parapet.Runbook` DSL for defining operator-triggered mitigation steps and attaching them based on SLOs or alert names.
3. Extended the Operator UI to interactively display attached runbooks and execute one-click mitigations with complete `ToolAudit` logging.
4. Built a modular `Parapet.Notifier` system with out-of-the-box Slack (Block Kit) and MS Teams (Adaptive Cards) adapters to broadcast incident state changes and record timeline entries.
5. Added UI capabilities for Operators to explicitly acknowledge incidents and generate comprehensive markdown retrospectives automatically.

### Known Gaps
None. All v0.3 requirements defined and satisfied.

## v0.4 Scoria AI Integration

**Date:** 2026-05-15
**Stats:**
- Phases: 1-4
- Plans: 9
- Total LOC: 7847 (Elixir/EEx)

### Accomplishments
1. Implemented telemetry translation consuming `Scoria.SRE.Telemetry` events and producing Parapet Prometheus metrics and durable Ecto Incidents.
2. Built `Parapet.SLO.ScoriaEval` to define and alert on Eval-Driven SLOs based on Scoria deterministic evaluation scores.
3. Added native tracking of AI Config Changes (`scorer_version`, `baseline_version`, `model`) and visualization in Grafana for SLO error budget correlation.
4. Monitored Scoria MCP tools failure modes (`timeout`, `execution_failed`, `breaker_open`, `access_denied`) as explicit SLIs.
5. Monitored Scoria workflow approval pauses as durable HITL states, triggering alerts on stale requests, and extending Operator UI with deep-links to Scoria's durable evidence.

### Known Gaps
None. All 11/11 requirements defined for v0.4 were satisfied and verified.

## v0.5 Proactive Resilience & Copilot Triage

**Date:** 2026-05-16
**Stats:**
- Phases: 1-3
- Plans: 9
- Total LOC: ~8500 (Elixir/EEx)

### Accomplishments
1. Implemented `Parapet.Probe` for defining and scheduling active synthetic canaries via `NativeScheduler` and `ObanScheduler`.
2. Expanded `Sigra` and `Accrue` integrations to emit explicit login, signup, and checkout SLIs.
3. Built a Parapet MCP server to allow AI agents to safely read incident data and act as triage copilots.
4. Resolved compilation and type warnings across the project, achieving a clean zero-warning compilation state.

### Known Gaps
None. All requirements defined for v0.5 were satisfied and verified.

## v0.6 Change Correlation & Audit Trailing

**Date:** 2026-05-17
**Stats:**
- Phases: 1-3
- Plans: 9
- Total LOC: 8968 (Elixir/EEx)

### Accomplishments
1. Implemented OpenTelemetry trace exemplar extraction from events and process dictionaries, appending `trace_id` to generated Prometheus metrics.
2. Added `trace_id` storage to Ecto `Incident` schemas and dynamically formatted trace links within the Operator UI.
3. Consumed `Rulestead` feature flag toggles via telemetry, creating durable timeline entries and suspect change markers to instantly correlate changes with SLO burn rates.
4. Highlighted recent proximate system changes (like flag toggles) on active incidents in the Operator UI, distinguishing them visually from human actions.
5. Implemented `Parapet.Integrations.Threadline` for compliance sync, mirroring Operator audit actions to Threadline event logs.
6. Added `:threadline_deferred` and `:dual_write` audit modes to satisfy strict compliance constraints (bypassing internal Parapet storage entirely when deferred).

### Known Gaps
None. All v0.6 requirements defined and satisfied. Tests pass locally.

## v0.7 Async & Delivery Reliability

**Date:** 2026-05-18
**Stats:**
- Phases: 4-7
- Plans: 12
- Total LOC: 13401 (Elixir/EEx)

### Accomplishments
1. Established safe telemetry contracts for `Mailglass`, `Chimeway`, and `Rindle` integrations to emit bounded async and delivery events.
2. Implemented out-of-the-box provider-first SLOs for async pipeline health and provider delivery states.
3. Created explicit fault-domain triage enrichment for async and delivery incidents, leveraging durable evidence over UI heuristics.
4. Added safe, host-wired recovery runbook templates for stalled async work (e.g., dead-letter handling, retry workflows).

### Known Gaps
None. All v0.7 requirements defined and satisfied. Tests pass locally.