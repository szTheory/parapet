# Roadmap: Parapet v0.7 Async & Delivery Reliability

## Milestone Goal

**"Operators can tell whether async and provider-mediated work is delayed, failing, or merely retrying, and they get safe guidance before acting."**

This milestone extends Parapet from request-time reliability into async and delivery reliability without introducing a parallel platform. The focus is low-cardinality detection, clear fault-domain classification, and host-owned recovery guidance.

## Phases

### Phase 4: Async & Delivery Telemetry Contracts
**Goal:** Lock the normalized async and delivery event vocabulary so sibling integrations emit bounded, low-cardinality signals that distinguish provider failure, webhook drift, suppression drift, and internal backlog.
**Depends on:** Completed v0.6 milestone
**Requirements:** DELV-01, TRIAGE-01
**Success Criteria**:
1. `Mailglass`, `Chimeway`, and `Rindle` integration seams emit bounded async or delivery event families with safe metadata contracts.
2. Delivery outcome states are explicitly separated instead of collapsed into one success or failure bucket.
3. Metrics label policy and compile-out behavior remain intact for all optional integrations.

### Phase 5: Built-In Async & Delivery SLOs
**Goal:** Turn the new telemetry contracts into out-of-the-box reliability slices for provider delivery and async pipeline health.
**Depends on:** Phase 4
**Requirements:** DELV-02, DELV-03, ASYNC-01, ASYNC-02, ASYNC-03
**Success Criteria**:
1. `Mailglass`, `Chimeway`, and `Rindle` each expose concrete low-cardinality metrics and provider modules for their reliability slice.
2. Generated alerts distinguish retry noise from exhausted or user-harming failure.
3. Webhook or reconciliation delay is surfaced separately from internal queue backlog.

### Phase 6: Fault-Domain Incident Enrichment
**Goal:** Enrich Parapet incidents and operator context so async and delivery alerts explain what plane is failing before an operator reaches for logs.
**Depends on:** Phase 5
**Requirements:** TRIAGE-02, TRIAGE-03, RNBK-03
**Success Criteria**:
1. Async and delivery incidents carry fault-domain context such as provider degradation, internal backlog, worker failure, suppression drift, or webhook delay.
2. Operator views show ordered evidence and clear classification using durable evidence, not ad hoc UI heuristics.
3. Exact operator-owned follow-up work can be represented durably without mirroring high-volume event streams into Ecto.

### Phase 7: Host-Owned Recovery Runbooks
**Goal:** Generate safe, inspectable runbooks and recovery seams for stalled or delivery-impaired work without defaulting into autonomous mutation.
**Depends on:** Phase 6
**Requirements:** RNBK-01, RNBK-02
**Success Criteria**:
1. Host applications can generate runbook templates for stalled executors, dead-letter handling, provider outages, and callback-delay investigation.
2. Any built-in recovery action is explicitly host-wired, preview-first, and fully audited.
3. Operator guidance favors safe investigation and scoped recovery over bulk replay or opaque automation.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DELV-01 | Phase 4 | Pending |
| TRIAGE-01 | Phase 4 | Pending |
| DELV-02 | Phase 5 | Completed |
| DELV-03 | Phase 5 | Completed |
| ASYNC-01 | Phase 5 | Completed |
| ASYNC-02 | Phase 5 | Completed |
| ASYNC-03 | Phase 5 | Completed |
| TRIAGE-02 | Phase 6 | Completed |
| TRIAGE-03 | Phase 6 | Completed |
| RNBK-03 | Phase 6 | Completed |
| RNBK-01 | Phase 7 | Completed |
| RNBK-02 | Phase 7 | Completed |

## Coverage

- Phases: 4
- v1 requirements: 12
- Requirements mapped: 12
- Unmapped: 0

## Build Order Rationale

1. Telemetry contract first, because every downstream slice depends on normalized and safe event semantics.
2. SLO and alert productization second, because detection must exist before incident enrichment can be trusted.
3. Durable operator context third, because classification belongs in evidence creation rather than UI-only derivation.
4. Runbooks and recovery last, because action surfaces should sit on top of stable evidence and alert semantics.

## Next Up

**Phase 7: Host-Owned Recovery Runbooks**

Focus:
- generate safe, host-wired recovery runbook templates
- preserve the evidence-first and audit-first operator posture
- build recovery actions on top of the durable Phase 6 triage seams

---
*Roadmap defined: 2026-05-17*
*Last updated: 2026-05-18 after Phase 6 execution*
