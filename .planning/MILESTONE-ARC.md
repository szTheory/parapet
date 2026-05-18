# Milestone Arc: Ecosystem Ubiquity & Operator Mastery

## Active Milestone

### v0.8 Deterministic Escalation & Bounded Mitigation

- status: active
- theme: The system protects itself predictably
- why_now: With async visibility and basic runbooks established, the system must now ensure that unacknowledged incidents durably escalate, and that safe, predefined mitigations execute automatically to protect SLOs without relying on autonomous LLM mutations.
- goals:
  - Durable, Oban-backed escalation routing (e.g. SEV-1 -> Slack -> 5m -> SMS)
  - Deterministic bounded mitigations using the `Parapet.Operator` API
  - Ecto-backed circuit breakers (via `ToolAudit` lookbacks) to prevent flap-loops
- non_goals:
  - Autonomous AI remediation (violates evidence-first, bounded-action mandate)
  - External state engines (escalation state must live in host Oban/Postgres)

## Candidate Milestones

### v0.9 Performance, Scale & DX

- status: candidate
- theme: Confidence under load
- why_next: After core feature breadth is in place, validate TSDB safety, generator ergonomics, and large-installation behavior.
- goals:
  - High-scale performance audits and TSDB load testing
  - Generator and install-path refinement

### v1.0 Stable Release

- status: candidate
- theme: API freeze and release readiness
- why_next: Lock the public surface only after ecosystem coverage and operational sharp edges are proven.
- goals:
  - API and telemetry contract freeze
  - Comprehensive guides and stable release prep
