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

**Date:** TBD
**Stats:**
- Phases: 1-3
- Plans: 0
- Total LOC: TBD

### Target Accomplishments
1. Implement `Parapet.Probe` for defining and scheduling active synthetic canaries.
2. Expand Sigra and Accrue integrations to emit explicit login, signup, and checkout SLIs.
3. Build a Parapet MCP server to allow AI agents to safely read incident data and act as triage copilots.

### Known Gaps
In planning.
