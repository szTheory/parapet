# Requirements: Parapet v0.5 (Proactive Resilience & Copilot Triage)

## Categories

- [PROBE] Synthetic Canaries
- [JTBD] Critical Journey Integrations (Sigra & Accrue)
- [MCP] Parapet AI Copilot Server

## Requirements

### Synthetic Canaries (PROBE)
- PROBE-01: System provides a `Parapet.Probe` behavior for defining periodic, active synthetic checks (e.g., HTTP ping, mock login, database health).
- PROBE-02: System executes probes using Oban (or a native scheduler) to guarantee execution without relying on incoming web traffic.
- PROBE-03: System emits standard Parapet metrics for probe success/failure, enabling "low-traffic SLOs" that don't suffer from noisy math on small denominators.

### Critical Journey Integrations (JTBD)
- JTBD-01: System expands the `Sigra` integration to provide out-of-the-box SLIs for login and signup success rates.
- JTBD-02: System expands the `Accrue` integration to provide out-of-the-box SLIs for billing checkout flows and webhook processing delays.
- JTBD-03: System correlates Auth and Billing regressions directly to recent deploy/config changes in the Operator UI.

### Parapet AI Copilot Server (MCP)
- MCP-01: System implements an MCP (Model Context Protocol) server interface exposing read-only SRE data to external AI agents.
- MCP-02: AI agents can query active Parapet incidents, view attached runbooks, and inspect the recent timeline of events.
- MCP-03: AI agents can retrieve current SLO burn rates and RED metrics to perform autonomous incident investigation triage without holding write-access to the system.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROBE-01    | Phase 1 | Pending |
| PROBE-02    | Phase 1 | Pending |
| PROBE-03    | Phase 1 | Pending |
| JTBD-01     | Phase 2 | Pending |
| JTBD-02     | Phase 2 | Pending |
| JTBD-03     | Phase 2 | Pending |
| MCP-01      | Phase 3 | Pending |
| MCP-02      | Phase 3 | Pending |
| MCP-03      | Phase 3 | Pending |
