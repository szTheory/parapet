# Roadmap: Parapet v0.5 (Proactive Resilience & Copilot Triage)

## Phases

- [ ] **Phase 1: Synthetic Probes** - Implement `Parapet.Probe` for active monitoring of critical flows in low-traffic environments.
- [ ] **Phase 2: Deepened Journey Integrations** - Concrete SLIs for `Sigra` (auth) and `Accrue` (billing).
- [ ] **Phase 3: Parapet MCP Server** - Expose Parapet incidents and runbooks as an MCP server for AI copilot investigation.

## Phase Details

### Phase 1: Synthetic Probes
**Goal**: Operators can define periodic active checks to maintain SLO signal quality even when organic user traffic is too low for stable math.
**Depends on**: Nothing
**Requirements**: PROBE-01, PROBE-02, PROBE-03
**Success Criteria**:
  1. Developer can define a module using `Parapet.Probe`.
  2. Probe runs on a schedule and emits pass/fail metrics.
  3. Failure of a critical probe triggers the associated alert rules.
**Plans**: 3 plans
- [ ] 01-01-PLAN.md — Implement Parapet.Probe macro and Metrics handler
- [ ] 01-02-PLAN.md — Implement pluggable schedulers (Native and Oban)
- [ ] 01-03-PLAN.md — Wire up initialization and update documentation

### Phase 2: Deepened Journey Integrations
**Goal**: Go beyond basic capability stubs by providing out-of-the-box, opinionated metrics translation for authentication (Sigra) and billing (Accrue).
**Depends on**: Phase 1
**Requirements**: JTBD-01, JTBD-02, JTBD-03
**Success Criteria**:
  1. `Parapet.Integrations.Sigra` correctly emits login/signup success rates.
  2. `Parapet.Integrations.Accrue` correctly emits checkout success and webhook latency.
  3. Operator UI surfaces these specific journeys explicitly.
**Plans**: 3 plans
- [ ] 02-01-PLAN.md — Implement concrete SLIs for Sigra authentication journeys
- [ ] 02-02-PLAN.md — Implement concrete SLIs for Accrue billing journeys
- [ ] 02-03-PLAN.md — Surface Critical Journeys explicitly in the Operator UI

### Phase 3: Parapet MCP Server
**Goal**: Allow external AI agents (like Claude or custom copilots) to interrogate Parapet's SRE state to draft postmortems and investigate incidents safely.
**Depends on**: Phase 1, Phase 2
**Requirements**: MCP-01, MCP-02, MCP-03
**Success Criteria**:
  1. System exposes a standard MCP server protocol.
  2. External agent can query `list_incidents`, `get_incident_timeline`, and `read_runbook`.
  3. Access is strictly read-only, honoring the "AI as copilot, not unbounded actor" principle.
**Plans**: 0 plans

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Synthetic Probes | 0/3 | Pending | |
| 2. Deepened Journey Integrations | 0/3 | Pending | |
| 3. Parapet MCP Server | 0/0 | Pending | |
