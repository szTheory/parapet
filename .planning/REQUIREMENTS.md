# Requirements: Parapet v0.7 Async & Delivery Reliability

**Defined:** 2026-05-17
**Core Value:** A Phoenix SaaS team can install Parapet and immediately know whether their critical user journeys are healthy — with evidence, not just dashboards.

## Categories

- [DELV] Delivery Reliability Adapters
- [ASYNC] Async Pipeline Reliability
- [TRIAGE] Incident Classification & Operator Context
- [RNBK] Host-Owned Recovery Runbooks

## v1 Requirements

### Delivery Reliability Adapters (DELV)

- [ ] **DELV-01**: System distinguishes `attempted`, `provider_accepted`, `delivered`, `failed`, `bounced`, `complained`, and `suppressed` delivery outcomes where the sibling integration exposes those states.
- [ ] **DELV-02**: System expands `Mailglass` integration to emit low-cardinality SLIs for outbound submit success, webhook ingest health, suppression drift, and delivery failure classes.
- [ ] **DELV-03**: System expands `Chimeway` integration to emit low-cardinality SLIs for provider acceptance, callback-confirmed delivery or failure, and callback delay where the sibling telemetry contract supports it.

### Async Pipeline Reliability (ASYNC)

- [ ] **ASYNC-01**: System expands `Rindle` integration to emit low-cardinality SLIs for queue backlog, queue age, long-running work, discard visibility, and async funnel regressions.
- [ ] **ASYNC-02**: System distinguishes retryable async failures from exhausted or discarded work so generated alerts page on user-harming failure instead of normal retry noise.
- [ ] **ASYNC-03**: System detects webhook or reconciliation delay separately from internal queue backlog so operators can identify the failing plane without inspecting raw logs first.

### Incident Classification & Operator Context (TRIAGE)

- [ ] **TRIAGE-01**: System normalizes async and delivery telemetry into bounded fault-domain metadata such as `provider`, `queue`, `pipeline_stage`, `outcome`, `failure_class`, and coarse delay buckets without leaking high-cardinality identifiers into metrics labels.
- [x] **TRIAGE-02**: System enriches async and delivery incidents with fault-domain context that clearly separates internal backlog, worker failure, provider degradation, webhook delay, and suppression drift.
- [x] **TRIAGE-03**: Operator can inspect async and delivery incidents with ordered evidence and clear classification before choosing a recovery path.

### Host-Owned Recovery Runbooks (RNBK)

- [ ] **RNBK-01**: System provides host-generated runbook templates for stalled executors, dead-letter handling, safe retry decisions, provider outage triage, and callback-delay investigation.
- [ ] **RNBK-02**: System scopes any built-in recovery action behind explicit host wiring, audit logging, and preview-first safety guidance rather than autonomous replay or mutation.
- [x] **RNBK-03**: System can create durable follow-up items only for exact operator-owned async or delivery work that requires manual action, without storing raw high-volume event streams in Ecto.

## v2 Requirements

### Delivery & Async Enhancements

- **DELV-04**: System provides a cross-adapter normalized delivery state model that is identical across `Mailglass`, `Chimeway`, and future provider integrations.
- **ASYNC-04**: System provides bounded async funnel SLIs across multiple canonical business stages beyond the initial `Rindle` slice.
- **TRIAGE-04**: System provides a small root-cause taxonomy in incident summaries across all async and delivery integrations.
- **RNBK-04**: System provides a narrow set of audited one-click recovery actions for obviously safe retry or requeue flows.

### Later Arc Work

- **ESC-01**: System provides lightweight host-owned escalation policies based on severity or time-of-day routing.
- **AUTO-01**: System allows safe reversible runbooks to auto-execute under explicit policy.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Provider-console replacement or per-message forensic UI | Not core to Parapet's evidence-first operator surface and would push the product into vendor-dashboard duplication |
| High-cardinality metrics labeled by recipient, message id, job id, or webhook id | Violates the project's low-cardinality and telemetry-as-API constraints |
| Autonomous retries, replay loops, or mutating remediation by default | Too risky before host-specific idempotency and safety boundaries are explicit |
| Generic workflow orchestration or a new async runtime | v0.7 is about observing existing sibling systems, not replacing them |
| Full escalation policy management | Reserved for the next milestone arc rather than v0.7 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DELV-01 | Phase 4 | Pending |
| DELV-02 | Phase 5 | Completed |
| DELV-03 | Phase 5 | Completed |
| ASYNC-01 | Phase 5 | Completed |
| ASYNC-02 | Phase 5 | Completed |
| ASYNC-03 | Phase 5 | Completed |
| TRIAGE-01 | Phase 4 | Pending |
| TRIAGE-02 | Phase 6 | Completed |
| TRIAGE-03 | Phase 6 | Completed |
| RNBK-01 | Phase 7 | Pending |
| RNBK-02 | Phase 7 | Pending |
| RNBK-03 | Phase 6 | Completed |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-05-17*
*Last updated: 2026-05-18 after Phase 6 execution*
